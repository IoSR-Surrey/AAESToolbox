function [onsetIndex] = getOnsetIndex(ir,fs,perChannel)
%
% getOnsetIndex returns the estimated index of the direct sound
% in each channel of the impulse response.
%
% This method is based on the Ds method of the following paper :
% https://pubs.aip.org/asa/jasa/article/124/4/EL248/980851/Finding-the-onset-of-a-room-impulse-response
%
% The method uses a spectral estimation which finds the block
% containing the signal onset. This function then refines the estimate by
% finding the max within the block
%
% INPUTS:
%   ir : impulse response (nSamples x nChannels)
%   fs : sampling frequency (Hz)
%   perChannel : Booloean value to return the same (perChannel=0) or 
%                different (perChannel=1) index for each channel
%                (optional, default 1)
%
% OUTPUT:
%   onsetIndex : (1 x nChannels) array containing the onset index of each channels
% 
%
% May 2023
% Thomas Fouchard, Phil Coleman
% Copyright (c) 2023 by L-Acoustics

arguments
    ir (:,:) double  % (SAMPLES, CHANNELS)
    fs (1,1) double
    perChannel (1,1) logical = true
end

DEBUG = false;

if isempty(ir)
    warning('Empty IR!')
    onsetIndex = -1;
    return
end

if all(ir == 0,'all')
    % Empty IR
    warning('IR has only zeros!')
    if perChannel
        onsetIndex = ones(1,size(ir,2));
    else
        onsetIndex = 1;
    end
    return
end

if size(ir,2) > size(ir,1) % assume RIR data has more samples than channels
    ir = ir';
end

% Defines
nChannels = size(ir,2);
onsetIndex = zeros(1,nChannels);
windowLength = floor(5/1000*fs); % 5ms window
overlap = floor(0.5*windowLength);

N = size(ir, 1);

% Process
for iCh = 1:nChannels
    [~, endInd] = max(abs(ir(:,iCh)));
    endInd = endInd + floor(0.01*fs); % don't search beyond the max sample

    zeropadIR = [zeros(windowLength,1);ir(1:endInd, iCh)]; % ensure onset within first signal frame is detected correctly
    logDecay = calcCumulativeEnergyDecay(zeropadIR);

    [X,~,~] = spectrogram(zeropadIR, windowLength, overlap, fs);
    E = sum(abs(X), 1);
    diffE = zeros(length(E)-1, 1);

    if DEBUG
    t_st = (1:length(E)-1)*(windowLength-overlap)/fs+windowLength/2/fs;
    end

    for j = 1:length(E)-1
        if E(j)==0 || isnan(E(j))
            diffE(j) = 0;
        else
            diffE(j) = E(j+1)/E(j);
        end
    end
    weighting = 10.^logDecay((1:length(E)-1)*(windowLength-overlap)+floor(windowLength/2));
    [~, diffEMaxInd] = max(diffE.*weighting);
    
    % PC: find the block containing the onset...
    onsetBlockStart = floor((windowLength-overlap)*diffEMaxInd);

    % ... then assume max value in block is the true onset
    % refines estimate for impulsive signals; doesn't hurt too much for
    % noise-like ones
    [~,maxInOnsetBlock] = max(abs(zeropadIR(onsetBlockStart:onsetBlockStart+windowLength)));
    onsetIndex(iCh) = max(maxInOnsetBlock + onsetBlockStart - 1 - windowLength, 1);
    
    % TF calc, modified to compensate for zero padding being added
    % appears to find the block containing the onset and return the middle
    % sample of that block
    % onsetIndex(iCh) = floor( (windowLength-overlap) * diffEMaxInd + windowLength/2) - windowLength;
end

if ~perChannel
    [firstOnsetIndex,~] = min(onsetIndex);
    onsetIndex = repmat(firstOnsetIndex,1,nChannels);
end

% Plot (for testing)
if DEBUG
    figure
    t = (0:N-1)'/fs;    
    plot(t, 20*log10(abs(ir)), '-');
    xline(t(onsetIndex), '-', 'startIndice', 'Color',[1 0 0], 'LineWidth',1.5)
    yyaxis right
    plot(t_st, diffE)
    grid on
    xlabel('Time (s)')
    xlim([0 2*max(onsetIndex)/fs])
end

end