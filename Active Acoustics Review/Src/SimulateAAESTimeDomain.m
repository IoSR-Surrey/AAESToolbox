function SimulateAAESTimeDomain(rir_read_dir, ...
    output_dir, ...
    output_filename, ...
    is_time_varying, ...
    loop_gain_dB, ...
    loop_gain_is_relative, ...
    rt_ratio, ...
    passive_room_rt, ...
    ir_length_sec, ...
    bit_depth)

    % Path to FDN toolbox
    addpath(genpath('../GitHub/fdnToolbox'));
    
    %% High-level params
    
    config.gain = loop_gain_dB; % dB
    config.gainIsRelativeToGBI = loop_gain_is_relative;
    
    %% Configuration data
    
    % Time parameters
    config.fs = 48000; % [Hz]
    config.blockSize = 256;
    
    %% Input Signals
    
    % Unit impulse:
    anechoic_signal = zeros(ir_length_sec * config.fs, 1);
    anechoic_signal(1) = 1;
    fs_an = config.fs;
    
    if fs_an ~= config.fs
        anechoic_signal = resample(anechoic_signal, config.fs, fs_an);
    end
    inputSignal = anechoic_signal;
    sigLength = size(inputSignal,1);
    
    %%
    
    % Layout
    config.numMicrophones = 4;
    config.numLoudspeakers = 16;
    
    %% Load room impulse responses (only 1 input source and 1 audience position)
    
    filename = rir_read_dir + "E_R1_S1.wav";
    [RIRs.H_SR, fs_rirs] = audioread(filename);                                         % [time, 1, 1]
    assert(fs_rirs == config.fs);
    RIRs.length = size(RIRs.H_SR, 1);
    
    RIRs.H_SM = zeros(RIRs.length, config.numMicrophones, 1);                           % [time, n_mics, 1]
    RIRs.H_LR = zeros(RIRs.length, 1, config.numLoudspeakers);                          % [time, 1, n_speakers]
    RIRs.H_LM = zeros(RIRs.length, config.numMicrophones, config.numLoudspeakers);      % [time, n_mics, n_speakers]
    
    for rec_index = 1:config.numMicrophones
        filename = rir_read_dir + "G_R" + rec_index + "_S1.wav";
        ir = audioread(filename);
        if length(ir) < RIRs.length
            ir = cat(1, ir, zeros(RIRs.length - length(ir), 1));
        end
        RIRs.H_SM(:,rec_index,1) = ir(1:RIRs.length);
    end
    
    for src_index = 1:config.numLoudspeakers
        filename = rir_read_dir + "F_R1_S" + src_index + ".wav";
        ir = audioread(filename);
        if length(ir) < RIRs.length
            ir = cat(1, ir, zeros(RIRs.length - length(ir), 1));
        end
        RIRs.H_LR(:,1,src_index) = ir(1:RIRs.length);
    end
    
    for rec_index = 1:config.numMicrophones
        for src_index = 1:config.numLoudspeakers
            filename = rir_read_dir + "H_R" + rec_index + "_S" + src_index + ".wav";
            ir = audioread(filename);
            if length(ir) < RIRs.length
                ir = cat(1, ir, zeros(RIRs.length - length(ir), 1));
            end
            RIRs.H_LM(:,rec_index,src_index) = ir(1:RIRs.length);
        end
    end
    
    RIRs.length = RIRs.length;
    
    %% Define FDN parameters and general gain
    
    rng(1);
    
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
    FDN.RT_DC = passive_room_rt * rt_ratio;                % [seconds]
    FDN.RT_NY = FDN.RT_DC / 2;                % [seconds]
    
    % Time Variation
    if (is_time_varying)
        FDN.modulationFrequency = 0.05;  % Hz
        FDN.modulationAmplitude = 0.3;
        FDN.spread = 50.0;
    else
        FDN.modulationFrequency = 0.0;  % Hz
        FDN.modulationAmplitude = 0.0;
        FDN.spread = 0.0;
    end
    
    % The class computes the GBI and then sets the general gain to mu = db2mag(GBI + GBI-offset)
    
    %% Active Acoustic Enhancement System
    
    aaes = AAESTimeDomain(config, RIRs, FDN);
    
    %% Process input signal
    
    % Allocate memory
    outputSignal = zeros(sigLength,1);
    
    % Number of processing blocks
    numBlocks = floor(sigLength / config.blockSize);
    
    % Block-wise processing
    for block = 1:numBlocks
        
        % Time indeces
        block_index = (block-1)*config.blockSize + (1:config.blockSize);
        % Processing function
        outputSignal(block_index) = aaes.process(inputSignal(block_index));
    
    end
    
    %% Output results
    
    outputSignal = outputSignal / max(abs(outputSignal));
    
    audiowrite(output_dir + output_filename, outputSignal, config.fs, "BitsPerSample", bit_depth);
end