function curvature = GetCurvature(ir, sample_rate)
    start_early_dB = -5;
    end_early_dB = -10;
    start_late_dB = -30;
    end_late_dB = -50;

    % calculate EDC
    [energy_decay_dB, time_values_seconds] = GetEnergyDecay(ir, sample_rate);

    % probe EDC at start_early, end_early, start_late and end_late
    [~, start_early_pos] = min(abs(energy_decay_dB - start_early_dB));
    [~, end_early_pos] = min(abs(energy_decay_dB - end_early_dB));
    [~, start_late_pos] = min(abs(energy_decay_dB - start_late_dB));
    [~, end_late_pos] = min(abs(energy_decay_dB - end_late_dB));

    start_early_time = time_values_seconds(start_early_pos);
    end_early_time = time_values_seconds(end_early_pos);
    start_late_time = time_values_seconds(start_late_pos);
    end_late_time = time_values_seconds(end_late_pos);

    % calculate gradients (y2 - y1) / (x2 - x1)
    m_early = (end_early_dB - start_early_dB) / (end_early_time - start_early_time);
    m_late = (end_late_dB - start_late_dB) / (end_late_time - start_late_time);

    % return difference in gradients - 1
    curvature = (1 - m_late / m_early) * 100;
end

function [energy_decay_dB, time_values_seconds] = GetEnergyDecay(ir, sample_rate)
    integration_limit_samples = size(ir,1);

    % Calculate Schroeder decay
    energy_decay_dB(integration_limit_samples:-1:1)=10*log10(cumsum(ir(integration_limit_samples:-1:1).^2)/sum(ir(1:integration_limit_samples).^2));

    time_values_samples = 1:length(energy_decay_dB);
    time_values_seconds = time_values_samples / sample_rate;
end