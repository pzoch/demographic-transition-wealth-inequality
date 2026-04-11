%%  income process estimation
clear all

% income process: 
% zeta(c,t,i) = rho * zeta(c,t-1,i) + epsilon(c,t,i)  
% eta(c,t,i) = gamma(c,i) +  zeta(c,t,i) + varepsilon(c,t,i) 
% 
% epsilon(c,t,i)     ~ N(0,sigma2_epsilon(c)) OR N(0,sigma2_epsilon(t))
% varepsilon(c,t,i)  ~ N(0,sigma2_varepsilon)
% gamma(c,i)         ~ N(0,sigma2_gamma(c))
% zeta(c,c-1,i)      ~ N(0,sigma2_zeta(c))

% to run the basic estimation specify
% opt.epsilon         = -1
% opt.eta             = -1
% opt.gamma           = -1
% opt.varepsilon      = -1

% this will give you labor income that is JUST an AR(1) process, no fixed
% effects, no transitory component.

% alternatively you can set opt.varepsilon      = 1
% and treat transitory component as measurement error

% I have NOT coded NO dispersion in the first period of life


    % aggregation: how many cohorts/periods have the same parameters?
     opt.cohort_aggregation  = 5; % how many cohorts have the same cohort specific parameter?
     opt.time_aggregation    = 1; % how many periods have the same time specific parameter?
    
     p.C = 60;  % number of cohorts beginning from the one that is born in p.first_cohort
     p.C_eff = p.C / opt.cohort_aggregation; % number of cohorts in "model" periods
     p.T = 45;  % number of years for each cohort
     %data_dir = 'C:/Users/HP/Dropbox/EMERYT/_Paper_16_inequality_longevity/calibration/income_process/';
     % data_dir = '../covariance_matrices_binned/output/mostdrop_hhslabinc/avghourlyhh/';
     
     data_dir = 'D:/EJ_Bootstrap/covariance_matrices_binned/';
     data_type = '';
     data_method = '';
    % prepare data
    % this gives us the matrix of empirical moments
    % maybe make this more flexible in the future
  
    % need to pick the first cohort
    p.first_cohort  = 1926; % has to be between 1923-1992, actually smaller, because nonidentification may arise
    p.data_start    = 1970; % first year in the data
    p.data_end      = 2017; % last year in the data
    
    p.age_start     = 20; 
    p.age_end       = p.age_start + p.T; % notice that p.T is how many years per cohort (at most), not how many years 
    p.Nyears        = p.data_end - p.data_start + 1; 
    % need to do some consistency checks 
    
    
        % empirical moments were generated in stata as txt files
        % these files are names "cohortXXXX" where XXXX denotes the year of
        % birth of cohort
        year = p.first_cohort:p.first_cohort - 1 + p.C;
        type = 'H'
        
        for c = 1:p.C_eff
            filename = strcat(data_dir,data_method,type,'_',data_type,'cohort',string(year((c-1)*5+1)),'.txt')
            loader % loads txt file
            cov_mat(:,:,c) =  cell2mat(raw);
            
            filename = strcat(data_dir,'Nobs_',data_method,type,'_',data_type,'cohort',string(year((c-1)*5+1)),'.txt')
            loader % loads txt file
            Nobs_mat(:,:,c) =  cell2mat(raw);
            
        end

% select relevant memebers of cov_mat and Nobs_mat
cov_mat = cov_mat(1:p.T,1:p.T,1:p.C_eff);
Nobs_mat = Nobs_mat(1:p.T,1:p.T,1:p.C_eff);


