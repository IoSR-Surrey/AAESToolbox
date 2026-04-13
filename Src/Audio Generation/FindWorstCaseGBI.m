
% This function returns the available gain before instability of the feedback
% matrix A in decibels, where a negative output indicates the input is
% unstable in its current state.
%
% Input:
% open_loop_matrix : (num_inputs x num_outputs x num_bins) where num_inputs
% = num_outputs

function gbi_dB = FindWorstCaseGBI(open_loop_matrix)
    eigenvalues = pageeig(open_loop_matrix);

    gbi = max(real(eigenvalues),[],"all");
    gbi_dB = -20 * log10(gbi);
end