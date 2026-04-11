%% Calculate the (normalised) energy decay curve for room impulse response
%
% INPUTS:
%   ir : impulse response (nChannels x nSamples)
%   startInd: first index to consider 
%   endInd : last index to consider
%   
% OUTPUTS
%   edc_dB : energy decay curve in dB
%   edc : backwards integrated squared impulse response
%
% PC
% (c) 2022 - L-Acoustics

function [edc_dB, edc] = calcCumulativeEnergyDecay(ir, options)

arguments
    ir (:,:) double % [SAMPLES, CHANNELS]
    options.startInd(1,:) double = ones(1, size(ir, 2))
    options.endInd (1,:) double = length(ir).*ones(1, size(ir, 2))
end

if all(ir == 0,'all')
    % Empty IR
    warning('Empty IR!')
    edc_dB = zeros(size(ir));
    edc = edc_dB;
    return
end

if size(ir, 2) > size(ir,1)
    ir = ir';
end

nCh = size(ir, 2);
for iCh = 1:nCh
    ir(1:options.startInd(iCh), iCh) = 0;
    ir(options.endInd(iCh):end, iCh) = 0;
end

% cumulative energy decay
total_energy = sum(ir.^2,1);
edc = cumsum(ir.^2,1,'reverse');

% in dB
edc_dB = 10*log10(edc)-10*log10(total_energy);




