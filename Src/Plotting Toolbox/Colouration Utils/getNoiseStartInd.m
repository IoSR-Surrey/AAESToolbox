function [noiseStartInd, noiseFloorDB] = getNoiseStartInd(ir, fs, onset)
%
% getNoiseStartInd returns the index where the input impulse response 
% reaches noise level.
%
% The method implemented in this function is from the paper by A. Lundeby, 
% T. E. Vigran, H. Bietz, and M. Vorländer, "Uncertainties of Measurements 
% in Room Acoustics,” Acustica, vol. 81, pp. 344–355 (1995)
%
% INPUTS:
%   ir : input impulse response (nSamples x nChannels)
%   fs : sampling frequency (Hz)
%   onset : ir onset indices (1 x nChannels)
%
% OUTPUT:
%   noiseStartInd : (1 x nChannels)
%   noiseFloorDB  : (1 x nChannels)
%
%
% 2023
% Thomas Fouchard, Frederic Roskam
% Copyright (c) 2023 by L-Acoustics

arguments
    ir (:,:) double % [SAMPLE x CHANNEL]
    fs (1,1) double
    onset (1,:) double = getOnsetIndex(ir, fs)
end

if size(ir,2) > size(ir,1) % assume RIR data has more samples than channels
    ir = ir';
end

% Defines
NB_CH = size(ir, 2);
NB_SAMPLES = size(ir, 1);
BLK_LENGTH = floor(0.05*fs); % 50ms block length

assert(NB_CH == numel(onset),'Number of channels and onsets must match')

noiseStartInd = zeros(1, NB_CH);
noiseFloorDB = zeros(1, NB_CH);

if NB_SAMPLES < 3 * BLK_LENGTH
    warning('IR too short (min 150ms)');
    noiseStartInd(:) = NB_SAMPLES;
    noiseFloorDB(:) = -Inf;
    return
end


% Process
for iCh = 1:NB_CH
    % Only consider post-onset IR
    postOnsetIRSquare = ir(onset(iCh):end, iCh).^2;
    irLength = size(postOnsetIRSquare, 1);

    % Compute mean square per block of 50ms
    blkPos = (1:BLK_LENGTH:irLength);
    
    blkMeanSquareIR = zeros(1, length(blkPos)-1);
    for bInd = 1:length(blkPos)-1
        blkMeanSquareIR(bInd) = mean(postOnsetIRSquare(blkPos(bInd):blkPos(bInd+1)));
    end

    if any(blkMeanSquareIR)
        % Estimate noise floor from the last 2 blocks
        noiseFloorDB(iCh) = 10*log10(mean(blkMeanSquareIR(end-1:end))); % take last 2 50ms blocks
        noiseStartBlkInd = find(10*log10(blkMeanSquareIR) <= noiseFloorDB(iCh) + 3, 1, 'first'); % find where signal level is 3dB above noise
    
        if noiseStartBlkInd > 1 % i.e. a solution was found
            if noiseStartBlkInd < length(blkMeanSquareIR)-1 % index not at the very end of the signal
                % Linear regression on the decaying signal before the noise floor
                % Skip first block
                p = polyfit(blkPos(2:noiseStartBlkInd), 10*log10(blkMeanSquareIR(2:noiseStartBlkInd)), 1);
                % Estimate cross point
                crossInd = find(polyval(p, (1:irLength)) < noiseFloorDB(iCh), 1, 'first');
    
                if ~isempty(crossInd)
                    noiseStartInd(iCh) = crossInd + onset(iCh);
        
                    % Find last sample above quantization noise
                    irChAbs = abs(ir(:, iCh));
                    minVal = min(irChAbs(irChAbs>0), [], 'all');
                    digitalNoiseStartInd = find(irChAbs > minVal, 1, 'last');
                    if ~isempty(digitalNoiseStartInd)
                        noiseStartInd(iCh) = min(digitalNoiseStartInd, noiseStartInd(iCh));
                    end
                else
                    noiseStartInd(iCh) = NB_SAMPLES;
                end
            else
                % Likely noise cannot be estimated
                noiseStartInd(iCh) = NB_SAMPLES;
                noiseFloorDB(iCh) = -Inf;
            end
        else
            % The channel is just noise
            noiseStartInd(iCh) = NB_SAMPLES;
            noiseFloorDB(iCh) = -Inf;
        end
    else
        % The channel is just zeros
        noiseStartInd(iCh) = 1;
        noiseFloorDB(iCh) = -Inf;
    end

end

end

