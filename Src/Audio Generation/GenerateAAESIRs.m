
% If the sources/receivers are part of the AAES, then simply use their IRs
% as if they were separate transducers. This duplication acts as a probing
% of the desired AAES transducers.

function GenerateAAESIRs(rir_directory, reverberator_directory, output_directory, loop_gains_dB, num_aaes_loudspeakers, num_aaes_mics, bit_depth, should_normalise, receivers_are_4th_order, loop_gain_is_relative_to_gbi, mic_ls_routing)
    if ~exist("receivers_are_4th_order", "var")
        receivers_are_4th_order = false;
    end

    if ~exist("loop_gain_is_relative_to_gbi", "var")
        loop_gain_is_relative_to_gbi = true;
    end

    %% Internal parameters
    N = 1; % Number of source loudspeakers
    M = 1; % Number of receiver microphones
    K = num_aaes_loudspeakers; % Number of AAES loudspeakers
    L = num_aaes_mics; % Number of AAES microphones

    output_length_factor = 2.5; %2.5 for plots % Length of output IRs as a factor of the src-rec RIR length

    [example_ir, sample_rate] = audioread(rir_directory + "E_R1_S1.wav");
    passive_ir_length = size(example_ir, 1); % Use the first IR of the set to determine IR lengths
    num_bins = round(passive_ir_length * output_length_factor); % Number of frequency bins (equals length of IR to save)
   
    %% Initialise matrices
    
    U = zeros(N, 1, num_bins); % U = 1xN Inputs

    if receivers_are_4th_order
        E = zeros(M, N, num_bins, 25); % E = NxMx25 matrix of transfer functions from each room source to each observer microphone, for 25 SHs
        F = zeros(M, K, num_bins, 25); % F = KxMx25 matrix of transfer functions from each AAES loudspeaker to each observer microphone, for 25 SHs
    else
        E = zeros(M, N, num_bins); % E = NxM matrix of transfer functions from each room source to each observer microphone
        F = zeros(M, K, num_bins); % F = KxM matrix of transfer functions from each AAES loudspeaker to each observer microphone
    end

    G = zeros(L, N, num_bins); % G = NxL matrix of transfer functions from each room source to each AAES microphone
    H = zeros(L, K, num_bins); % H = KxL matrix of transfer functions from each AAES loudspeaker to each AAES microphone
    X = zeros(K, L, num_bins); % X = LxK matrix of transfer functions defining the reverberator
    
    %% Fill transfer function matrices by reading IR files and performing FFTs
    
    U = FillTransferFunctionMatrix(U, num_bins, "U", rir_directory);
    E = FillTransferFunctionMatrix(E, num_bins, "E", rir_directory, receivers_are_4th_order);
    F = FillTransferFunctionMatrix(F, num_bins, "F", rir_directory, receivers_are_4th_order);
    G = FillTransferFunctionMatrix(G, num_bins, "G", rir_directory);
    H = FillTransferFunctionMatrix(H, num_bins, "H", rir_directory);
    X = FillTransferFunctionMatrix(X, num_bins, "X", reverberator_directory);

    mkdir(output_directory);

    if exist("mic_ls_routing", "var")
        X = X .* mic_ls_routing;
    end

    gbi_dB = 0.0;

    num_spherical_harmonics = 1;

    if (receivers_are_4th_order)
        num_spherical_harmonics = 25;
    end

    %% Run simulation

    disp("Simulating AAES for RIRs in: "+rir_directory+" with reverberator in: "+reverberator_directory+"...");

    % Isolate feedback loop and find GBI

    feedback_loop = zeros(K, K, num_bins);
    
    for bin = 1:num_bins
        feedback_loop(:,:,bin) = X(:,:,bin) * H(:,:,bin);
    end
    
    % PlotEigenvalues(feedback_loop, 48000, false);

    if loop_gain_is_relative_to_gbi
        gbi_dB = FindWorstCaseGBI(feedback_loop);
    else
        gbi_dB = 0.0;
    end

    for loop_gain_dB = loop_gains_dB
        disp("Loop Gain = " + loop_gain_dB + " dB...");
        for spherical_harmonic = 1:num_spherical_harmonics
            disp("Spherical Harmonic " + spherical_harmonic + "...");
            
            %% Set loop gain relative to the gain before instability
            
            % mu = AAES feedback loop gain
            loop_gain_linear = power(10, (gbi_dB + loop_gain_dB) / 20);
            
            %% Compute output

            % Identity for all bins
            I = zeros(num_aaes_loudspeakers, num_aaes_loudspeakers, num_bins);
            for bin_index = 1:num_bins
                I(:, :, bin_index) = eye(num_aaes_loudspeakers); % [freq bin, M, M]
            end
    
            closed_loop_denominator = I - loop_gain_linear * pagemtimes(X, H);  % [freq bin, M, M]
            H_X_H_SM = pagemtimes(X, G);
            closed_loop_H_X_H_SM = pagemldivide(closed_loop_denominator, H_X_H_SM);  % inverse(closed_loop_denominator) @ H_X @ H_SM
            receiver_freq_response = E(:, :, :, spherical_harmonic) + loop_gain_linear * pagemtimes(F(:, :, :, spherical_harmonic), closed_loop_H_X_H_SM);
            
            % Convert receiver transfer function back to the time domain
            output_signal = ifft(squeeze(receiver_freq_response(1, 1, :)));
    
            
            %% Save output
            if (~receivers_are_4th_order)
                if (should_normalise)
                    output_signal = output_signal / max(abs(output_signal));
                end

                audiowrite(output_directory + "ReceiverRIR.wav", output_signal, sample_rate, 'BitsPerSample', bit_depth);
            else
                fourth_order_output_signal(:, spherical_harmonic) = output_signal;
            end
        end

        if (receivers_are_4th_order)
            if (should_normalise)
                fourth_order_output_signal = fourth_order_output_signal / max(abs(fourth_order_output_signal), [], "all");
            end

            audiowrite(output_directory + "ReceiverRIR.wav", fourth_order_output_signal, sample_rate, 'BitsPerSample', bit_depth);
        end
    end

    disp("Finished folder: " + output_directory);
end

%% Functions

function matrix_to_fill = FillTransferFunctionMatrix(matrix_to_fill, desired_ir_length, filename_base_id, ir_directory, receivers_are_4th_order)
    if ~exist("receivers_are_4th_order","var")
        receivers_are_4th_order = false;
    end

    num_rows = size(matrix_to_fill,1);
    num_cols = size(matrix_to_fill,2);

    % If the input signal file doesn't exist, use a unit impulse
    if filename_base_id == "U" && ~isfile(ir_directory)
        matrix_to_fill(:, :, :) = 1;
        return
    end

    % Load each IR, zero pad, take FFT and insert into transfer function matrix
    for row = 1:num_rows
        for col = 1:num_cols
            if receivers_are_4th_order
                padded_ir = zeros(desired_ir_length, 25);
            else
                padded_ir = zeros(desired_ir_length, 1);
            end
    
            [raw_ir, ~] = audioread(ir_directory + filename_base_id + "_R" + row + "_S" + col + ".wav");
        
            nonzero_length = min(length(raw_ir), desired_ir_length); % Iterate up to the end of the audio, truncating if too long

            if receivers_are_4th_order
                padded_ir(1:nonzero_length, :) = raw_ir(1:nonzero_length, :);
                matrix_to_fill(row, col, :, :) = fft(padded_ir);
            else
                padded_ir(1:nonzero_length) = raw_ir(1:nonzero_length);
                matrix_to_fill(row, col, :) = fft(padded_ir);
            end
        end
    end
end