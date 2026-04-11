% smoothNoctFreqDomain returns a 1/Nth octave smoothed version of the input, 
% in the frequency domain
%
% INPUTS:
%   dataIn : can be either magnitude (lin or dB), phase (rad or deg) or 
%            frequency response (complex values)
%   band   : smoothing type: 'octave'
%                            'half'
%                            '1/3rd'
%                            'sterz'
%                            '1/6th' 
%                            '1/12th'
%                            '1/24th'
%                            '1/48th'
%   method : output frequency distribution: 'octave'
%                                           '3rd'
%                                           '12th'
%                                           '24th'
%                                           '48th'
%                                           '384th' pseudo full scale but with logarithmic distribution
%                                           full scale if nothing specified 
%   fs     : sampling rate, in Hz
%   freqIn : frequencies corresponding to dataIn, in Hz
%            If not specified, dataIn is supposed to be uniformly 
%            distributed between 0 and Fs/2
%
%   smoothingType : "mean" (default) or "max" (for Ambiance use)
%
% OUTPUTS:
%   dataOut : 1/Nth octave smoothed version of dataIn
%   freqOut : corresponding frequencies, in Hz
%
% Spin-off of smoothsignal function (Etienne Corteel)
% Julie Seris 
% Copyright (c) 2018 by L-Acoustics

function [dataOut, freqOut] = smoothNoctFreqDomain(dataIn, band, method, fs, freqIn, smoothingType)

% Define
HALFTONE = 2^(1/12);

% Arguments checking and initialization
if(nargin < 2 || isempty(dataIn) ||  isempty(band) || ~isnumeric(dataIn))
    help smoothNoctFreqDomain
    error('Not enough input arguments')
end
switch band
    case 'octave' % octave
        halfband = HALFTONE^6;
    case 'half' % half octave
        halfband = HALFTONE^3;
    case {'terz', '1/3rd'} % third octave
        halfband = HALFTONE^2;
    case 'sterz' % small third octave
        halfband = HALFTONE^1.5;
    case {'tone', '1/6th'} % tone
        halfband = HALFTONE;
    case {'hton', '1/12th'} % half tone
        halfband = sqrt(HALFTONE);
    case '1/24th' % quarter tone
        halfband = HALFTONE^(1/4);
    case '1/48th' % 1/8th tone
        halfband = HALFTONE^(1/8);
    otherwise
        help smoothNoctFreqDomain
        error('Band name invalid');
end
if(nargin < 3 || isempty(method) || ~ischar(method))
    method = '';
    warning('Full definition has been chosen for the output frequencies, please look at the help if you want another approach')
end
if(nargin < 4 || isempty(fs) || ~isnumeric(fs) || ~isscalar(fs) || fs <= 0)
    fs = defaultValues('fs_f');
    warning(['The sampling frequency has been set to ' num2str(fs) 'Hz']);
end
if(nargin < 5 || isempty(freqIn))
    freqIn = linspace(0,fs/2, length(dataIn));  % dataIn is supposed to be uniformly distributed and given for all the frequency domain [0 - Fs/2]
elseif(~isnumeric(freqIn) || ~isvector(freqIn))
    freqIn = linspace(0,fs/2, length(dataIn));
    warning('The input data is supposed to be uniformly distributed in the frequency domain, if not, please specify a right input frequency scale');
elseif(length(dataIn) ~= length(freqIn))
    error('Dimensions of the input and the corresponding frequencies mismatch')
elseif(sum(sort(abs(freqIn)) == freqIn) < length(freqIn))
    error('The frequency scale should only contain positive values in an ascending order')
end
if (nargin < 6 || isempty(smoothingType))
    smoothingType = "mean";
end

% For Matlab purpose only
[dim1_n, dim2_n] = size(freqIn);
if(dim1_n > dim2_n)
    freqIn = transpose(freqIn);
end
[dim12_n, dim22_n] = size(dataIn);
if(dim12_n > dim22_n)
    dataIn = transpose(dataIn);
    nData_n = dim22_n;
else
    nData_n = dim12_n;
