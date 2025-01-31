*log using Dealscan_Analysis.log, replace

use "../3. Data/Processed/tranche_level_ds_compa.dta", clear
drop treated*

merge m:1 gvkey fyear using "../3. Data/Processed/ds_gvkey_treatment_assignment.dta"
keep if _merge == 3
drop _merge
gen treated_post = treated * post

gen treated1_post = treated1 * post
gen treated2_post = treated2 * post

if "`c(hostname)'" == "mphill-surface4" {
global overleaf_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\Tax Incidence and Loan Contract Negotiations\Tables"
global fig_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\Tax Incidence and Loan Contract Negotiations\Figures"
	
}

global overleaf_dir "/Users/zrsong/MIT Dropbox/Zirui Song/Apps/Overleaf/Tax Incidence and Loan Contract Negotiations/Tables"
global fig_dir "/Users/zrsong/MIT Dropbox/Zirui Song/Apps/Overleaf/Tax Incidence and Loan Contract Negotiations/Figures"

keep if year >= 2014

* Check if the directory exists, if not create it
cap mkdir "$overleaf_dir"

* gen logged bps
gen log_margin_bps = log(margin_bps)

* list of controls in regression 
gen log_at = log(at)
gen log_deal_amount_converted = log(deal_amount_converted)

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

* generate interaction between controls and post
foreach var in `controls' {
    gen `var'_post = `var' * post
	gen `var'_treated = `var' * treated
}

local controls_post "log_at_post cash_flows_by_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post sales_growth_post dividend_payer_post nol_post ret_vol_post"
local controls_treated "log_at_treated cash_flows_by_at_treated market_to_book_treated ppent_by_at_treated debt_by_at_treated cash_by_at_treated sales_growth_treated dividend_payer_treated nol_treated ret_vol_treated"

* winsorize at 1% and 99%
foreach var in margin_bps log_margin_bps `controls' `deal_controls' `controls_post' `controls_treated' `controls_treated_loss' {
    winsor2 `var', cuts(1 99) replace
}

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

* label controls and treated, post, and treated_post
label variable log_at "Log Total Assets"
label variable cash_flows_by_at "Cash Flows / Assets"
label variable market_to_book "Market to Book Ratio"
label variable ppent_by_at "PP\&E / Assets"
label variable debt_by_at "Debt / Assets"
label variable cash_by_at "Cash / Assets"
label variable sales_growth "Sales Growth"
label variable dividend_payer "Dividend Payer"
label variable z_score "Z-Score"
label variable nol "Net Operating Loss"
label variable ret_buy_and_hold "Buy and Hold Return"
label variable ret_vol "Return Volatility"

label variable leveraged "Leveraged"
label variable maturity "Maturity"
label variable log_deal_amount_converted "Log Loan Amount"
label variable secured_dummy "Secured"
label variable tranche_type_dummy "Tranche Type"
label variable tranche_o_a_dummy "Origination"
label variable sponsor_dummy "Sponsored"

label variable treated "Treated"
label variable post "Post"
label variable treated_post "Treated x Post"

save "../3. Data/Processed/tranche_level_ds_compa_wlabel1.dta", replace

/***********
	Bring in SP Ratings
	***********/
	
	use "../3. Data/Processed/tranche_level_ds_compa_wlabel1.dta", clear

rename currentratingsymbol sp_rating
replace sp_rating = subinstr(sp_rating, " prelim", "", .) 

gen sp_rating_num = .
replace sp_rating_num = 21 if sp_rating == "AAA"
* replace sp_rating_num = 21 if sp_rating == "AA+" (only 1 obs)
replace sp_rating_num = 20 if sp_rating == "AA" | sp_rating == "ilAA" | sp_rating == "AA+"
replace sp_rating_num = 19 if sp_rating == "AA-"
replace sp_rating_num = 18 if sp_rating == "A+"
replace sp_rating_num = 17 if sp_rating == "A"
replace sp_rating_num = 16 if sp_rating == "A-" | sp_rating == "A-1+" | sp_rating == "A-2" | sp_rating == "A-3"
replace sp_rating_num = 15 if sp_rating == "BBB+"
replace sp_rating_num = 14 if sp_rating == "BBB"
replace sp_rating_num = 13 if sp_rating == "BBB-"
replace sp_rating_num = 12 if sp_rating == "BB+"
replace sp_rating_num = 11 if sp_rating == "BB"
replace sp_rating_num = 10 if sp_rating == "BB-"
replace sp_rating_num = 9  if sp_rating == "B+"
replace sp_rating_num = 8  if sp_rating == "B"
replace sp_rating_num = 7  if sp_rating == "B-"
replace sp_rating_num = 6  if sp_rating == "CCC+"
replace sp_rating_num = 5  if sp_rating == "CCC"
replace sp_rating_num = 4  if sp_rating == "CCC-"
replace sp_rating_num = 3  if sp_rating == "CC"
replace sp_rating_num = 2  if sp_rating == "C"
replace sp_rating_num = 1  if sp_rating == "D"
replace sp_rating_num = 0 if sp_rating_num == .

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

gen not_rated = 1 if sp_rating_num == 0
replace not_rated = 0 if not_rated == .

label var sp_rating_num "S\&P Rating"
label var not_rated "Not Rated"

* LHS Sample Composition Tests
reghdfe not_rated treated1 treated1_post treated2 treated2_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m2
preserve 
	drop if sp_rating_num == 0
	reghdfe sp_rating_num treated1 treated1_post treated2 treated2_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
	estimates store m1
restore

save "../3. Data/Processed/tranche_level_ds_compa_wlabel1.dta", replace

/***********
	Exposure Regression 
	***********/
	
gen excess_interest_30_post = excess_interest_30 * post
gen excess_interest_loss_post = excess_interest_loss * post
label variable excess_interest_30 "Excess Interest (30\% Rule)"
label variable excess_interest_loss "Excess Interest (Loss)"
label variable excess_interest_30_post "Excess Interest (30\% Rule) X Post"
label variable excess_interest_loss_post "Excess Interest (Loss) X Post"

local treated_vars "excess_interest_30 excess_interest_loss"
	
reghdfe next_year_excess_interest_total	`treated_vars' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe next_year_excess_interest_total `treated_vars' `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
	
reghdfe next_year_excess_interest_total `treated_vars' `controls' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
estimates store m3
reghdfe next_year_excess_interest_total `treated_vars' `controls' `controls_post' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
estimates store m4

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 using "$overleaf_dir/next_year_excess_interest_total_validation.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(`treated_vars' `controls' `deal_controls')
est clear

