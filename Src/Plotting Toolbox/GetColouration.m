% IR coloration metric
% following "Objective measure of sound colouration in rooms"
% Meynial & Vuichard, Acta Acustica 1999
%
% inputs:
% ir (samples x 1), single channel room impulse response
% fs, sample rate
% options: 
%   Debug (logical), displays plots if true
%   NFFT, set custom FFT size
function colourationScore = GetColouration(ir, fs, options)

arguments
    ir (:,1) double % (SAMPLES, 1)
    fs (1,1) double % sample rate
    options.Debug (1,1) logical = false;
    options.NFFT (1,1) double = 2^14;
    options.MinFreq (1,1) double = 50;
    options.MaxFreq (1,1) double = 4e3;
end
    
% estimate decay using Schroader integral
% (could perform sub-band filtering first)
logDecay = calcCumulativeEnergyDecay(ir);
d1 = -15; % dB start of late tail
d2 = -35; % dB end of late tail
m = 10; % margin to noise floor

% check that d2 is greater than noise floor + margin
[~, noiseLeveldB] = getNoiseStartInd(ir, fs);
if d2 - (noiseLeveldB + m) < 0 % check noise floor plus margin
    error('insufficient dynamic range');
end

% estimate RT...
% calculate t1 and t2 from d1 and d2
[~,t1] = min(abs(logDecay - d1),[],1);
[~,t2] = min(abs(logDecay - d2),[],1);

nSamples = length(ir);
t = (0:1/fs:(nSamples-1)/fs)';
t_fit = t(1:t2-t1+1); % shift time for curve fitting
d_fit = logDecay(t1:t2)-logDecay(t1); % fit from 0
[fit, ~] = polyfit(t_fit,d_fit,1);

% Result
RT = (-60 - fit(2)) / fit(1); % x intercept for y = -60

% perform the time windowing
irw = ir(t1:t2);
tw = t(t1:t2);

% multiply IR by exp(6.91t/T) to compensate for the decay
irwc = irw .* exp(6.91.*tw/RT);


% t2 - t1 > T/4
% (t1:t2 is the time window; t1 should be greater than the mixing time)
% (d1 and d2 are the decays corresponding to t1 and t2)
if (t2 - t1 > RT/4) == 0
    disp('Assumption about RT might have been broken');
end

% FFT
nfft = options.NFFT;
spectrum = fft(irwc,nfft);
magSpecFull = (abs(spectrum));
f = fs .* (0:nfft-1)./nfft;

% smooth spectrum
smoothingBandsPerOctave = 3;
[specSm,fSm] = smoothMagnitudeSpectrum(magSpecFull, fs, smoothingBandsPerOctave);

% interpolate full spectrum to fSm to allow subtraction
magSpec = interp1(f,magSpecFull,fSm);

%Gw = 10.^((magSpec - specSm.')/20);
Gw = magSpec./specSm.';

% filter IR in [f1;f2] band
f1 = options.MinFreq; % Hz, should strictly be Schroeder freq
f2 = options.MaxFreq; % 4e3 used in paper

fwin = ones(size(fSm));
[~,f1i] = min(abs(fSm - f1));
[~,f2i] = min(abs(fSm - f2));
fwin([1:f1i-1,f2i:end]) = 0;
Gw = Gw .* fwin;
Gww = Gw(f1i:f2i);

% sigma_g is simply the standard deviation of G
colourationScore = std(Gww);

if options.Debug % make some plots
    figure;
    subplot(2,1,1),
    semilogx(fSm,magSpec);
    hold all
    semilogx(fSm,specSm,'r','LineWidth',1.5);
    xlim([f1, f2])
    legend({'Modulus of IR',['Smoothed modulus |M(\omega)| (' num2str(smoothingBandsPerOctave) ' bands per octave)']})
    grid on
    title('IR magnitude response |H_{ww}(\omega)|')

    subplot(2,1,2),
    semilogx(fSm,Gw); hold all
    xlim([f1, f2])
    legend(['Mean: ' num2str(mean(Gww))]);
    grid on
    title('Estimate of |G_w(\omega)|')

    figure;
    subplot(2,1,1),
    plot(tw,ir(t1:t2));
    grid on
    title('Before exponential decay compensation')

    subplot(2,1,2),
    plot(tw,irwc);
    grid on
    title('After exponential decay compensation')

end