set scheme burd
//importing data on shares of wealth held by welth percetnile groups from Federal Reserve
/*import delimited "https://www.federalreserve.gov/releases/z1/dataviz/download/dfa-networth-shares.csv", clear
save r_sd/r_sd.dta, replace */

use r_sd/r_sd.dta, clear

generate year = substr(date,1,4)
destring year, replace
capture drop share
rename networth share
keep date year category share
collapse (mean) share, by(year category)
replace share = share/100

reshape wide share , i(year)  j(category) string
replace shareRemainingTop1 = shareRemainingTop1 + shareTopPt1
drop shareTopPt1

reshape long 
egen t_mean = mean(share), by(category)

reshape wide t_mean share , i(year)  j(category) string

//data from HKS
gen SDbot50 = .023
gen SDnext40 = .081
gen SDremainingt9 = .094
gen SDtopPt1 = .119



gen total_meanSD = (t_meanBottom50*SDbot50)^2 + (t_meanNext40*SDnext40)^2 + (t_meanNext9*SDremainingt9)^2 + (t_meanRemainingTop1*SDtopPt1)^2
replace total_meanSD = sqrt(total_meanSD)

collapse (mean) total_meanSD
range r_bar 0.0 0.1 11
gen R_marcin = (1+r_bar)^(1/5)

sum total_meanSD
gen ei_sd = `r(mean)'
drop total_meanSD
gen var_ei = ei_sd^2
gen D_bar = (1+r_bar)/exp((1/2)*5*var_ei)
replace D_bar = D_bar^(1/5)
gen var_log_norm = D_bar^10*(exp(5*var_ei)-1)*exp(5*var_ei)


gen var_norm = R_marcin^8*(5*var_ei) +  R_marcin^6*(10*(var_ei^2)) + R_marcin^4*(10*var_ei^3) + R_marcin^2*(var_ei^4) + (var_ei)^5 

gen var_5_sigma = 5*var_ei

rename var_ei var_HKS 
line var_HKS var_log_norm var_norm var_5_sigma r_bar, sort

/*
gen yearly_meanSD = (shareBottom50*SDbot50)^2 + (shareNext40*SDnext40)^2 + (shareNext9*SDremainingt9)^2 + (shareRemainingTop1*SDtopPt1)^2
replace yearly_meanSD = sqrt(yearly_meanSD)


tset year
tsline yearly_meanSD  total_meanSD
graph export comp_SD.png, replace
tsline shareBottom50 shareNext40 shareNext9 shareRemainingTop1
graph export comp_shares.png, replace

gen y_var_X = total_meanSD^2
gen five_y_var_X = y_var_X^5
gen five_y_sd_X = sqrt(five_y_var_X)
