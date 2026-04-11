% This script generates the reverberator files required by
% SimulateAAESForReviewPaper.m. Please ensure the fdnToolbox is installed
% and has been added to MATLAB's working path.

clear all

%% Reverberator 1 (identity)
SaveIdentityReverberator(16, "Active Acoustics Review/Reverberators/Reverberator 1/", 48000, 24);

%% Reverberator 2-5 (LTI FDN; RT Ratio = 0.5, 1.0, 1.5, 2.0 w.r.t. Room 1)
[ir, fs] = audioread("Active Acoustics Review/Generated AAES RIRs/Room Condition 1/E_R1_S1.wav");
passive_room_1kHz_rt = FindT30(ir,fs,1000);
rt_ratios = [0.5, 1.0, 1.5, 2.0];
num_mics = 16;
num_ls = 16;
bit_depth = 32;
output_parent_dir = "Active Acoustics Review/Reverberators/";

for reverberator_index = 1:4
    rt_ratio = rt_ratios(reverberator_index);
    rt_dc = passive_room_1kHz_rt * rt_ratio;
    rt_nyquist = rt_dc / 2;
    GenerateFDNIRs(rt_dc, rt_nyquist, num_mics, num_ls, fs, bit_depth, output_parent_dir+"Reverberator "+(reverberator_index + 1)+"/")
end

%% Reverberator 6 (Hadamard matrix)
hadamard_matrix = 1;

for i = 1:4
    hadamard_matrix = GenerateNextHadamardIteration(hadamard_matrix);
end

SaveReverberatorMatrix(hadamard_matrix, "Active Acoustics Review/Reverberators/Reverberator 6/", 48000, 32);

%% Reverberator 7 (LTI FDN; RT Ratio = 2.0 w.r.t. Room 4)
[ir, fs] = audioread("Active Acoustics Review/Generated AAES RIRs/Room Condition 4/E_R1_S1.wav");
passive_room_1kHz_rt = FindT30(ir,fs,1000);
rt_ratio = 2;
num_mics = 16;
num_ls = 16;
bit_depth = 32;
output_parent_dir = "Active Acoustics Review/Reverberators/";

rt_dc = passive_room_1kHz_rt * rt_ratio;
rt_nyquist = rt_dc / 2;
GenerateFDNIRs(rt_dc, rt_nyquist, num_mics, num_ls, fs, bit_depth, output_parent_dir+"Reverberator 7/")


function SaveReverberatorMatrix(matrix, output_dir, sample_rate, bit_depth)
    mkdir(output_dir);

    for row = 1:size(matrix, 1)
        for col = 1:size(matrix, 2)
            audiowrite(output_dir + "X_R" + row + "_S" + col + ".wav", matrix(row,col), sample_rate, BitsPerSample=bit_depth);
        end
    end
end

function output_matrix = GenerateNextHadamardIteration(input_matrix)
    num_rows = length(input_matrix);
    num_cols = num_rows;

    output_matrix = zeros(num_rows * 2, num_cols * 2);

    % Fill top left
    output_matrix(1:num_rows, 1:num_cols) = input_matrix;

    % Fill bottom left
    output_matrix(num_rows + 1:num_rows * 2, 1:num_cols) = input_matrix;

    % Fill top right
    output_matrix(1:num_cols, num_cols + 1:num_cols * 2) = input_matrix;

    % Fill bottom right
    output_matrix(num_rows + 1:num_rows * 2, num_cols + 1:num_cols * 2) = -input_matrix;
end

function SaveIdentityReverberator(num_channels, output_dir, sample_rate, bit_depth)
    mkdir(output_dir);

    for row = 1:num_channels
        for col = 1:num_channels
            output = 0;
            if row == col
                output = 1;
            end
            audiowrite(output_dir + "X_R" + row + "_S" + col + ".wav", output, sample_rate, BitsPerSample=bit_depth);
        end
    end
end