%% INCOME PROCESS PARAMETER ESTIMATION: Consolidated MATLAB Script
% Produces: _data_sigma2eps_{variant}_avghourlyhh.txt (earnings shock variances)
%           H.mat, L.mat (full estimation results with bootstrap CIs)
%
% Reads covariance matrices produced by estimate_income_process.do
%
% Source script (on Dropbox, for reference):
%   matlab/main_types_binned.m
%
% Income process:
%   zeta(c,t,i) = rho * zeta(c,t-1,i) + epsilon(c,t,i)
%   eta(c,t,i)  = gamma(c,i) + zeta(c,t,i) + varepsilon(c,t,i)
%
%   epsilon     ~ N(0, sigma2_epsilon(c))   cohort-specific
%   varepsilon  ~ N(0, sigma2_varepsilon)   iid measurement error
%   gamma       ~ N(0, sigma2_gamma(c))     cohort-specific fixed effect
%   zeta(c,0,i) ~ N(0, sigma2_eta(c))      initial dispersion

clear all

% Add helper functions to path (loader, objective_cohort_binned,
% create_parameters_binned are in matlab/ subdirectory)
addpath('matlab');

%% ========================================================================
%  CONFIGURATION (only section user ever edits)
%  ========================================================================
variants  = {'mostdrop_hhslabinc', 'busno_drop_hhslabinc'};
measure   = 'avghourlyhh';
% n_reps: 0 = point estimate only (fast), 1000 = full bootstrap for confidence bands.
% Override via environment variable N_REPS (e.g. `set N_REPS=1000` before running
% run_estimation.bat). Leave unset for the default of 0.
n_reps_env = getenv('N_REPS');
if ~isempty(n_reps_env)
    n_reps = str2double(n_reps_env);
else
    n_reps = 0;
end
fprintf('Using n_reps = %d\n', n_reps);

%% ========================================================================
%  MODEL SETUP (should not need editing)
%  ========================================================================

% Cohort structure
p.C     = 60;                         % number of single-year cohorts
opt.cohort_aggregation = 5;           % years per cohort bin
p.C_eff = p.C / opt.cohort_aggregation;  % = 12 five-year bins
p.T     = 45;                         % max years per cohort (ages 20-64)

% Calendar parameters
p.first_cohort = 1926;
p.data_start   = 1970;
p.data_end     = 2017;
p.age_start    = 20;
p.age_end      = p.age_start + p.T;
p.Nyears       = p.data_end - p.data_start + 1;

% Estimation specification: AR(1) with cohort-specific sigma2_epsilon, no
% fixed effects, no transitory component, no initial dispersion.
opt.epsilon         = 0;    % cohort-specific
opt.eta             = -1;   % no initial dispersion
opt.gamma           = -1;   % no fixed effects
opt.varepsilon      = -1;   % no transitory shock
opt.trend_epsilon   = 0;    % fixed effects (not trends)
opt.trend_eta       = 0;
opt.trend_gamma     = 0;
opt.time_aggregation = 1;

% Weighting matrix
opt.W               = 0;    % identity (= 1 for Kaplan 2012 n^{-1/2})

% Bootstrap
opt.bootstrap       = (n_reps > 0);
opt.bootstrap_rep   = n_reps;

% Fortran output mapping
% sigma2_epsilon has p.C_eff = 12 bins, but Fortran needs 15 values per type.
% Mapping: bin 2 repeated 5x (pre-data padding, model periods 1935-1959),
% then bins 3:12 (model periods 1960-2009). Bin 1 is dropped (oldest
% cohort, born 1926, has fewest observations and unreliable estimates).
n_fortran_sigma2eps = 15;
n_pad               = 5;    % how many times to repeat first exported bin
first_export_bin    = 2;    % first bin to export (bin 1 = 1926 is dropped)

types = {'H', 'L'};         % H = college, L = no college
year  = p.first_cohort : (p.first_cohort + p.C - 1);

%% ========================================================================
%  VARIANT LOOP
%  ========================================================================

