% This script generates all RIRs required to compute the AAES model
% described by Eq. (4) in "Active Acoustic Enhancement Systems - A Review".
% Shoebox dimensions, absorption coefficients and AAES channel counts.
% Please ensure the following AKtools fork is installed and added to
% MATLAB's working path: https://github.com/wjcassidy/AKtools-FreqIndepSH

% close all

%% User Parameters

% General audio parameters
sample_rate = 48000;
bit_depth = 32;

absorptions_dir = "Active Acoustics Review/Room Simulation Parameters/Absorption Coefficients/";
coords_dir = "Active Acoustics Review/Room Simulation Parameters/Coordinates/";
rotations_dir = "Active Acoustics Review/Room Simulation Parameters/Rotations/";
directivities_dir = "Active Acoustics Review/Room Simulation Parameters/Directivities/";
output_dir = "Active Acoustics Review/Generated AAES RIRs/";

% Room Condition 5 is 1 with EQ (use GenerateEqualisedRoom.m after running
% this script)
for rir_set_index = 1
    GenerateRIRs(rir_set_index, absorptions_dir, coords_dir, rotations_dir, directivities_dir, output_dir, sample_rate, bit_depth);
end

delete(gcp('nocreate'));

%% Generation

function GenerateRIRs(rir_set_index, absorptions_dir, coords_dir, rotations_dir, directivities_dir, output_dir, sample_rate, bit_depth)
    room_dims = readmatrix("Active Acoustics Review/Room Simulation Parameters/Room Dimensions/room_dimensions.dat");
    alphas = readmatrix(absorptions_dir + "absorption_coeffs_"+rir_set_index+".dat");
    
    src_coords = readmatrix(coords_dir + "src_coords.dat");
    rec_coords = readmatrix(coords_dir + "rec_coords.dat");
    ls_coords = readmatrix(coords_dir + "ls_coords_"+rir_set_index+".dat");
    mic_coords = readmatrix(coords_dir + "mic_coords_"+rir_set_index+".dat");
    
    src_rotations = readmatrix(rotations_dir + "src_rotations.dat");
    rec_rotations = readmatrix(rotations_dir + "rec_rotations.dat");
    ls_rotations = readmatrix(rotations_dir + "ls_rotations_"+rir_set_index+".dat");
    mic_rotations = readmatrix(rotations_dir + "mic_rotations_"+rir_set_index+".dat");
    
    src_directivities = string(readcell(directivities_dir + "src_directivities.csv"));
    rec_directivities = string(readcell(directivities_dir + "rec_directivities.csv"));
    ls_directivities = string(readcell(directivities_dir + "ls_directivities_"+rir_set_index+".csv"));
    mic_directivities = string(readcell(directivities_dir + "mic_directivities_"+rir_set_index+".csv"));
    
    current_config = RoomWithAAES(room_dims, ...
        alphas, ...
        src_coords, ...
        rec_coords, ...
        ls_coords, ...
        mic_coords, ...
        src_rotations, ...
        rec_rotations, ...
        ls_rotations, ...
        mic_rotations, ...
        src_directivities, ...
        rec_directivities, ...
        ls_directivities, ...
        mic_directivities, ...
        sample_rate, ...
        bit_depth);
    current_config.GenerateSystemIRs(output_dir + "Room Condition "+rir_set_index+"/", true);
end