end

% Computation of the output frequencies
if contains(method, 'octave')
    freqOut = defaultValues('freqListOctave')';
elseif contains(method, '3rd')
    freqOut = defaultValues('freqList3rd')';
elseif contains(method, '12th')
    freqOut = defaultValues('freqList12th')';
elseif contains(method, '24th')
    freqOut = defaultValues('freqList24th')';
elseif contains(method, '48th')
    freqOut = defaultValues('freqList48th')';
elseif contains(method, '384th')
    freqOut = defaultValues('freqList384th')';
else
    freqOut = freqIn;
end
nbFreqOut_n = length(freqOut);

% Computation of the index ranges on which the smoothing will be done
freqIndLow_n = zeros(1, nbFreqOut_n);
freqIndHigh_n = zeros(1, nbFreqOut_n);
numFreq_n = 1;
while(numFreq_n <= nbFreqOut_n)
    range = find(freqIn >= freqOut(numFreq_n)/halfband & freqIn <= freqOut(numFreq_n)*halfband);
    % If the range is empty, the current frequency is removed from the frequency vector
    if(isempty(range))
        nbFreqOut_n = nbFreqOut_n - 1;
        freqOut(numFreq_n) = [];
    % If not, the indexes are computed
    else
        freqIndLow_n(numFreq_n) = range(1);
        freqIndHigh_n(numFreq_n) = range(end);
        numFreq_n = numFreq_n + 1;
    end
end
freqIndLow_n = freqIndLow_n(1:nbFreqOut_n);
freqIndHigh_n = freqIndHigh_n(1:nbFreqOut_n);

% If dataIn has some points before the beginning of the smoothing, they are retained
if(freqOut(1) > freqIn(1))
    for ind = freqIndLow_n(1)-1:-1:1
        freqOut = [freqIn(ind) freqOut];
        nbFreqOut_n = nbFreqOut_n + 1;
        freqIndLow_n = [ind freqIndLow_n];
        freqIndHigh_n = [ind freqIndHigh_n];
    end
end

% To avoid steps in the frequency response due to consecutive identical index ranges, the duplications are removed 
% and their value will be interpolated from their neighbours later
selectedInd = 1;
for numFreq_n = 2:nbFreqOut_n-1
     if(~(freqIndLow_n(numFreq_n) == freqIndLow_n(numFreq_n-1) && freqIndHigh_n(numFreq_n) == freqIndHigh_n(numFreq_n-1)))
         selectedInd = [selectedInd numFreq_n];
     end
end
if(freqIndLow_n(nbFreqOut_n) == freqIndLow_n(nbFreqOut_n-1) && freqIndHigh_n(nbFreqOut_n) == freqIndHigh_n(nbFreqOut_n-1))  % High limit case to be able to use interp1 for the interpolation
    selectedInd(end) = nbFreqOut_n;
else
    selectedInd = [selectedInd nbFreqOut_n];
end

% Nth smoothing on the selected index ranges
dataOut = zeros(nData_n, length(selectedInd));
for i = 1:length(selectedInd)
    if (smoothingType == "mean")
        dataOut(:,i) = mean(dataIn(:,freqIndLow_n(selectedInd(i)):freqIndHigh_n(selectedInd(i))),2);
    elseif (smoothingType == "max")
        dataOut(:,i) = max(dataIn(:,freqIndLow_n(selectedInd(i)):freqIndHigh_n(selectedInd(i))),[],2);
    end
end

% Interpolation to fill the missing values, due to index ranges duplications
% (here the interpolation is on the frequency indexes and not on the frequencies themselves to avoid exponential curves due to logarithmic scale)
if(length(selectedInd) < length(freqOut))
    indOut = 1:nbFreqOut_n;
    dataOut = interp1(indOut(selectedInd), dataOut', indOut);
end

% For Matlab purpose only
if(dim1_n > dim2_n)
    freqOut = transpose(freqOut);
end
[dim1_n, dim2_n] = size(dataOut);
if(dim1_n > dim2_n)
    dataOut = transpose(dataOut);
end
