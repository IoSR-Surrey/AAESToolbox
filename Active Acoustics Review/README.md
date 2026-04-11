# Active Acoustics Review Simulations
This directory provides the means to reproduce the AAES simulations featured in the review paper "Active Acoustic Enhancement Systems - A Review" (link to follow).

Requires [this fork](https://github.com/willcassidy00454/AKtools-FreqIndepSH) of AKtools to handle directional sources/receivers, and the [fdnToolbox](https://github.com/SebastianJiroSchlecht/fdnToolbox) for generating time-varying reverberators.

The general pipeline is as follows:
- Generate the reverberators used for the LTI conditions with ```GenerateReverberators.m```.
- Generate an IR for every loudspeaker-microphone pair, including the room source and audience receiver. Uses AKtools via ```GenerateRIRsForReviewPaper.m```.
- Apply equalisation to the H matrix if necessary with ```EqualiseHMatrix.m```.
- Run the AAES simulation with ```SimulateAAESForReviewPaper.m``` which saves into ```AAES Receiver RIRs/```. For the LTV reverberator conditions, a time-domain model is used instead; this will be added soon.
- Explore the simulated RIRs using ```PlotRIR.m``` (found in ```AAESToolbox/Src/Plotting Toolbox/```).

Each stage can be run for select rooms or conditions, e.g.:
```
for condition_index = [7 9 10]
    GenerateRIRs(...);
end
```
NB: In ```GenerateRIRsForReviewPaper.m```, the ```condition_index``` refers to the RIR Set Index in Table 1, whereas in ```SimulateAAESForReviewPaper.m```, the ```row``` refers to the AAES Index. This is because multiple AAES simulations may use the same RIR set, for example when comparing different loop gains in the same configuration.

The final RIRs used for the paper figures can be found in the folder ```AAES Receiver RIRs/```, labelled according to the AAES Index in Table 1 below. Due to the large amount of data, intermediate audio files have not been included, but these can be generated locally using the provided scripts.

## Table 1: LTI Simulation Conditions
This table presents the arguments for each time-invariant simulation, using the frequency domain model. The AAES Index column corresponds to the labels in the output directory (```AAES Receiver RIRs/```).

| Fig. | RIR Set Index | AAES Index | Num Mics | Num LS | Absorption | Reverberator | Loop Gain | EQ |
|------|---------------|------------|----------|--------|------------|--------------|-----------|----|
| 7 | 1 | 1 | 16 | 16 | Base | 1: Identity | -4 dB | None |
| 7 | 1 | 2 | 16 | 16 | Base | 1: Identity | -2 dB | None |
| 8 | 1 | 3 | 16 | 16 | Base | 5: LTI FDN; RT Ratio = 0.5 | -68 dBFS | None |
| 8 | 1 | 4 | 16 | 16 | Base | 6: LTI FDN; RT Ratio = 1.0 | -68 dBFS | None |
| 8 | 1 | 5 | 16 | 16 | Base | 7: LTI FDN; RT Ratio = 1.5 | -68 dBFS | None |
| 8 | 1 | 6 | 16 | 16 | Base | 8: LTI FDN; RT Ratio = 2.0 | -68 dBFS | None |
| 10 | 8 (1 with EQ) | 7 | 16 | 16 | Base | 1: Identity | -5 dB | Two biquads on each feedback element |
| 10 | 8 (1 with EQ) | 8 | 16 | 16 | Base | 1: Identity | -2 dB | Two biquads on each feedback element |
| 11 | 1 | 9 | 16 | 16 | Base | 14: Hadamard | -5 dB | None |
| 11 | 1 | 10 | 16 | 16 | Base | 15 (8?): LTI FDN; RT Ratio = 2.0 | -5 dB | None |
| 11 | 12 | 11 | 16 | 16 | Base -50% | 14: Hadamard | -5 dB | None |
| 11 | 12 | 12 | 16 | 16 | Base -50% | 16: LTI FDN; RT Ratio = 2.0 (w.r.t. room 12) | -5 dB | None |
| 12 | 1 | 13 | 16 | 16 | Base | 14: Hadamard | -6 to -1.5 dB | None |
| 12 | 12 | 14 | 16 | 16 | Base -50% | 14: Hadamard | -6 to -1.5 dB | None |
| 13 | 9 | 15 | 8 (cardioid) | 8 (cardioid) | Base | 1: Identity | -2 dB | None |
| 13 | 10 | 16 | 8 (omni) | 8 (cardioid) | Base | 1: Identity | -2 dB | None |

(time-varying simulations to be added)
