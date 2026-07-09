  % this script creates cohort/time-specific variances 
  % need to adjust it handle matrices

 
   % add cohort aggregation - this is not really working unless we use trends!
    c_big = 1:p.C_eff;
    t_big = repelem(1:p.Nyears,opt.time_aggregation);
    
    c_vec = c_big;
    t_vec = t_big(1:p.Nyears);
    
   % this part checks if something is switched off
   % if yes, it sets it to 0

    rho                     = 1 / (1 + exp(guess(1,1)));
    
    if opt.varepsilon == -1
        sigma2_varepsilon = 0;
    else
        sigma2_varepsilon       = exp(guess(2,1));
    end
    
    if opt.eta == -1
        sigma2_eta = 0;
    else
        guess_eta               = (guess(2+opt.Nvarepsilon:2+opt.Nvarepsilon+opt.Neta-1,1));
    end
    
    if opt.gamma  == -1
        sigma2_gamma  = 0;
    else
        guess_gamma             = (guess(2+opt.Nvarepsilon+opt.Neta:2+opt.Nvarepsilon+opt.Neta+opt.Ngamma-1,1));
    end
   
    if opt.epsilon  == -2
        sigma2_epsilon  = 0;
    else
        guess_epsilon           = (guess(2+opt.Nvarepsilon+opt.Neta+opt.Ngamma:end,1));
    end
   

    % build objects of interest
    % this part uses "guess" to build variances

% ETA
    if opt.eta == -1
        sigma2_eta = 0;
        sigma2_eta = repmat(sigma2_eta,1,p.C_eff);
    elseif opt.eta == 0
        sigma2_eta = exp(guess_eta(1,1));
        sigma2_eta = repmat(sigma2_eta,1,p.C_eff);
    elseif opt.eta > 0
        if  opt.trend_eta == 0
        sigma2_eta = repelem(exp(guess_eta),1);
        else
        sigma2_eta = exp(polyval(flip(guess_eta),c_vec));
        end
    end
    
% GAMMA           
    
   if opt.gamma == -1
        sigma2_gamma = 0;
        sigma2_gamma = repmat(sigma2_gamma,1,p.C_eff);
   elseif opt.gamma == 0
        sigma2_gamma = exp(guess_gamma(1,1));
        sigma2_gamma = repmat(sigma2_gamma,1,p.C_eff);
   elseif opt.gamma > 0  
        if opt.trend_gamma == 0
         sigma2_gamma = repelem(exp(guess_gamma),1);   
        else     
        sigma2_gamma = exp(polyval(flip(guess_gamma),c_vec));
        end
   end
   
        
% EPSILON

    if opt.epsilon == -2
        sigma2_epsilon = 0;
        sigma2_epsilon = repmat(sigma2_epsilon,1,p.C_eff);
        
    elseif opt.epsilon == -1
        sigma2_epsilon = exp(guess_epsilon(1,1));
        sigma2_epsilon = repmat(sigma2_epsilon,1,p.C_eff);
        
    elseif opt.epsilon == 0
        
         if opt.trend_epsilon > 0
         sigma2_epsilon  = exp(polyval(flip(guess_epsilon),c_vec));
         else
         sigma2_epsilon = repelem(exp(guess_epsilon),1);   
         end
        
    elseif opt.epsilon == 1
        
        if opt.trend_epsilon > 0
        sigma2_epsilon  = exp(polyval(flip(guess_epsilon),t_vec));
        else
        sigma2_epsilon = repelem(exp(guess_epsilon),opt.time_aggregation);
        end
    end    