*** Margin on net_year_excess_interest_total 

use "../3. Data/Processed/tranche_level_ds_compa_wlabel1.dta", clear

replace interest_expense_total_excess = interest_expense_total_excess/xint

corr interest_expense_total_excess next_year_excess_interest_total

*drop if year == 2020 | year == 2021

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

gen next_year_excess_post = next_year_excess_interest_total * post
gen interest_expense_excess_post = interest_expense_total_excess * post

reghdfe margin_bps next_year_excess_interest_total next_year_excess_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)

reghdfe margin_bps interest_expense_total_excess interest_expense_excess_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)


preserve 
	keep if post == 0 
	reg margin_bps next_year_excess_interest_total
	reghdfe margin_bps next_year_excess_interest_total `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
restore

preserve 
	keep if post == 1
	reg margin_bps next_year_excess_interest_total
	reghdfe margin_bps next_year_excess_interest_total `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
restore

* median/tercile split
*keep if next_year_excess_interest_total > 0
bysort year ff_48: egen median_excess = median(next_year_excess_interest_total)
bysort year ff_48: egen p33_excess = pctile(next_year_excess_interest_total), p(33)
bysort year ff_48: egen p66_excess = pctile(next_year_excess_interest_total), p(66)
*gen next_year_excess_treat = 1 if next_year_excess_interest_total > median_excess
gen next_year_excess_treat = 1 if next_year_excess_interest_total == 1
replace next_year_excess_treat = 0 if next_year_excess_treat == .

gen next_year_excess_treat_post = next_year_excess_treat * post

reghdfe margin_bps next_year_excess_treat next_year_excess_treat_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)

*** DID regressions (30% and Loss: MAIN RESULT TABLE 1) ***
/*
use "../3. Data/Processed/tranche_level_ds_compa_wlabel1.dta", clear

reghdfe margin_bps treated1 treated1_post treated2 treated2_post `controls' `deal_controls' sp_rating_num, absorb(year ff_48) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps treated1 treated1_post treated2 treated2_post `controls' `controls_post' `deal_controls' sp_rating_num, absorb(year ff_48) vce(cluster gvkey)
estimates store m2

reghdfe margin_bps treated1 treated1_post treated2 treated2_post `controls' `deal_controls' sp_rating_num, absorb(year gvkey) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps treated1 treated1_post treated2 treated2_post `controls' `controls_post' `deal_controls' sp_rating_num, absorb(year gvkey) vce(cluster gvkey)
estimates store m2 */
