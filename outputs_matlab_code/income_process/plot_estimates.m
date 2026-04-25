%% Plot sigma2_epsilon estimates with bootstrap confidence intervals
% Loads point estimates from H.mat / L.mat (the live pipeline output,
% overwritten by every run of estimate_parameters.m including the default
% N_REPS=0). Loads bootstrap confidence intervals from H_archive.mat /
% L_archive.mat if present - these hold the authors' paper-baseline
% 1000-rep bootstrap and are tracked in the repository; they are never
% overwritten by run_estimation.bat. This split means a default
% point-estimate rerun cannot clobber the committed CI arrays.
%
% Fallback: if no *_archive.mat exists, look for sigma2_epsilon_bs inside
% H.mat / L.mat directly (pre-split layout). If neither has bootstrap,
% plot point estimates only.
%
% Each .mat file contains:
%   sigma2_epsilon_point  - point estimates (1 x C_eff)
%   sigma2_epsilon_bs     - bootstrap estimates (C_eff x n_reps), if n_reps > 0
%
% Can be called from any working directory.
% Output saved to graphs/inputs/ (monorepo calibration figures).

variants = {'mostdrop_hhslabinc', 'busno_drop_hhslabinc'};
this_dir = fileparts(mfilename('fullpath'));
repo_root = fullfile(this_dir, '..', '..');
result_root = fullfile(repo_root, 'inputs_matlab_code', 'income_process', 'output');
output_dir = fullfile(repo_root, 'graphs', 'inputs');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

for ivar = 1:length(variants)
    variant    = variants{ivar};
    result_dir = fullfile(result_root, variant);

    fprintf('Plotting sigma2_epsilon for %s\n', variant);

    % --- Point estimates: always from live H.mat / L.mat ---
    H_data = load(fullfile(result_dir, 'H.mat'), 'sigma2_epsilon_point');
    L_data = load(fullfile(result_dir, 'L.mat'), 'sigma2_epsilon_point');
    sig2_H = H_data.sigma2_epsilon_point;
    sig2_L = L_data.sigma2_epsilon_point;

    % --- Bootstrap arrays: prefer *_archive.mat (paper baseline, tracked);
    %     fall back to live *.mat if no archive exists (e.g. after a full
    %     bootstrap run that rewrote both live and archive). ---
    sig2_H_bs = [];
    sig2_L_bs = [];
    H_archive = fullfile(result_dir, 'H_archive.mat');
    L_archive = fullfile(result_dir, 'L_archive.mat');
    H_live    = fullfile(result_dir, 'H.mat');
    L_live    = fullfile(result_dir, 'L.mat');

    try
        if exist(H_archive, 'file')
            tmp = load(H_archive, 'sigma2_epsilon_bs');
            sig2_H_bs = tmp.sigma2_epsilon_bs;
            fprintf('    H CI source: H_archive.mat\n');
        else
            tmp = load(H_live, 'sigma2_epsilon_bs');
            sig2_H_bs = tmp.sigma2_epsilon_bs;
            fprintf('    H CI source: H.mat (no archive found)\n');
        end
    catch
    end
    try
        if exist(L_archive, 'file')
            tmp = load(L_archive, 'sigma2_epsilon_bs');
            sig2_L_bs = tmp.sigma2_epsilon_bs;
            fprintf('    L CI source: L_archive.mat\n');
        else
            tmp = load(L_live, 'sigma2_epsilon_bs');
            sig2_L_bs = tmp.sigma2_epsilon_bs;
            fprintf('    L CI source: L.mat (no archive found)\n');
        end
    catch
    end

    has_bootstrap = false;
    if ~isempty(sig2_H_bs) && ~isempty(sig2_L_bs)
        % Drop reps where any bin failed to converge (all-NaN propagates
        % through prctile; reps are failed per-column not per-bin).
        valid_H   = ~any(isnan(sig2_H_bs), 1);
        valid_L   = ~any(isnan(sig2_L_bs), 1);
        prc0975H  = prctile(sig2_H_bs(:, valid_H)', 97.5);
        prc0025H  = prctile(sig2_H_bs(:, valid_H)', 2.5);
        prc0975L  = prctile(sig2_L_bs(:, valid_L)', 97.5);
        prc0025L  = prctile(sig2_L_bs(:, valid_L)', 2.5);
        fprintf('  H bootstrap: %d valid / %d total reps.\n', sum(valid_H), numel(valid_H));
        fprintf('  L bootstrap: %d valid / %d total reps.\n', sum(valid_L), numel(valid_L));
        has_bootstrap = true;
    else
        fprintf('  No bootstrap data ??" plotting point estimates only.\n');
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

end

fprintf('All plots saved to %s\n', output_dir);
