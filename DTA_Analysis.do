if "`c(hostname)'" == "mphill-surface4" {
global overleaf_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\M&A Debt\Tables"
global fig_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\M&A Debt\Figures"
	
}

global overleaf_dir "/Users/zrsong/Dropbox (MIT)/Apps/Overleaf/M&A Debt/Tables"
global fig_dir "/Users/zrsong/Dropbox (MIT)/Apps/Overleaf/M&A Debt/Figures"

* Check if the directory exists, if not create it
cap mkdir "$overleaf_dir"


/***********
	DTA Analysis
	***********/
use "../3. Data/Processed/dta_analysis.dta", clear

sicff sic, ind(48)

* list of controls in regression 
gen log_at = log(at)

gen cash_flows_by_at = oancf/at
gen ppent_by_at = ppent/at
gen debt_by_at = debt/at
gen cash_by_at = che/at

gen post = 1 if fyear >= 2018
replace post = 0 if post == .
gen treated = excess_interest_30 
gen treated_loss = excess_interest_loss

gen treated_post = treated * post 
gen treated_loss_post = treated_loss * post

*** 2x2 Treatment Bins

gen treated_one = 1 if treated == 1 & treated_loss == 0
replace treated_one = 0 if treated_one == .
gen treated_one_post = treated_one * post

gen treated_two = 1 if treated == 0 & treated_loss == 1
replace treated_two = 0 if treated_two == .
gen treated_two_post = treated_two * post
 
gen treated_three = 1 if treated == 1 & treated_loss == 1
replace treated_three = 0 if treated_three == .
gen treated_three_post = treated_three * post

label variable treated "Excess Interest (30\% rule)"
label variable post "Post"
label variable treated_post "Excess Interest (30\% rule) x Post"
label variable treated_loss "Excess Interest (Loss rule)"
label variable treated_loss_post "Excess Interest (Loss rule) x Post"

label variable treated_one "Excess Interest (30\% rule only)"
label variable treated_two "Excess Interest (Loss rule only)"
label variable treated_three "Excess Interest (30\% and Loss rule)"
label variable treated_one_post "Excess Interest (30\% rule only) x Post"
label variable treated_two_post "Excess Interest (Loss rule only) x Post"
label variable treated_three_post "Excess Interest (30\% and Loss rule) x Post"

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local treat_vars "treated_one treated_one_post treated_two treated_two_post treated_three treated_three_post"

*** regressions of dta/asset on treated

reghdfe DTA_byat `treat_vars', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1

reghdfe DTA_byat `treat_vars' `controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m2

reghdfe DTA_byat `treat_vars', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m3

reghdfe DTA_byat `treat_vars' `controls', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m4

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 using "$overleaf_dir/dta_did_both_rule.tex", replace ///
nodepvars nomti nonum collabels(none) label b(5) se(5) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(`treat_vars')
est clear

*********** Binscatters ***********
local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
* binscatters
binscatter DTA fyear, by(treated_three) controls(`controls' i.ff_48) legend(label(1 "Control (Loss rule)") label(2 "Treated (30\% and Loss rule)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("DTA") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_dta_treated_loss.png") replace
* binscatters
binscatter DTA_byat fyear, by(treated_three) controls(`controls' i.ff_48) legend(label(1 "Control (Loss rule)") label(2 "Treated (30\% and Loss rule)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("DTA by Total Assets") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_dta_byat_treated_loss.png") replace

* binscatters
binscatter delta_DTA fyear, by(treated_three) controls(`controls' i.ff_48) legend(label(1 "Control (Loss rule)") label(2 "Treated (30\% and Loss rule)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("Delta DTA") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_delta_dta_treated_loss.png") replace
* binscatters
binscatter delta_DTA_byat fyear, by(treated_three) controls(`controls' i.ff_48) legend(label(1 "Control (Loss rule)") label(2 "Treated (30\% and Loss rule)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("Delta DTA by Total Assets") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_delta_dta_byat_treated_loss.png") replace


/***********
	MTR Analysis
	***********/
use "../3. Data/Processed/mtr8022.dta", clear
