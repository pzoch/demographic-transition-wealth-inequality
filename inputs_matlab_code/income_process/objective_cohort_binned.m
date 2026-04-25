function [residual,stacked_zeta] = objective_cohort_binned(guess,cov_mat,p,opt,W)

% this is used when we have cohort-specific variances

% variable "t" denotes model age 
% variable "c" is the number of cohort
% variable "t_calendar" is a calendar year
% variable "k" seems redundant - it seems to be the same as t



% if statement will slow it down, but let's try anyway...
% correct for the changed structure of the data...

% unload guesses, this is the order of things in the vector
%     guess = [ guess_rho;
%         guess_varepsilon;
%         guess_eta;
%         guess_gamma;
%         guess_epsilon];

create_parameters_binned;

% MAKE CALENDAR AGE vs MODEL AGE DISTINCTION NEATER
% so far it is very confusing!!!


    stacked = [];
    stacked_zeta = [];
i = 1;
for c = 1:p.C_eff;
    
    c_birth = p.first_cohort + 5*c - 5; % this returns the calendar year of the cohort's c birth

    
     
    for t = 1:45 % this is a loop over all available ages of cohort c
        % t means model age!
        
        % some redundancy - t_init and k
        for s = 0:min(45-t,45) % it is a loop, we go as much forward as possible, the upper bound is imposed either by data selection or data limitations
        
        k = (t-1); % k is years since reaching p.age_start
        
        % create covariances of stochastic components
        
        % modify the one below to allow for time-specific sigma2_epsilon
        var_eta(c) = rho^2 * (k + 1) * sigma2_eta(c) + (1 - rho ^ (2 * (k + 1)))/(1 - rho^2) * sigma2_epsilon(c);
        
            if s == 0;
                % this line gives variance of earnings of cohort c when it
                % is of age t
                zeta(t,t,c) = sigma2_gamma(c) + sigma2_varepsilon + var_eta(c);    
        
            elseif s > 0
                
                % this line gives covariance of earnings of cohort c in
                % periods (t, t+s)
                zeta(t,t+s,c) = sigma2_gamma(c) + rho ^ s * var_eta(c); 
                
            else
                zeta(t,t+s,c) = NaN;
            end
            
            
            % create residuals
            residual_mat(c,t,t+s) = (zeta(t,t+s,c) - cov_mat(t,t+s,c)) * sqrt(W(t,t+s,c));
            stacked_zeta = [stacked_zeta;zeta(t,t+s,c)];
            stacked = [stacked;residual_mat(c,t,t+s)];
        end
        i = i + 1;
    end
end


residual = stacked(~isnan(stacked));      

end

