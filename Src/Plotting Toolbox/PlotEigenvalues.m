function PlotEigenvalues(A, fs, bins_are_first_dim)
    nexttile

    if bins_are_first_dim
        half_num_bins = floor(size(A, 1) / 2);
    else
        half_num_bins = floor(size(A, 3) / 2);
    end

    % Assumes dim 2 is the square matrix side length
    all_channel_eigenvalues = zeros(size(A, 2), half_num_bins);
    
    % num_bins / 2 used to discard Fourier transform symmetry
    for bin = 1:half_num_bins
        if bins_are_first_dim
            all_channel_eigenvalues(:, bin) = eig(squeeze(A(bin, :, :)));
        else
            all_channel_eigenvalues(:, bin) = eig(A(:, :, bin));
        end
    end

    num_maxima = 35;
    num_channels = size(A, 1);
    
    % Sort all eigs from largest to smallest
    [sorted_values, sorted_indices] = sort(abs(all_channel_eigenvalues), 'descend');

    max_channel_indices = sorted_indices(1, :);

    phases_across_channels = zeros(half_num_bins, 1);

    for bin = 1:half_num_bins
        phases_across_channels(bin) = angle(all_channel_eigenvalues(max_channel_indices(bin), bin));%(sorted_indices(1, :)));
    end

    maxima_across_channels = sorted_values(1, :);

    [~, sorted_indices] = sort(maxima_across_channels, 'descend');

    % Get first num_maxima indices
    max_eigs_dB = maxima_across_channels;%mag2db(maxima_across_channels / max(maxima_across_channels));
    max_indices = sorted_indices(1:num_maxima);

    % Find max and normalise to 0 dB
    max_eigs_padded = -100 * ones(half_num_bins, 1);
    max_eigs_padded(max_indices) = max_eigs_dB(max_indices);

    max_eigs_phases_padded = zeros(half_num_bins, 1);
    max_eigs_phases_padded(max_indices) = phases_across_channels(max_indices);

    % Plot
    % [max_eigs, indices_of_max_eigs] = maxk(abs(all_channel_eigenvalues), num_maxima);

    % for i = 1:num_channels
    PlotEigs(maxima_across_channels, phases_across_channels, max_eigs_padded, max_indices, max_eigs_phases_padded, fs, half_num_bins);
    % end
end

function PlotEigs(maxima_across_channels, phases_across_channels, max_eigs_padded, max_indices, phases, fs, half_num_bins)
    frequency_resolution = (fs/2) / half_num_bins;
    frequency_values = frequency_resolution:frequency_resolution:(fs/2);
    % eigenvalue_magnitudes = abs(eigs);
    % normalised_eigenvalues = mag2db(eigenvalue_magnitudes / max_of_all_eigs);

    max_of_all_eigs = max(abs(maxima_across_channels));

    maxima_dBFS = mag2db(maxima_across_channels / max_of_all_eigs);

    scatter(maxima_dBFS, frequency_values, 2, "filled", "o", "MarkerEdgeColor", "black", "MarkerFaceColor", "black");
    set(gca,'yscale','log');
    % semilogy(maxima_dBFS, frequency_values, "Color", "black");%, "MarkerIndices", max_indices, "Marker", ".", "MarkerSize", 28, "Color", "black");
    % semilogy(max_eigs_padded, frequency_values, "MarkerIndices", max_indices, "Marker", ".", "MarkerSize", 18, "Color", "black");
    hold on
    grid on
    phases_transformed = abs(phases(max_indices));
    scatter(maxima_dBFS(max_indices), frequency_values(max_indices), 100, phases_transformed, "filled", "MarkerFaceAlpha", 0.4);
    colormap("autumn");
    cb = colorbar("south");
    set(cb, "Ydir", "reverse", "Ticks", [0, pi], "TickLabels", ["0", "\pm\pi"], "position", [0.75 0.1 0.1 0.03]);
    clim([0, pi]);
    ylabel(cb, "Phase");
    ylim([20 20000]);
    yticks([20, 200, 2000, 20000]);
    yticklabels(["20", "200", "2k", "20k"]);
    ylabel("Frequency (Hz)");
    xlabel("Magnitude (dBFS)");
    xlim([-9 1]);

    set(gca,'fontsize', 15);
    title("Title","FontSize",16,"FontWeight","normal");

    hold off
end