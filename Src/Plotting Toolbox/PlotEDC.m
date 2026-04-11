% 
% This function plots an Energy Decay Curve (aka Schroeder curve) of an IR
% using backwards integration.
%
% Optional Parameters:
%
% line_style - defaults to solid ("-")
% x_max - Maximum time value to plot in seconds
% y_min - Minimum energy value to plot in dB (defaults to -70 dB)
% integration_limit_sec - integration limit in seconds (defaults to the length of the IR)

function integrated_values_dB = PlotEDC(ir, sample_rate, octave_band_centre, line_style, x_max, y_min, integration_limit_sec)
    integration_limit_samples = 0;
    
    if ~exist("octave_band_centre", "var")
        octave_band_centre = false;
    end

    if octave_band_centre ~= false
        oct_filt = octaveFilter(octave_band_centre,"SampleRate",sample_rate);
        ir = oct_filt(ir);
    end

    if ~exist('line_style','var')
        line_style = "-";
    end

    if ~exist('y_min','var')
        y_min = -60;
    end

    if exist('integration_limit_sec','var')
        integration_limit_samples = integration_limit_sec * sample_rate;
    else
        integration_limit_samples = size(ir,1);
    end

    % Calculate Schroeder decay
    integrated_values_dB(integration_limit_samples:-1:1)=10*log10(cumsum(ir(integration_limit_samples:-1:1).^2)/sum(ir(1:integration_limit_samples).^2));

    time_values_samples = 1:length(integrated_values_dB);
    time_values_seconds = time_values_samples / sample_rate;

    plot(time_values_seconds,integrated_values_dB,'LineStyle',line_style,"LineWidth",1.5,"MarkerSize",3);
    set(gca,'fontsize', 15);
    title("Energy Decay Curve","FontSize",16,"FontWeight","normal");
    xlabel("Time (s)");
    ylabel("Energy (dB)");
    ylim([y_min 0]);
    grid on

    if exist('x_max','var')
        xlim([0 x_max]);
    end
end