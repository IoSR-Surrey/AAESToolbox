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

## Table 1: Simulation Conditions
This table presents the arguments for each simulation parameter. The simulation ID corresponds to the labels in the output directory (```AAES Receiver RIRs/```).

| RIR Set Index | AAES Index | Mic Layout   | LS Layout | Absorption | Reverberator | Loop Gain | EQ |
|---------------|------------|--------------|-----------|------------|--------------|-----------|----|
| 1 | 1 | 16ch (regen) | 16ch | Reference | 1: 16x16 Identity | -5 dB | None |
| 2 | 2 | 4ch (in-line) | 16ch | Reference | 8: 16x4 LTI FDN RT Ratio = 2 | -16 dB | None |
| 3 | 3 | 16ch (hybrid) | 16ch | Reference | 4: 16x16 Hybrid (Rev 8 for left-most 16x4, rest identity) | -5 dB | None |

(more rows coming soon)
