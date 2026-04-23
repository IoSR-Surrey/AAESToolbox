# Active Acoustics Review Simulations
This directory provides the means to reproduce the AAES simulations featured in the review article [Active acoustic enhancement systems: A review](https://pubs.aip.org/asa/jasa/article/159/4/3533/3387630/Active-acoustic-enhancement-systems-A-review). Due to the large amount of data, intermediate audio files have not been included in this repository, but these can be generated locally using the workflow detailed below.

Requires [this fork](https://github.com/willcassidy00454/AKtools-FreqIndepSH) of AKtools to handle directional sources/receivers, and the [fdnToolbox](https://github.com/SebastianJiroSchlecht/fdnToolbox) for generating reverberators.

The general pipeline is as follows:
- Run ```GenerateReverberators.m``` to generate the reverberators used for the LTI conditions.
- Run ```GenerateRIRsForReviewPaper.m``` to generate an RIR for every loudspeaker-microphone pair, including room sources and audience receivers. Requires an AKtools fork as mentioned above.
- Run ```GenerateEqualisedRoom.m``` to apply equalisation to the H matrix of Room Condition 1 (becomes Room Condition 6).
- Run ```SimulateAAESForReviewPaper.m``` to simulate each AAES condition, saving the results into ```AAES Receiver RIRs/```.
- Call ```PlotReviewFigure(figure_number)``` from the command window to plot the review paper figures, or explore the other plotting tools found in ```AAESToolbox/Src/Plotting Toolbox/```.

```GenerateRIRsForReviewPaper.m``` and ```SimulateAAESForReviewPaper.m``` refer to an ```rir_set_index``` and ```aaes_index```, respectively. Table 1 (below) details the parameter arguments for these conditions.

## Table 1: Frequency Domain Simulation Conditions
This table presents the arguments for each frequency domain simulation.

| Fig. | RIR Set Index | AAES Index | Num Mics | Num LS | Absorption | Reverberator | Loop Gain | EQ |
|------|---------------|------------|----------|--------|------------|--------------|-----------|----|
| 7 | 1 | 1 | 16 | 16 | Base | 1: Identity | -4 dB | None |
| 7, 10 | 1 | 2 | 16 | 16 | Base | 1: Identity | -2 dB (-34.2 dBFS) | None |
| 8 | 1 | 3 | 16 | 16 | Base | 2: LTI FDN; RT Ratio = 0.5 | -68 dBFS | None |
| 8 | 1 | 4 | 16 | 16 | Base | 3: LTI FDN; RT Ratio = 1.0 | -68 dBFS | None |
| 8 | 1 | 5 | 16 | 16 | Base | 4: LTI FDN; RT Ratio = 1.5 | -68 dBFS | None |
| 8 | 1 | 6 | 16 | 16 | Base | 5: LTI FDN; RT Ratio = 2.0 | -68 dBFS | None |
| 10 | 6 (1 with EQ) | 7 | 16 | 16 | Base | 1: Identity | -34.2 dBFS | Two biquads on each feedback element |
| 10 | 6 (1 with EQ) | 8 | 16 | 16 | Base | 1: Identity | -2 dB | Two biquads on each feedback element |
| 11 | 1 | 9 | 16 | 16 | Base | 6: Hadamard | -5 dB | None |
| 11 | 1 | 10 | 16 | 16 | Base | 5: LTI FDN; RT Ratio = 2.0 | -5 dB | None |
| 11 | 4 | 11 | 16 | 16 | Base -50% | 6: Hadamard | -5 dB | None |
| 11 | 4 | 12 | 16 | 16 | Base -50% | 7: LTI FDN; RT Ratio = 2.0 (w.r.t. Room 4) | -5 dB | None |
| 12 | 1 | 13-31 | 16 | 16 | Base | 6: Hadamard | -6 to -1.5 dB | None |
| 12 | 4 | 32-50 | 16 | 16 | Base -50% | 6: Hadamard | -6 to -1.5 dB | None |
| 13 | 2 | 51 | 8 (cardioid) | 8 (cardioid) | Base | 1: Identity | -2 dB | None |
| 13 | 3 | 52 | 8 (omni) | 8 (cardioid) | Base | 1: Identity | -2 dB | None |


## Table 2: Time Domain Simulation Conditions
This table presents the arguments for each time domain simulation, allowing time-varying reverberators to be applied.

| Fig. | RIR Set Index | AAES Index | Num Mics | Num LS | Absorption | Reverberator | Loop Gain | EQ |
|------|---------------|------------|----------|--------|------------|--------------|-----------|----|
| 9 | 5 | 53 | 4 | 16 | Base | LTI FDN; RT Ratio = 2.0 | -6.5 dB (-36.1 dBFS) | None |
| 9 | 5 | 54 | 4 | 16 | Base | LTV FDN; RT Ratio = 2.0 | -36.1 dBFS | None |
| 9 | 5 | 55 | 4 | 16 | Base | LTV FDN; RT Ratio = 2.0 | -3.5 dB | None |
