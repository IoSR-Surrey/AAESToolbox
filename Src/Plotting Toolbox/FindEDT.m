% Returns EDT of an IR in the specified octave band
% This is based on the gradient calculated between 0 dB and -10 dB
function edt = FindEDT(ir, fs, band_centre, bandwidth_mode)
    if ~exist("bandwidth_mode", "var")
        bandwidth_mode = "1 octave";
    end

    if ~exist("band_centre", "var")
        edc_dB = GetEDC(ir, fs);
    else
        edc_dB = GetEDC(ir, fs, band_centre, bandwidth_mode);
    end

    start_index = find(ir == max(ir), 1);
    minus_10_index = find(edc_dB <= -10, 1);

    if isempty(start_index) || isempty(minus_10_index)
        edt = 0;
        return
    end

    sampling_period = 1 / fs;
    start_time = start_index * sampling_period;
    minus_10_time = minus_10_index * sampling_period;
    gradient = -10 / (minus_10_time - start_time);
    edt = -60 / gradient;
end