% specify options
    % time or cohort specific variances of innovations?
    opt.epsilon         = 0; % variance set to 0 = -2, not_specific = -1, cohort = 0, time = 1;
    
    % inherited eta dispersion?
    opt.eta             = -1;   % cohort specific inherited eta dispersion = 1, no cohort specific = 0, no eta dispersion at all = -1;
    
    % fixed effects?
    opt.gamma           = -1; % cohort specific fixed effects = 1, no cohort specific fixed effects = 0, no fixed effect at all = -1;
    
    % varepsilon?
    opt.varepsilon      = -1; % transitory shock = 1, no transitory shock = -1;
    
    
    % trends or fixed effects?
    opt.trend_epsilon    = 0  ;    % FE = 0, linear trend = 1, quadratic = 2, quartic = 3;
    opt.trend_eta        = 0;    % FE = 0, linear trend = 1, quadratic = 2, quartic = 3;
    opt.trend_gamma      = 0;    % FE = 0, linear trend = 1, quadratic = 2, quartic = 3;
    
    
    % do we use global search to find the minimum?
    opt.global_search      =    0;     % no = 0, yes = 1;
   
    opt.W                   = 0;    % identity matrix = 0, identity matrix multiplied by n^(-1/2) (as in Kaplan 2012) = 1;
    opt.bootstrap           = 1;    % parametric bootstrap = 1, no bootstrap (no standard errors reported) = 0
    opt.bootstrap_rep       = 1000; % number of repetitions in bootstrap
   

    if opt.W == 0 
        W  = Nobs_mat ./ Nobs_mat ;
    elseif opt.W == 1
        W  = Nobs_mat .^ (-1/2);
    end



%% preparing guesses
    guess = [];
% prepare guesses
% initial dispersion
          if opt.eta == -1
           guess_eta = [];
           opt.Neta = 0;  
           
          elseif opt.eta == 1
            if opt.trend_eta == 0
                guess_eta = log(ones(p.C_eff,1));
                opt.Neta = p.C_eff;
            elseif opt.trend_eta == 1
                guess_eta = zeros(2,1);
                opt.Neta = 2;
            elseif opt.trend_eta == 2
                guess_eta = zeros(3,1);
                opt.Neta = 3;
            elseif opt.trend_eta == 3
                guess_eta = zeros(4,1);
                opt.Neta = 4;
            end
            
          elseif opt.eta == 0
            guess_eta = log(1);
            opt.Neta = 1;
          end

% fixed effects
        if opt.gamma == -1
               guess_gamma = [];
               opt.Ngamma = 0; 
           
        elseif opt.gamma == 1
            if opt.trend_gamma == 0
                guess_gamma = log(ones(p.C_eff,1));
                opt.Ngamma = p.C_eff;
            elseif opt.trend_gamma == 1
                guess_gamma = zeros(2,1);
                opt.Ngamma = 2;
            elseif opt.trend_gamma == 2
                guess_gamma = zeros(3,1);
                opt.Ngamma = 3;
            elseif opt.trend_gamma == 3
                guess_gamma = zeros(4,1);
                opt.Ngamma = 4;
            end
        elseif opt.gamma == 0 
            guess_gamma = log(1);
            opt.Ngamma = 1;
        end    
            
        

% variances of shocks       

        if opt.epsilon == -2
           guess_epsilon = [];
           opt.Nepsilon = 0;  
           
        elseif opt.epsilon == -1
           guess_epsilon = log(.01);
           opt.Nepsilon = 1;
           
        elseif opt.epsilon == 0
            
            if opt.trend_epsilon == 0
                guess_epsilon = log(ones(p.C_eff,1));
                opt.Nepsilon = ceil(p.C_eff);
            elseif opt.trend_epsilon == 1
                guess_epsilon = zeros(2,1);
                opt.Nepsilon = 2;
            elseif opt.trend_epsilon == 2
                guess_epsilon = zeros(3,1);
                opt.Nepsilon = 3;
            elseif opt.trend_epsilon == 3
                guess_epsilon = zeros(4,1);
                opt.Nepsilon = 4;
            end
            
        elseif opt.epsilon == 1
            
            if opt.trend_epsilon == 0
                guess_epsilon = log(ones(ceil(p.Nyears/opt.time_aggregation),1));
                opt.Nepsilon = ceil(p.Nyears/opt.time_aggregation);
            elseif opt.trend_epsilon == 1
                guess_epsilon = zeros(2,1);
                opt.Nepsilon = 2;
            elseif opt.trend_epsilon == 2
                guess_epsilon = zeros(3,1);
                opt.Nepsilon = 3;
            elseif opt.trend_epsilon == 3
                guess_epsilon = zeros(4,1);
                opt.Nepsilon = 4;
            end
            
        end    