for ivar = 1:length(variants)
    variant  = variants{ivar};
    data_dir = ['./output/' variant '/cov_binned/'];
    save_dir = ['./output/' variant '/'];

    fprintf('\n###############################################################\n');
    fprintf('# Processing variant: %s\n', variant);
    fprintf('###############################################################\n');

    % Preallocate storage for sigma2eps export
    sigma2eps_fortran = zeros(n_fortran_sigma2eps, length(types));

    for itype = 1:length(types)
        type = types{itype};
        fprintf('\n=== Estimating type %s ===\n', type);

        % ------------------------------------------------------------------
        % Load point-estimate covariance matrices
        % ------------------------------------------------------------------
        clear cov_mat Nobs_mat
        for c = 1:p.C_eff
            filename = fullfile(data_dir, ...
                [type '_cohort' num2str(year((c-1)*5+1)) '.txt']);
            loader   % reads txt file into 'raw'
            cov_mat(:,:,c) = cell2mat(raw);

            filename = fullfile(data_dir, ...
                ['Nobs_' type '_cohort' num2str(year((c-1)*5+1)) '.txt']);
            loader
            Nobs_mat(:,:,c) = cell2mat(raw);
        end

        cov_mat  = cov_mat(1:p.T, 1:p.T, 1:p.C_eff);
        Nobs_mat = Nobs_mat(1:p.T, 1:p.T, 1:p.C_eff);

        % Weighting matrix
        if opt.W == 0
            W = Nobs_mat ./ Nobs_mat;   % identity (NaN where Nobs=0)
        elseif opt.W == 1
            W = Nobs_mat .^ (-1/2);     % Kaplan 2012
        end

        % ------------------------------------------------------------------
        % Build initial guesses
        % ------------------------------------------------------------------
        guess = [];

        % eta (initial dispersion)
        if opt.eta == -1
            guess_eta = [];  opt.Neta = 0;
        elseif opt.eta == 1
            if opt.trend_eta == 0
                guess_eta = log(ones(p.C_eff,1));  opt.Neta = p.C_eff;
            else
                guess_eta = zeros(opt.trend_eta+1,1);  opt.Neta = opt.trend_eta+1;
            end
        elseif opt.eta == 0
            guess_eta = log(1);  opt.Neta = 1;
        end

        % gamma (fixed effects)
        if opt.gamma == -1
            guess_gamma = [];  opt.Ngamma = 0;
        elseif opt.gamma == 1
            if opt.trend_gamma == 0
                guess_gamma = log(ones(p.C_eff,1));  opt.Ngamma = p.C_eff;
            else
                guess_gamma = zeros(opt.trend_gamma+1,1);  opt.Ngamma = opt.trend_gamma+1;
            end
        elseif opt.gamma == 0
            guess_gamma = log(1);  opt.Ngamma = 1;
        end

        % epsilon (innovation variance)
        if opt.epsilon == -2
            guess_epsilon = [];  opt.Nepsilon = 0;
        elseif opt.epsilon == -1
            guess_epsilon = log(.01);  opt.Nepsilon = 1;
        elseif opt.epsilon == 0
            if opt.trend_epsilon == 0
                guess_epsilon = log(ones(p.C_eff,1));  opt.Nepsilon = p.C_eff;
            else
                guess_epsilon = zeros(opt.trend_epsilon+1,1);  opt.Nepsilon = opt.trend_epsilon+1;
            end
        elseif opt.epsilon == 1
            if opt.trend_epsilon == 0
                guess_epsilon = log(ones(ceil(p.Nyears/opt.time_aggregation),1));
                opt.Nepsilon = ceil(p.Nyears/opt.time_aggregation);
            else
                guess_epsilon = zeros(opt.trend_epsilon+1,1);  opt.Nepsilon = opt.trend_epsilon+1;
            end
        end

        % rho and varepsilon
        guess_rho = 0.99;
        if opt.varepsilon == 1
            guess_varepsilon = log(.01);  opt.Nvarepsilon = 1;
        else
            guess_varepsilon = [];  opt.Nvarepsilon = 0;
        end

        guess = [guess_rho; guess_varepsilon; guess_eta; guess_gamma; guess_epsilon];
        opt.Nguess = length(guess);

        % ------------------------------------------------------------------
        % Point estimation
        % ------------------------------------------------------------------
        fprintf('Running point estimation...\n');
        if opt.epsilon == 0
            [guess, value] = lsqnonlin(@(x) objective_cohort_binned(x,cov_mat,p,opt,W), guess);
        elseif opt.epsilon == 1
            [guess, value] = lsqnonlin(@(x) objective_time(x,cov_mat,p,opt,W), guess);
        else
            [guess, value] = lsqnonlin(@(x) objective_cohort_binned(x,cov_mat,p,opt,W), guess);
        end

        % Unpack point estimates
        create_parameters_binned;
        rho_point               = rho;
        sigma2_gamma_point      = sigma2_gamma;
        sigma2_eta_point        = sigma2_eta;
        sigma2_varepsilon_point = sigma2_varepsilon;
        sigma2_epsilon_point    = sigma2_epsilon;

        fprintf('  rho = %.6f\n', rho_point);
        fprintf('  sigma2_epsilon (bins 1-%d): ', p.C_eff);
        fprintf('%.6f ', sigma2_epsilon_point);
        fprintf('\n');

        guess_initial = guess;   % save for bootstrap warm start

        % ------------------------------------------------------------------
        % Bootstrap (if requested)
        % ------------------------------------------------------------------
        if opt.bootstrap == 1
            fprintf('Running bootstrap (%d reps)...\n', opt.bootstrap_rep);
            clear cov_mat Nobs_mat

            for k = 1:opt.bootstrap_rep
                % Load bootstrap covariance matrices for rep k
                for c = 1:p.C_eff
                    filename = fullfile(data_dir, ...
                        [type '_cohort' num2str(year((c-1)*5+1)) '_rep' num2str(k) '.txt']);
                    loader
                    cov_mat(:,:,c) = cell2mat(raw);

                    filename = fullfile(data_dir, ...
                        ['Nobs_' type '_cohort' num2str(year((c-1)*5+1)) '_rep' num2str(k) '.txt']);
                    loader
                    Nobs_mat(:,:,c) = cell2mat(raw);
                end

                try
                    [guess_bs, ~] = lsqnonlin(@(x) objective_cohort_binned(x,cov_mat,p,opt,W), guess_initial);
                    guess = guess_bs;
                    create_parameters_binned;
                    rho_bs(:,k)               = rho;
                    sigma2_gamma_bs(:,k)      = sigma2_gamma;
                    sigma2_eta_bs(:,k)        = sigma2_eta;
                    sigma2_varepsilon_bs(:,k) = sigma2_varepsilon;
                    sigma2_epsilon_bs(:,k)    = sigma2_epsilon;
                catch ME
                    fprintf('  Bootstrap rep %d failed: %s\n', k, ME.message);
                    rho_bs(:,k)               = NaN;
                    sigma2_gamma_bs(:,k)      = NaN;
                    sigma2_eta_bs(:,k)        = NaN;
                    sigma2_varepsilon_bs(:,k) = NaN;
                    sigma2_epsilon_bs(:,k)    = NaN;
                end

                if mod(k, 100) == 0
                    fprintf('  Completed %d / %d bootstrap reps\n', k, opt.bootstrap_rep);
                end
            end
        end

        % ------------------------------------------------------------------
        % Save results
        % ------------------------------------------------------------------
        mat_file = fullfile(save_dir, [type '.mat']);
        fprintf('Saving %s\n', mat_file);
        save(mat_file);

        % When a bootstrap was run (n_reps > 0), also mirror the workspace to
        % <type>_archive.mat. The archive is the CI source for plot_estimates.m
        % and the file that is tracked in the repository; refreshing it on
        % every bootstrap run keeps the archive in sync with the latest
        % resampling. A default point-estimate run (n_reps == 0) does NOT
        % touch the archive, so the committed paper-baseline 1000-rep
        % bootstrap is preserved through a `set N_REPS=0 & run_estimation.bat`
        % replication.
        if n_reps > 0
            archive_file = fullfile(save_dir, [type '_archive.mat']);
            fprintf('Saving %s (bootstrap archive)\n', archive_file);
            save(archive_file);
        end

        % ------------------------------------------------------------------
        % Store sigma2_epsilon for Fortran export
        % ------------------------------------------------------------------
        % Map 12 cohort bins -> 15 Fortran time periods:
        %   Periods 1-5  (1935-1959): sigma2_epsilon(2) repeated (bin 1 dropped)
        %   Periods 6-15 (1960-2009): sigma2_epsilon(3:12)
        sig_col = sigma2_epsilon_point(:);  % ensure column vector
        sigma2eps_fortran(:, itype) = [ ...
            repmat(sig_col(first_export_bin), n_pad, 1); ...
            sig_col(first_export_bin+1:end) ];

    end  % type loop

    % ======================================================================
    %  EXPORT SIGMA2EPS TXT (both types combined)
    % ======================================================================
    % Format: 30 lines. Lines 1-15 = H (college), lines 16-30 = L (no college).
    % This matches the Fortran read order: do m = 1, bigM (m=1 is H, m=2 is L).

    output_file = fullfile(save_dir, ['_data_sigma2eps_' variant '_' measure '.txt']);
    fprintf('\nWriting %s\n', output_file);

    fid = fopen(output_file, 'w');
    for itype = 1:length(types)
        for i = 1:n_fortran_sigma2eps
            fprintf(fid, '%.17g\n', sigma2eps_fortran(i, itype));
        end
    end
    fclose(fid);

    % ======================================================================
    %  COPY TO FORTRAN DATA DIRECTORY
    % ======================================================================
    fortran_dir = '../../fortran_code/Data';
    omega_file  = fullfile(save_dir, ['_data_omega_' variant '_' measure '.txt']);
    sigma_file  = output_file;

    if exist(fortran_dir, 'dir')
        copyfile(omega_file, fortran_dir);
        copyfile(sigma_file, fortran_dir);
        fprintf('Copied to %s\n', fortran_dir);
    else
        fprintf('WARNING: %s not found, skipping copy\n', fortran_dir);
    end

    fprintf('Done with %s.\n', variant);

end  % variant loop

fprintf('\n=== All variants complete ===\n');
for ivar = 1:length(variants)
    fprintf('  output/%s/_data_sigma2eps_%s_%s.txt\n', ...
        variants{ivar}, variants{ivar}, measure);
end
fprintf('Fortran inputs in: ../../fortran_code/Data/\n');
