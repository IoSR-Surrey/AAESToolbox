
function GenerateFDNIRs(rt_dc, rt_nyquist, num_mics, num_ls, fs, bit_depth, output_dir)
    config.numMicrophones = num_mics;
    config.numLoudspeakers = num_ls;
    
    % FDN order
    FDN.order = 32;
    
    % Gains
    FDN.inputGains = orth(randn(FDN.order, config.numMicrophones));
    FDN.outputGains = orth(randn(config.numLoudspeakers, FDN.order)')';
    FDN.directGains = zeros(config.numLoudspeakers,config.numMicrophones);
    
    % Delay lines
    FDN.delays = randi([1200,2500], [1,FDN.order]);
    
    % Feedback matrix
    FDN.feedbackMatrix = randomOrthogonal(FDN.order);
    
    % Absoption filters
    FDN.RT_DC = rt_dc;                % [seconds]
    FDN.RT_NY = rt_nyquist;                % [seconds]
    
    % FDN.RT_DC = 0.868 * rt_ratio;                % [seconds]
    % FDN.RT_NY = FDN.RT_DC / 2;                % [seconds]
    
    % Time Variation
    FDN.modulationFrequency = 0.0;  % hz
    FDN.modulationAmplitude = 0.0;
    FDN.spread = 0.0;
    
    FDN.blockSize = 256;
    FDN.fs = fs;
    
    FDN = create_FDN(FDN);
    irs = computeFDNirs(FDN, config);
    
    % Normalise each element individually
    for row = 1:config.numMicrophones
        for col = 1:config.numLoudspeakers
            irs(row, col, :) = irs(row, col, :) / max(abs(irs(row, col, :)));
        end
    end
    
    mkdir(output_dir);
    SaveIRs(irs, FDN.fs, bit_depth, output_dir, "X");
end

% Generate FDN
function params = create_FDN(params)
    % Reverberation time
    params.RT = max(params.RT_DC, params.RT_NY);
    % Input gains
    B = convert2zFilter(params.inputGains);
    params.InputGains = dfiltMatrix(B);
    % Delay lines
    params.DelayFilters = feedbackDelay(params.blockSize, params.delays);

    % Absorption filters
    [absorption.b,absorption.a] = onePoleAbsorption(params.RT_DC, params.RT_NY, params.delays, params.fs);
    A = zTF(absorption.b, absorption.a,'isDiagonal', true);
    % A = zTF(b_coeffs, a_coeffs,'isDiagonal', true);
    params.absorptionFilters = dfiltMatrix(A);
    % Feedback matrix
    F = convert2zFilter(params.feedbackMatrix);
    params.FeedbackMatrix = dfiltMatrix(F);
    params.TVMatrix = timeVaryingMatrix(params.order, params.modulationFrequency, params.modulationAmplitude, params.fs, params.spread);
    % Output gains
    C = convert2zFilter(params.outputGains);
    params.OutputGains = dfiltMatrix(C);
    % Direct path
    D = convert2zFilter(params.directGains);
    params.DirectGains = dfiltMatrix(D);
end

% FDN iteration step
function [output, params] = FDN_step(params, input)

    % Delays 
    delayOutput = params.DelayFilters.getValues(params.blockSize);
    % Absorption
    absorptionOutput = params.absorptionFilters.filter(delayOutput); 
    % Feedback matrix
    feedback = params.FeedbackMatrix.filter(absorptionOutput);
    if ~isempty(params.TVMatrix)
        feedback = params.TVMatrix.filter(feedback);
    end
    % Output
    output = params.OutputGains.filter(absorptionOutput) + params.DirectGains.filter(input);

    % Prepare next iteration
    delayLineInput = params.InputGains.filter(input) + feedback;
    params.DelayFilters.setValues(delayLineInput);
    params.DelayFilters.next(params.blockSize);

end

function FDN_irs = computeFDNirs(params, config)

    % Define length of the FDN irs based on the FDN RT
    sigLength = ceil(params.RT * params.fs);
    
    % Allocate memory
    FDN_irs = zeros(config.numMicrophones, config.numLoudspeakers, sigLength);

    % Iterate over FDN inputs
    for i = 1:config.numMicrophones
        
        % Define input signal (Impulse at a single channel)
        inputSignal = zeros(sigLength, config.numMicrophones);
        inputSignal(1,i) = 1;

        % Block processing
        numBlocks = floor(sigLength / params.blockSize);
        for block = 1:numBlocks
            block_index = (block-1)*params.blockSize + (1:params.blockSize);
            [fdn_step_output, params] = FDN_step(params, inputSignal(block_index,:));
            FDN_irs(i,:,block_index) = fdn_step_output';
        end
    end

    params.DelayFilters.values(:) = 0;
end