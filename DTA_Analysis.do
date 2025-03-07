use "../3. Data/Processed/dta_analysis.dta", clear

if "`c(hostname)'" == "mphill-surface4" {
global overleaf_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\Tax Incidence and Loan Contract Negotiation\Tables"
global fig_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\Tax Incidence and Loan Contract Negotiation\Figures"
}

global overleaf_dir "/Users/zrsong/Dropbox (MIT)/Apps/Overleaf/Tax Incidence and Loan Contract Negotiation/Tables"
global fig_dir "/Users/zrsong/Dropbox (MIT)/Apps/Overleaf/Tax Incidence and Loan Contract Negotiation/Figures"

* Check if the directory exists, if not create it
cap mkdir "$overleaf_dir"

sicff sic, ind(48)

* list of controls in regression 
gen log_at = log(at)

gen cash_flows_by_at = oancf/at
gen ppent_by_at = ppent/at
gen debt_by_at = debt/at
gen cash_by_at = che/at

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"

gen post = 1 if fyear >= 2018
replace post = 0 if post == .
gen treated = excess_interest_30 
gen treated_loss = excess_interest_loss
gen treated_post = treated * post 
gen treated_loss_post = treated_loss * post

*** treatment


label variable treated "Excess Interest (30\% Rule)"
label variable post "Post"
label variable treated_post "Excess Interest (30\% Rule) x Post"
label variable treated_loss "Excess Interest (Loss)"
label variable treated_loss_post "Excess Interest (Loss) x Post"


*** regressions of dta/asset on treated
reghdfe DTA_byat treated treated_post treated_loss treated_loss_post `controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1

reghdfe DTA_byat treated treated_post treated_loss treated_loss_post `controls', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m2

* save the results (esttab) using overleaf_dir
esttab m1 m2 using "$overleaf_dir/dta_did_both_rule.tex", replace ///
nodepvars nomti nonum collabels(none) label b(5) se(5) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear

*********** Binscatters ***********
local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
* binscatters
binscatter DTA fyear, by(treated_loss) controls(`controls' i.ff_48) legend(label(1 "Control (Loss)") label(2 "Treated (Loss)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("DTA") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_dta_treated_loss.png") replace
* binscatters
binscatter DTA_byat fyear, by(treated_loss) controls(`controls' i.ff_48) legend(label(1 "Control (Loss)") label(2 "Treated (Loss)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("DTA by Total Assets") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_dta_byat_treated_loss.png") replace

* binscatters
binscatter delta_DTA fyear, by(treated_loss) controls(`controls' i.ff_48) legend(label(1 "Control (Loss)") label(2 "Treated (Loss)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("Delta DTA") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_delta_dta_treated_loss.png") replace
* binscatters
binscatter delta_DTA_byat fyear, by(treated_loss) controls(`controls' i.ff_48) legend(label(1 "Control (Loss)") label(2 "Treated (Loss)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("Delta DTA by Total Assets") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_delta_dta_byat_treated_loss.png") replace
