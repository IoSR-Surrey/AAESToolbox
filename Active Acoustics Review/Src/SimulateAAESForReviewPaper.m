
rir_base_dir = "Active Acoustics Review/Generated AAES RIRs/";
reverberator_base_dir = "Active Acoustics Review/Reverberators/";
output_base_dir = "Active Acoustics Review/AAES Receiver RIRs/";
bit_depth = 32;

conditions = readmatrix("Active Acoustics Review/Src/SimulationConditions.dat");
conditions_to_simulate = 1:size(conditions, 1);

for aaes_index = conditions_to_simulate
    rir_set_index = conditions(aaes_index, 1);
    num_mics = conditions(aaes_index, 2);
    num_ls = conditions(aaes_index, 3);
    rev_index = conditions(aaes_index, 4);
    loop_gain = conditions(aaes_index, 5);
    loop_gain_is_relative = conditions(aaes_index, 6);

    if loop_gain_is_relative
        loop_gain_label = "(rel)";
    else
        loop_gain_label = "(abs)";
    end

    GenerateAAESIRs(rir_base_dir + "Room Condition " + rir_set_index + "/", ...
        reverberator_base_dir + "Reverberator " + rev_index + "/", ...
        output_base_dir, ...
        "aaes_condition_" + aaes_index +".wav", ...
        loop_gain, ...
        num_ls, ...
        num_mics, ...
        bit_depth, ...
        true, ...
        loop_gain_is_relative);
end

% % % Add time domain sims here...