% rho and varepsilon

        guess_rho = 0.99;
        
        if opt.varepsilon == 1
            guess_varepsilon = log(.01);
            opt.Nvarepsilon = 1;
        else
            guess_varepsilon =[];
            opt.Nvarepsilon = 0;
        end
        

% build vector of guesses
        guess = [ guess_rho;
            guess_varepsilon;
            guess_eta;
            guess_gamma;
            guess_epsilon];

    opt.Nguess = length(guess);



%% estimation

% estimate
    if opt.epsilon == 0
    [guess,value] = lsqnonlin(@(x) objective_cohort_binned(x,cov_mat,p,opt,W),guess);
    elseif opt.epsilon == 1
        
    [guess,value] = lsqnonlin(@(x) objective_time(x,cov_mat,p,opt,W),guess);
    else
    [guess,value] = lsqnonlin(@(x) objective_cohort_binned(x,cov_mat,p,opt,W),guess);
    end

    %problem = createOptimProblem('lsqnonlin','objective',@(x) objective_cohort(x,cov_mat,p,opt,W),'x0',guess)

    %[aa,bb]      = run(ms,problem,15);

    % this part unpacks solution and transforms it to get parameters of
    % interest

% unpack parameters of interest
    create_parameters_binned;

         rho_point         = rho;
         sigma2_gamma_point = sigma2_gamma;
         sigma2_eta_point   = sigma2_eta;
         sigma2_varepsilon_point = sigma2_varepsilon;
         sigma2_epsilon_point = sigma2_epsilon;
    
% save results to reuse later
    guess_initial = guess;
%DO NOT USE IT YET


if opt.bootstrap == 1
    data_dir = data_dir
    save_dir = data_dir;   
    % prepare data
    % this gives us the matrix of empirical moments
    % maybe make this more flexible in the future
    clear cov_mat Nobs_mat
    
     filename = strcat(data_dir,data_method,type,'_',data_type,'cohort',string(year((c-1)*5+1)),'.txt')
    
    for k = 10:opt.bootstrap_rep    
        for c = 1:p.C_eff
            filename = strcat(data_dir,data_method,type,'_',data_type,'cohort',string(year((c-1)*5+1)),'_rep',string(k),'.txt')
            loader % loads txt file
            cov_mat(:,:,c) =  cell2mat(raw);
            
            filename = strcat(data_dir,'Nobs_',data_method,type,'_',data_type,'cohort',string(year((c-1)*5+1)),'_rep',string(k),'.txt')
            loader % loads txt file
            Nobs_mat(:,:,c) =  cell2mat(raw);
            
        end
        try
        [guess,value] = lsqnonlin(@(x) objective_cohort_binned(x,cov_mat,p,opt,W),guess_initial);
        create_parameters_binned;
         rho_bs(:,k)          = rho;
         sigma2_gamma_bs(:,k) = sigma2_gamma;
         sigma2_eta_bs(:,k)   = sigma2_eta;
         sigma2_varepsilon_bs(:,k) = sigma2_varepsilon;
         sigma2_epsilon_bs(:,k) = sigma2_epsilon;
        catch
           fprintf('problem with the optimizer'); 
        end
      
     end
end   

 
     save_dir = './output/busno_drop_hhslabinc/avghourlyhh/';

filename = strcat(save_dir,data_method,type,data_type,'.mat');
save(filename)

sigma2_epsilon_bs(sigma2_epsilon_bs==0) = NaN
prc095 = prctile(sigma2_epsilon_bs',95)
prc050 = prctile(sigma2_epsilon_bs',50)
prc005 = prctile(sigma2_epsilon_bs',5)

