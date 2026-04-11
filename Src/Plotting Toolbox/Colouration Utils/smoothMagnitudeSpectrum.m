function [magSpecSmoothed,freqSm] = smoothMagnitudeSpectrum(magSpec, fs, smoothingPointsPerOctave, options)
%SMOOTHMAGNITUDESPECTRUM smooth RIR by a number of points per octave
% returns magnitude spectrum up to Nyquist with corresponding frequency vector
% magSpec is result of FFT of signal INCLUDING negative frequency
% components

arguments
    magSpec (:,:) double % (FREQ BINS, CHANNELS)
    fs (1,1) double
    smoothingPointsPerOctave (1,1) double = 48 % use -1 for no smoothing
    options.inputSpectrum = "full"; % "full" or "half"
    options.outputResolution (:,:) char {mustBeText} = '48th';
    options.inputFreq (1,:) double = []; % input frequency vector
    options.smoothingType = "mean"; % "mean" or "max"
end

% smoothing expects half spectrum

Nf = size(magSpec,1);

if options.inputSpectrum == "full"
    if rem(Nf,2) == 0
        fEnd = Nf/2;
    else
        fEnd = (Nf-1)/2;
    end
elseif options.inputSpectrum == "half"
    fEnd = Nf - 1;
else
    error('check arg options.inputSpectrum');
end

magSpec = magSpec(1:fEnd+1,:); 

if smoothingPointsPerOctave == -1 
    % no smoothing
    magSpecSmoothed = magSpec;
    freqSm = fs*(0:Nf/2)./Nf;
else
    % smooth input spectrum
    switch smoothingPointsPerOctave
        case 1
            smoothingString = 'octave';
        case 2
            smoothingString = 'half';
        case 3
            smoothingString = '1/3rd';
        case 6
            smoothingString = '1/6th';
        case 12
            smoothingString = '1/12th';
        case 24
            smoothingString = '1/24th';
        case 48
            smoothingString = '1/48th';
    end
    [magSpecSmoothed, freqSm] = smoothNoctFreqDomain(magSpec, smoothingString, options.outputResolution, fs, options.inputFreq, options.smoothingType);
    magSpecSmoothed = magSpecSmoothed.';
end