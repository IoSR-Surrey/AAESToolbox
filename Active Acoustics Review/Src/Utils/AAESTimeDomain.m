classdef AAESTimeDomain < handle

    % Properties
    properties
        % time-frequency
        fs
        nfft
        blockSize
        % layout
        numMics
        numLds
        % RIRs
        H_SR
        H_SM
        H_LR
        H_LM
        % DSP
        FDN
        generalGain
        % Storages
        mics_storage
        receivers_storage
    end
    
    methods
        
        % Constructor
        function obj = AAESTimeDomain(config, RIRs, FDN_params)

            % Processing
            obj.fs = config.fs;
            obj.nfft = RIRs.length;
            obj.blockSize = config.blockSize;
            % Layout
            obj.numMics = config.numMicrophones;
            obj.numLds = config.numLoudspeakers;
            % RIRs
            obj.H_SR = RIRs.H_SR;
            obj.H_SM = RIRs.H_SM;
            obj.H_LR = RIRs.H_LR;
            obj.H_LM = RIRs.H_LM;
            % DSP
            obj.create_FDN(FDN_params);

            if (config.gainIsRelativeToGBI)
                obj.generalGain = db2mag(config.gain)*obj.estimateGBI();
            else
                % % % % use this to allow the eigenvalues to be plotted if
                % desired
                % obj.estimateGBI();

                obj.generalGain = db2mag(config.gain);
            end

            % Storages
            obj.mics_storage = zeros(obj.nfft, obj.numMics);
            obj.receivers_storage = zeros(obj.nfft,1);

        end

        % Generate FDN
        function create_FDN(obj, params)
            % Reverberation time
            obj.FDN.RT = max(params.RT_DC, params.RT_NY);

            % Input gains
            B = convert2zFilter(params.inputGains);
            obj.FDN.InputGains = dfiltMatrix(B);
            % Delay lines
            obj.FDN.DelayFilters = feedbackDelay(obj.blockSize, params.delays);
            % Absorption filters
            [absorption.b,absorption.a] = onePoleAbsorption(params.RT_DC, params.RT_NY, params.delays, obj.fs);
            A = zTF(absorption.b, absorption.a,'isDiagonal', true);
            obj.FDN.absorptionFilters = dfiltMatrix(A); 
            % Feedback matrix
            F = convert2zFilter(params.feedbackMatrix);
            obj.FDN.FeedbackMatrix = dfiltMatrix(F);
            obj.FDN.TVMatrix = timeVaryingMatrix(params.order, params.modulationFrequency, params.modulationAmplitude, obj.fs, params.spread);
            % Output gains
            C = convert2zFilter(params.outputGains);
            obj.FDN.OutputGains = dfiltMatrix(C);
            % Direct path
            D = convert2zFilter(params.directGains);
            obj.FDN.DirectGains = dfiltMatrix(D);

        end

        % Gain before instability estimation
        function GBI = estimateGBI(obj)
            FDN_irs = obj.computeFDNirs();
            open_loop_TFs = matrix_product(fft(obj.H_LM, obj.nfft, 1), ...
                                           fft(FDN_irs, obj.nfft, 1));

            eigenvalues = pageeig(permute(open_loop_TFs, [2,3,1]));

            % PlotEigenvalues(open_loop_TFs, obj.fs, true);

            GBI = 1/max(real(eigenvalues),[],'all');
            disp(strcat(['The current GBI is: ', sprintf('%0.1f',(mag2db(GBI)))]));
        end

        function FDN_irs = computeFDNirs(obj)

            % Define length of the FDN irs based on the FDN RT
            sigLength = floor(obj.FDN.RT * obj.fs);
            
            % Allocate memory
            FDN_irs = zeros(sigLength, obj.numLds, obj.numMics);

            % Iterate over FDN inputs
            for i = obj.numMics
                
                % Define input signal (Impulse at a single channel)
                inputSignal = zeros(sigLength, obj.numMics);
                inputSignal(1,i) = 1;

                % Block processing
                numBlocks = floor(sigLength / obj.blockSize);
                for block = 1:numBlocks
                    block_index = (block-1)*obj.blockSize + (1:obj.blockSize);
                    FDN_irs(block_index,:,i) = obj.FDN_step(inputSignal(block_index,:));
                end
            end

            obj.FDN.DelayFilters.values(:) = 0;

        end

        % Process signal
        function output = process(obj, input)

            % Input block
            assert(size(input,1) == obj.blockSize);
            % Microphone input
            source_to_mics = real(ifft( matrix_product( fft(obj.H_SM, obj.nfft, 1), fft(input, obj.nfft, 1) ), obj.nfft, 1));
            mics_signals = source_to_mics(1:obj.blockSize,:) + obj.mics_storage(1:obj.blockSize,:);
            % FDN
            FDN_input = mics_signals;
            FDN_output = obj.FDN_step(FDN_input);
            % Loudspeaker output
            ls_signals = obj.generalGain * FDN_output;
            % Feedback
            ls_to_mics = real(ifft( matrix_product( fft(obj.H_LM, obj.nfft, 1), fft(ls_signals, obj.nfft, 1) ), obj.nfft, 1));
            % Receiver signals
            ls_to_receivers = real(ifft( matrix_product( fft(obj.H_LR, obj.nfft, 1), fft(ls_signals, obj.nfft, 1) ), obj.nfft, 1));
            source_to_receivers = real(ifft( matrix_product( fft(obj.H_SR, obj.nfft, 1), fft(input, obj.nfft, 1) ), obj.nfft, 1));
            receivers_signal = ls_to_receivers + source_to_receivers;
            % Output block
            output = receivers_signal(1:obj.blockSize) + obj.receivers_storage(1:obj.blockSize);
            % Store for next block iterations
            obj.update_storage("mics_storage", source_to_mics+ls_to_mics);
            obj.update_storage("receivers_storage", receivers_signal);

        end

        % FDN iteration step
        function output = FDN_step(obj, input)
                
            % Delays 
            delayOutput = obj.FDN.DelayFilters.getValues(obj.blockSize);
            % Absorption
            absorptionOutput = obj.FDN.absorptionFilters.filter(delayOutput); 
            % Feedback matrix
            feedback = obj.FDN.FeedbackMatrix.filter(absorptionOutput);
            if ~isempty(obj.FDN.TVMatrix)
                feedback = obj.FDN.TVMatrix.filter(feedback);
            end
            % Output
            output = obj.FDN.OutputGains.filter(absorptionOutput) + obj.FDN.DirectGains.filter(input);

            % Prepare next iteration
            delayLineInput = obj.FDN.InputGains.filter(input) + feedback;
            obj.FDN.DelayFilters.setValues(delayLineInput);
            obj.FDN.DelayFilters.next(obj.blockSize);
            
        end

        % Store signal blocks
        function update_storage(obj, storage, newData)

            % Add new data
            obj.(storage) = obj.(storage) + newData;
            % Shift left
            obj.(storage) = circshift(obj.(storage), -obj.blockSize, 1);
            % Clean end
            obj.(storage)(end-(obj.blockSize-1):end, :) = 0;

        end

    end
end