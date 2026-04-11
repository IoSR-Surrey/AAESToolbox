clear

%% Figure 7 (loop gain demo)
[ir_passive, fs] = audioread("Active Acoustics Review/Generated AAES RIRs/Room Condition 1/E_R1_S1.wav");
plot_length_sec = 2.5;
ir = zeros(plot_length_sec * fs, 1);
ir(1:length(ir_passive)) = ir_passive;

for aaes_index = 1:3
    PlotSpectrogram(ir,fs,plot_length_sec,true);
    PlotT30Line(ir, fs)
    if aaes_index < 3
        [ir, ~] = audioread("Active Acoustics Review/AAES Receiver RIRs/aaes_condition_"+aaes_index+".wav");
    end
end

SetFigureSize("triple_vertical")

%% Figure 8 (RT ratio demo)
[ir, fs] = audioread("Active Acoustics Review/Generated AAES RIRs/Room Condition 1/E_R1_S1.wav");
plot_length_sec = 2.25;
line_styles = ["--", "-", ":", "-.", "-"];
aaes_indices = 3:6;
octave_band_centre = 1000;
hold on

for plot_index = 1:5
    PlotEDC(ir, fs, octave_band_centre, line_styles(plot_index), plot_length_sec);
    if plot_index < 5
        aaes_index = aaes_indices(plot_index);
        [ir, ~] = audioread("Active Acoustics Review/AAES Receiver RIRs/aaes_condition_"+aaes_index+".wav");
    end
end

%% Figure 9 (time variation demo)

%% Figure 10 (EQ demo with eigenvalues)
figure
SetFigureSize("triple_vertical")
plot_length_sec = 3;
aaes_indices = [2,7,8];

for aaes_index = aaes_indices
    [ir, fs] = audioread("Active Acoustics Review/AAES Receiver RIRs/aaes_condition_"+aaes_index+".wav");
    PlotSpectrogram(ir,fs,plot_length_sec,true);
    PlotT30Line(ir, fs)
end

figure
SetFigureSize("double_vertical")
rir_base_dir = "Active Acoustics Review/Generated AAES RIRs/";
reverberator_base_dir = "Active Acoustics Review/Reverberators/";
bit_depth = 32;

conditions = readmatrix("Active Acoustics Review/Src/SimulationConditionsFinalOnly.dat");
aaes_indices = [2,7];

for aaes_index = aaes_indices
    rir_set_index = conditions(aaes_index, 1);
    num_mics = conditions(aaes_index, 2);
    num_ls = conditions(aaes_index, 3);
    rev_index = conditions(aaes_index, 4);
    loop_gain = conditions(aaes_index, 5);
    loop_gain_is_relative = conditions(aaes_index, 6);

    GenerateAAESIRs(rir_base_dir + "Room Condition " + rir_set_index + "/", ...
        reverberator_base_dir + "Reverberator " + rev_index + "/", ...
        "", ...
        "", ...
        loop_gain, ...
        num_ls, ...
        num_mics, ...
        bit_depth, ...
        true, ...
        loop_gain_is_relative, ...
        true);
end

%% Figure 11 (absorption EDC demo)
plot_length_sec = 4;
room_conditions = [1,12]; % % % % % This needs changing to 1:2 after renaming the room conditions
aaes_conditions = 9:12;
aaes_plot_index = 1;
line_styles = ["-", ":"];

for subplot_index = 1:2
    nexttile
    hold on
    room_index = room_conditions(subplot_index);
    [ir, fs] = audioread("Active Acoustics Review/Generated AAES RIRs/Room Condition "+room_index+"/E_R1_S1.wav");
    PlotEDC(ir, fs, false, "--", plot_length_sec);

    for plot_index = 1:2
        aaes_index = aaes_conditions(aaes_plot_index);
        [ir, ~] = audioread("Active Acoustics Review/AAES Receiver RIRs/aaes_condition_"+aaes_index+".wav");
        PlotEDC(ir, fs, false, line_styles(plot_index), plot_length_sec);
        aaes_plot_index = aaes_plot_index + 1;
    end
end

SetFigureSize("double_vertical")

%% Figure 12 (absorption colouration demo)
hold on
aaes_conditions = [13:31; 32:50];
loop_gains = -6:0.25:-1.5;

for plot_index = 1:2
    colouration_values = zeros(length(loop_gains), 1);
    colouration_index = 1;
    for aaes_index = aaes_conditions(plot_index, :)
        [ir, fs] = audioread("Active Acoustics Review/AAES Receiver RIRs/aaes_condition_"+aaes_index+".wav");
        colouration_values(colouration_index) = GetColouration(ir,fs,NFFT=2^19);
        colouration_index = colouration_index + 1;
    end

    plot(loop_gains, colouration_values);
end

legend(["Base", "-50%"])
SetFigureSize("single")

%% Figure 13 (directivity demo - DRR heatmaps and spectrograms)

% This estimates the time-of-flight delay between each source and receiver
% in the "H" (feedback) matrix, based on the maximum absolute value of each
% IR in the omni condition. This is then used to determine the DRR of the
% cardioid condition, since the direct signal will be attenuated so the max
% may not indicate the location of the direct signal.
[~, delay_matrix] = GetMatrixDRR("Active Acoustics Review/Generated AAES RIRs/Room Condition 10/", "H", 8, 8);

PlotMatrixDRR("Active Acoustics Review/Generated AAES RIRs/Room Condition 10/", "H", 8, 8, "Omni Mics");
PlotMatrixDRR("Active Acoustics Review/Generated AAES RIRs/Room Condition 9/", "H", 8, 8, "Cardioid Mics", delay_matrix);
SetFigureSize("double_horizontal")

figure
for aaes_index = [52, 51]
    [ir, fs] = audioread("Active Acoustics Review/AAES Receiver RIRs/aaes_condition_"+aaes_index+".wav");
    PlotSpectrogram(ir,fs,2,true)
end

SetFigureSize("double_vertical")

function PlotT30Line(ir, fs)
    hold on
    rt = FindT30(ir, fs);
    semilogy([rt rt], [0.02 20], "LineStyle", "--", "LineWidth", 1, "Color", "white");
end

function SetFigureSize(mode)
    if mode == "single"
        set(gcf, "position", [300 300 600 300]);
    elseif mode == "double_horizontal"
        set(gcf,'position',[300,300,1000,400]);
    elseif mode == "triple_vertical"
        set(gcf, "position", [300 0 650 800]);
    elseif mode == "double_vertical"
        set(gcf, "position", [300 0 650 500]);
    elseif mode == "triple_horizontal"
        set(gcf, "position", [300 0 1120 300]);
    end
end