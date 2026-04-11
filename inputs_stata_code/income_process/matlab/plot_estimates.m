%% Plot sigma2_epsilon estimates with bootstrap confidence intervals
% Loads H.mat and L.mat from the output directory produced by
% estimate_parameters.m. Each .mat file contains:
%   sigma2_epsilon_point  - point estimates (1 x C_eff)
%   sigma2_epsilon_bs     - bootstrap estimates (C_eff x n_reps), if n_reps > 0
%
% Called from income_process/ directory (same CWD as estimate_parameters.m).
% Output saved to ../../graphs/inputs/ (monorepo calibration figures).

variants   = {'mostdrop_hhslabinc', 'busno_drop_hhslabinc'};
output_dir = '../../graphs/inputs';

for ivar = 1:length(variants)
    variant    = variants{ivar};
    result_dir = ['./output/' variant '/'];

    fprintf('Plotting sigma2_epsilon for %s\n', variant);

    % --- Load H (college) ---
    H_data = load(fullfile(result_dir, 'H.mat'), ...
        'sigma2_epsilon_point');
    sig2_H = H_data.sigma2_epsilon_point;
    has_bootstrap = false;
    try
        H_bs = load(fullfile(result_dir, 'H.mat'), 'sigma2_epsilon_bs');
        sig2_H_bs = H_bs.sigma2_epsilon_bs;
        prc0975H  = prctile(sig2_H_bs', 97.5);
        prc0025H  = prctile(sig2_H_bs', 2.5);
        has_bootstrap = true;
    catch
        fprintf('  No bootstrap data for H — plotting point estimates only.\n');
    end

    % --- Load L (no college) ---
    L_data = load(fullfile(result_dir, 'L.mat'), ...
        'sigma2_epsilon_point');
    sig2_L = L_data.sigma2_epsilon_point;
    if has_bootstrap
        try
            L_bs = load(fullfile(result_dir, 'L.mat'), 'sigma2_epsilon_bs');
            sig2_L_bs = L_bs.sigma2_epsilon_bs;
            prc0975L  = prctile(sig2_L_bs', 97.5);
            prc0025L  = prctile(sig2_L_bs', 2.5);
        catch
            fprintf('  No bootstrap data for L — plotting point estimates only.\n');
            has_bootstrap = false;
        end
    end

    %% Main figure (paper version)

    ind = 1:11;   % bins 2:12 (drop first bin = pre-1950 cohort)
    fmain = figure('Visible', 'off');
        fmain.Position = [0 0 900 600];

        if has_bootstrap
            patch([ind'; flip(ind')], [prc0025H(2:end)'; flip(prc0975H(2:end)')], 'r', 'EdgeColor','r')
            patch([ind'; flip(ind')], [prc0025L(2:end)'; flip(prc0975L(2:end)')], 'b', 'EdgeColor','b')
            alpha(0.2)
            hold on

            plot(ind, prc0025H(2:end), 'r');
            plot(ind, prc0975H(2:end), 'r');
            handle_H = plot(ind, sig2_H(2:end), 'r', 'Linewidth', 4);

            plot(ind, prc0025L(2:end), 'b');
            plot(ind, prc0975L(2:end), 'b');
            handle_L = plot(ind, sig2_L(2:end), 'b', 'Linewidth', 4);
            hold off
        else
            hold on
            handle_H = plot(ind, sig2_H(2:end), 'r', 'Linewidth', 4);
            handle_L = plot(ind, sig2_L(2:end), 'b', 'Linewidth', 4);
            hold off
        end

        grid;
        axis tight;

        ax = gca;
        ax.XGrid = 'off';
        ax.YGrid = 'on';
        legend([handle_L, handle_H], 'High school or less', 'College or more', ...
            'Location', 'northoutside', 'Orientation', 'horizontal')

        ylabel('Variance')
        xlabel('Labor market entry year')
        xticks([1 3 5 7 9 11])
        yticks([0.01 0.02 0.03 0.04])
        ylim([0 0.04])
        xticklabels({'1955','1965','1975','1985','1995','2005'})
        legend('boxoff')
        set(gca, 'FontSize', 16)

    % Save to graphs/inputs/
    out_name = fullfile(output_dir, ['sigma2eps_' variant]);
    saveas(fmain, out_name, 'epsc');
    saveas(fmain, out_name, 'png');
    fprintf('  Saved: %s.eps, %s.png\n', out_name, out_name);
    close(fmain);

    %% Diagnostic figure (all bins including first)
    if has_bootstrap
        f = figure('Visible', 'off');
            f.Position = [0 0 1540 1040];

            subplot(1,2,1)
            plot(prc0025H);
            hold on;
            plot(prc0975H);
            plot(sig2_H);
            title('H')
            grid;
            axis tight;

            subplot(1,2,2)
            plot(prc0025L);
            hold on;
            plot(prc0975L);
            plot(sig2_L);
            title('L')
            grid;
            axis tight;

        saveas(f, fullfile(output_dir, ['sigma2eps_diagnostic_' variant]), 'png');
        close(f);
    end

end

fprintf('All plots saved to %s\n', output_dir);
