% Returns the direct-to-reverberant ratio matrix for all sources to
% receivers, and the predicted distances (delays) between all sources to
% receivers in samples
function [drr_matrix, src_rec_delay_matrix] = GetMatrixDRR(read_dir, matrix_prefix, num_mics, num_ls, max_src_rec_distance_metres, src_rec_delay_matrix)
    if ~exist("max_src_rec_distance_metres", "var")
        max_src_rec_distance_metres = 17;
    end

    if ~exist("src_rec_delay_matrix", "var")
        src_rec_delay_matrix = zeros(num_mics, num_ls);
        should_use_delay_matrix = false;
    else
        should_use_delay_matrix = true;
    end

    drr_matrix = zeros(num_mics, num_ls);
    speed_of_sound = 343;

    for mic_index = 1:num_mics
        for ls_index = 1:num_ls
            [ir, fs] = audioread(read_dir + matrix_prefix + "_R" + ls_index + "_S" + mic_index + ".wav");

            if ~should_use_delay_matrix
                direct_search_limit_samples = floor((fs * max_src_rec_distance_metres) / speed_of_sound);
    
                % Find direct component sample index
                [~, direct_pos] = max(abs(ir(1:direct_search_limit_samples)));

                src_rec_delay_matrix(mic_index, ls_index) = direct_pos;
            else
                direct_pos = src_rec_delay_matrix(mic_index, ls_index);
            end

            % Calculate direct energy (+/- 5 ms around direct)
            half_window_length_samples = floor(0.005 * fs);
            direct_region_samples = ir(max(1, direct_pos - half_window_length_samples):direct_pos + half_window_length_samples);
            direct_energy = sum(direct_region_samples.^2);

            % Calculate reverberant energy (total energy - direct)
            total_energy = sum(ir.^2);
            reverberant_energy = total_energy - direct_energy;

            % Calculate ratio
            drr = direct_energy / reverberant_energy;

            % Clamp at -100 dB
            if drr < 1e-10
                drr = 1e-10;
            end
            
            drr_matrix(mic_index, ls_index) = drr;
        end
    end

    drr_matrix = 10 * log10(drr_matrix);
end