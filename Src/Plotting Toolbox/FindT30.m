% Returns T_30 of an IR in the specified octave band
% This is based on the gradient calculated between -5 dB and -35 dB
function t30 = FindT30(ir, fs, band_centre, bandwidth_mode)
    if ~exist("bandwidth_mode", "var")
        bandwidth_mode = "1 octave";
    end

    if ~exist("band_centre", "var")
        edc_dB = GetEDC(ir, fs);
    else
        edc_dB = GetEDC(ir, fs, band_centre, bandwidth_mode);
    end

    minus_5_index = find(edc_dB <= -5, 1);
    minus_35_index = find(edc_dB <= -35, 1);

    if isempty(minus_5_index) || isempty(minus_35_index)
        t30 = 0;
        return
    end

    sampling_period = 1 / fs;

    index_range = minus_5_index:minus_35_index;
    energy = edc_dB(index_range);
    times = double(index_range) * sampling_period;

    gradient = transpose(times)\transpose(energy);

    t30 = -60 / gradient;
end