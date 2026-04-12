% This script loads Room Condition 1, equalises the "H" (feedback) matrix,
% and saves all IRs into Room Condition 5. The following website was used
% to calculate the biquad coefficients:
% https://www.earlevel.com/main/2021/09/02/biquad-calculator-v3/

read_dir = "Active Acoustics Review/Generated AAES RIRs/Room Condition 1/";
write_dir = "Active Acoustics Review/Generated AAES RIRs/Room Condition 5/";
num_rows = 16;
num_cols = 16;
CopyRoomAndEqualise(read_dir, write_dir, num_rows, num_cols);

function CopyRoomAndEqualise(read_dir, write_dir, num_rows, num_cols)
    b = [0.9833149058539373 -1.8342605438232056 0.8613046229420136 % -2.1 dB peak @ 810 Hz Q 0.8
        0.9847343376264435 -1.6080644395882402 0.6800564732437505]; % -1.4 dB low shelf @ 2 kHz
    a = [1 -1.8342605438232056 0.8446195287959508
        1 -1.6031037877693375 0.6697514626890969];
    sos = dsp.SOSFilter(b, a);

    PlotBodeMag(sos);

    copyfile(read_dir, write_dir);

    for row = 1:num_rows
        for col = 1:num_cols
            [ir, fs] = audioread(read_dir + "H_R"+row+"_S"+col+".wav");
            filtered_output = sos(ir);
            audiowrite(write_dir + "H_R"+row+"_S"+col+".wav", filtered_output, fs, "BitsPerSample", 32);
        end
    end
end

function PlotBodeMag(sos)
    nexttile(4)
    [h, w] = freqz(sos);
    fs = 48000;
    semilogy(20*log10(abs(h)), w / (2 * pi) * fs);
    grid on
    xlim([-9 1]);
    ylim([20, 20000]);
    xlabel("Magnitude (dB)");
    ylabel("Frequency (Hz)");
    yticks([20, 200, 2000, 20000]);
end