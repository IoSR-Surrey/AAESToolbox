# AAES Toolbox
A collection of MATLAB scripts for simulating active acoustic enhancement systems.

Requires [AKtools](https://github.com/f-brinkmann/AKtools) (unless you already have an RIR dataset).

## Review Paper Simulations Branch
The [```review-simulations```](https://github.com/wjcassidy/AAESToolbox/blob/review-simulations/Active%20Acoustics%20Review/README.md) branch provides scripts and audio examples to recreate the simulations from the paper "Active Acoustic Enhancement Systems - A Review and Simulations" (link to follow). See the [README](https://github.com/wjcassidy/AAESToolbox/blob/review-simulations/Active%20Acoustics%20Review/README.md) for more information.

## ```AAESSimulator.m```

This script allows the user to simulate multiple AAESs iteratively given existing impulse response data. These data can either be measured from real AAES installations, or simulated using ```AutomatedRIRGenerator.m```.

### Parameters

- ```rir_parent_dir``` is the read directory for the room impulse responses. The simulator will use these RIRs to populate the model.
- ```output_dir``` is the write directory for the simulated output RIRs.
- ```num_channels_set``` specifies the different channel counts available e.g. ```[8 12 16]```. This currently assumes the number of microphones equals the number of loudspeakers.
- ```room_nums``` specifies the indices of the rooms to use according to the folder labels in ```rir_parent_dir``` e.g. ```[1 2 3]```.
- ```alpha_sets``` specifies the indices of the alpha sets to use according to the folder labels in ```rir_parent_dir``` e.g. ```[1 2 3]```.
- ```loop_gain_biases_dB``` specifies the loop gains to use relative to the limit of stability in decibels e.g. ```[-2 -4 -6]```. A relative loop gain of 0 dB should be critically stable.
- ```uses_parallel_processing``` can be set to ```true``` to use MATLAB's Parallel Computing Toolbox for parallelisation.

## ```AutomatedRIRGenerator.m```

This script simulates the room impulse responses between loudspeaker and microphone positions in shoebox rooms. Multiple rooms can be specified with varying dimensions and absorption coefficients in seven octave bands. The absorption coefficients are read from ```.dat``` files, as well as the loudspeaker and microphone coordinates. Find examples in the folders ```Example Absorption Coefficients``` and ```Example Transducer Coordinates```.

### Current Assumptions

- This script will create RIRs for the example data, which are for 8, 12 and 16-channel square AAESs.
- Mono sources and receivers are used, positioned 1/3 and 2/3 along the floor diagonal at 1.2 metres high.
- All sources and receivers are omnidirectional, but this can be changed in ```GenerateAKToolsRIRs.m```.

### Parameters

- ```room_dims``` specifies the room dimensions in metres in the following format: ```[x y z; x y z; etc.]``` where ```x``` and ```y``` are the floor dimensions and ```z``` is height.
- ```absorptions_dir``` is the read directory of the absorption coefficients.
- ```transducer_coords_dir``` is the read directory of the transducer coordinates.
- ```output_parent_dir``` is the write directory of the simulated RIRs. These will be written into folders regarding each room condition.
- ```uses_parallel_processing``` can be set to ```true``` to use MATLAB's Parallel Computing Toolbox for parallelisation.
