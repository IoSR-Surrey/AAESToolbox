
rir_base_dir = "Active Acoustics Review/Generated AAES RIRs/";
output_base_dir = "Active Acoustics Review/AAES Receiver RIRs/";
bit_depth = 32;

%% Frequency-domain simulations
reverberator_base_dir = "Active Acoustics Review/Reverberators/";
conditions = readmatrix("Active Acoustics Review/Room Simulation Parameters/SimulationConditions.dat");
conditions_to_simulate = 1:size(conditions, 1);

for aaes_index = conditions_to_simulate
    rir_set_index = conditions(aaes_index, 1);
    num_mics = conditions(aaes_index, 2);
    num_ls = conditions(aaes_index, 3);
    rev_index = conditions(aaes_index, 4);
    loop_gain = conditions(aaes_index, 5);
    loop_gain_is_relative = conditions(aaes_index, 6);

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

%% Time-domain simulations
ir_length_sec = 4;
conditions_to_simulate = 53:55;
time_varying_conditions = [false, true, true];
loop_gains = [-6.5, -36.1, -3.5];
loop_gains_are_relative = [1, 0, 1];
[ir, fs] = audioread("Active Acoustics Review/Generated AAES RIRs/Room Condition 5/E_R1_S1.wav");
passive_room_rt = FindT30(ir,fs);


for simulation_index = 1:3
    aaes_index = conditions_to_simulate(simulation_index);
    output_filename = "aaes_condition_" + aaes_index +".wav";
    is_time_varying = time_varying_conditions(simulation_index);
    rt_ratio = 2.0;
    loop_gain = loop_gains(simulation_index);
    loop_gain_is_relative = loop_gains_are_relative(simulation_index);

    disp("Simulating "+output_filename);
    
    SimulateAAESTimeDomain(rir_base_dir + "Room Condition 5/", ...
        output_base_dir, ...
        output_filename, ...
        is_time_varying, ...
        loop_gain, ...
        loop_gain_is_relative, ...
        rt_ratio, ...
        passive_room_rt, ...
        ir_length_sec, ...
        bit_depth)
end