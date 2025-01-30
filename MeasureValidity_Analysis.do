use "../3. Data/Processed/ds_gvkey_treatment_assignment.dta", clear

if "`c(hostname)'" == "mphill-surface4" {
global overleaf_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\M&A Debt\Tables"
global fig_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\M&A Debt\Figures"
	
}

global overleaf_dir "/Users/zrsong/Dropbox (MIT)/Apps/Overleaf/M&A Debt/Tables"
global fig_dir "/Users/zrsong/Dropbox (MIT)/Apps/Overleaf/M&A Debt/Figures"

* Check if the directory exists, if not create it
cap mkdir "$overleaf_dir"

sicff sic, ind(48)

* list of controls in regression 
gen log_at = log(at)
replace next_year_excess_interest_total = next_year_excess_interest_total * 100

gen cash_flows_by_at = oancf/at
gen ppent_by_at = ppent/at
gen debt_by_at = debt/at
gen cash_by_at = che/at

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"

gen post = 1 if fyear >= 2018
replace post = 0 if post == .

drop treated
egen treated_either = rowmax(excess_interest_30 excess_interest_loss)
gen treated_either_post = treated_either * post
egen treated_both = rowmin(excess_interest_30 excess_interest_loss)
gen treated_both_post = treated_both * post

gen treated = treated1 
egen treated_loss = rowmax(treated2 treated1)
gen treated_post = treated * post 
gen treated_loss_post = treated_loss * post

label variable treated "Treated (30\% rule)"
label variable post "Post"
label variable treated_post "Treated (30\% rule) x Post"
label variable treated_loss "Treated (Loss)"
label variable treated_loss_post "Treated (Loss) x Post"


*** regressions of dta/asset on treated
reghdfe next_year_excess_interest_total treated treated_post treated_loss treated_loss_post `controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1

reghdfe next_year_excess_interest_total treated treated_post treated_loss treated_loss_post `controls', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m2

* save the results (esttab) using overleaf_dir
esttab m1 m2 using "$overleaf_dir/dta_did_both_rule.tex", replace ///
nodepvars nomti nonum collabels(none) label b(5) se(5) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear

