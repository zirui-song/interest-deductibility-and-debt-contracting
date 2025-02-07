log using Dealscan_Analysis.log, replace

use "../3. Data/Processed/tranche_level_ds_compa.dta", clear

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
gen log_at = log(at)
gen log_deal_amount_converted = log(deal_amount_converted)

*** treatment
/*replace treated = 0 if treated_loss == 1
replace treated_prev_3yr = 0 if treated_loss_prev_3yr == 1
replace treated_prev_5yr = 0 if treated_loss_prev_5yr == 1
replace treated_next_1yr = 0 if treated_loss_next_1yr == 1
replace treated_next_3yr = 0 if treated_loss_next_3yr == 1
replace treated_next_5yr = 0 if treated_loss_next_5yr == 1 */

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

* generate interaction between controls and post
foreach var in `controls' {
    gen `var'_post = `var' * post
	gen `var'_treated = `var' * treated
	gen `var'_treated_loss = `var' * treated_loss
}

local controls_post "log_at_post cash_flows_by_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post sales_growth_post dividend_payer_post nol_post ret_vol_post"
local controls_treated "log_at_treated cash_flows_by_at_treated market_to_book_treated ppent_by_at_treated debt_by_at_treated cash_by_at_treated sales_growth_treated dividend_payer_treated nol_treated ret_vol_treated"
local controls_treated_loss "log_at_treated_loss cash_flows_by_at_treated_loss market_to_book_treated_loss ppent_by_at_treated_loss debt_by_at_treated_loss cash_by_at_treated_loss sales_growth_treated_loss dividend_payer_treated_loss nol_treated_loss ret_vol_treated_loss"

* winsorize at 1% and 99%
foreach var in margin_bps log_margin_bps `controls' `deal_controls' `controls_post' `controls_treated' `controls_treated_loss' {
    winsor2 `var', cuts(1 99) replace
}

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

label variable treated "Excess Interest (30\% Rule)"
label variable post "Post"
label variable treated_post "Excess Interest (30\% Rule) x Post"
label variable treated_loss "Excess Interest (Loss)"
label variable treated_loss_post "Excess Interest (Loss) x Post"

label variable treated_prev_3yr "Excess Interest (30\% Rule, Previous 3 Years)"
label variable treated_prev_3yr_post "Excess Interest (30\% Rule, Previous 3 Years) x Post"
label variable treated_loss_prev_3yr "Excess Interest (Loss, Previous 3 Years)"
label variable treated_loss_prev_3yr_post "Excess Interest (Loss, Previous 3 Years) x Post"
label variable treated_prev_5yr "Excess Interest (30\% Rule, Previous 5 Years)"
label variable treated_prev_5yr_post "Excess Interest (30\% Rule, Previous 5 Years) x Post"
label variable treated_loss_prev_5yr "Excess Interest (Loss, Previous 5 Years)"
label variable treated_loss_prev_5yr_post "Excess Interest (Loss, Previous 5 Years) x Post"

save "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", replace

/***********
	Bring in SP Ratings
	***********/
	
	use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

capture program drop clean_rating
program define clean_rating
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
end

clean_rating

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local treat_vars "treated treated_post treated_loss treated_loss_post"	

gen not_rated = 1 if sp_rating_num == 0
replace not_rated = 0 if not_rated == .

label var sp_rating_num "S\&P Rating"
label var not_rated "Not Rated"

* LHS Sample Composition Tests
reghdfe not_rated `treat_vars' `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m2
preserve 
	drop if sp_rating_num == 0
	reghdfe sp_rating_num `treat_vars' `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
	estimates store m1
restore
* save the results (esttab) using overleaf_dir
esttab m1 m2 using "$overleaf_dir/sp_rating_robustness.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(`treat_vars' `controls' `deal_controls')
est clear

save "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", replace

*** DID regressions (30% and Loss: MAIN RESULT TABLE 1) ***

use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

gen treated_both = treated * treated_loss
gen treated_both_post = treated_both * post

gen treated_eo = 1 if treated == 1 | treated_next_1yr == 1
replace treated_eo = 0 if treated_eo == .
gen treated_loss_eo = 1 if treated_loss == 1 | treated_loss_next_1yr == 1
replace treated_loss_eo = 0 if treated_loss_eo == .

gen treated_eo_post = treated_eo * post
gen treated_loss_eo_post = treated_loss_eo * post

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post cash_flows_by_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post sales_growth_post dividend_payer_post nol_post ret_vol_post"

*** check results with no covariates
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1

reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 using "$overleaf_dir/margin_did_both_rule.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')
est clear

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"


*** robustness dropping 2020 and 2021 (COVID)
preserve
	drop if year == 2021 | year == 2020
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m1
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m2
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m3
	
	* save the results (esttab) using overleaf_dir
	esttab m1 m2 m3 using "$overleaf_dir/margin_did_both_rule_dropcovid.tex", replace ///
	nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
	star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')
	est clear
restore

/********* 
	DID regressions (30% and Loss: ROBUSTNESS RESULT TABLE 2 and Appendix)
	*********/
* Firm FE 
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
estimates store m2
* 3-year and 5-year look backs
preserve  
	/*drop treated treated_post treated_loss treated_loss_post
	rename (treated_prev_3yr treated_prev_3yr_post treated_loss_prev_3yr treated_loss_prev_3yr_post) (treated treated_post treated_loss treated_loss_post)
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m3
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m4*/
	
	drop treated treated_post treated_loss treated_loss_post
	rename (treated_prev_5yr treated_prev_5yr_post treated_loss_prev_5yr treated_loss_prev_5yr_post) (treated treated_post treated_loss treated_loss_post)
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m5
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m6
restore 

* save the results (esttab) using overleaf_dir
esttab m1 m2 m5 m6 using "$overleaf_dir/margin_did_both_rule_robustness.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear

****** Forward Looking Measures Table D4 

local treated_base "treated treated_post treated_loss treated_loss_post"
local treated_next_1yr "treated_next_1yr treated_next_1yr_post treated_loss_next_1yr treated_loss_next_1yr_post"
local treated_next_3yr "treated_next_3yr treated_next_3yr_post treated_loss_next_3yr treated_loss_next_3yr_post"
local treated_next_5yr "treated_next_5yr treated_next_5yr_post treated_loss_next_5yr treated_loss_next_5yr_post"
local treated_eo_all "treated_eo treated_eo_post treated_loss_eo treated_loss_eo_post"

preserve 
	drop `treated_base'
	rename (`treated_next_1yr') (`treated_base')
	reghdfe margin_bps `treated_base' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey) 
	estimates store m1
	reghdfe margin_bps `treated_base' `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)  
	estimates store m2

	/*
	drop `treated_base'
	rename (`treated_next_3yr') (`treated_base')
	reghdfe margin_bps `treated_base' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey) 
	estimates store m3
	reghdfe margin_bps `treated_base' `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)  
	estimates store m4
	*/
	
	drop `treated_base'
	rename (`treated_next_5yr') (`treated_base')
	reghdfe margin_bps `treated_base' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey) 
	estimates store m5
	reghdfe margin_bps `treated_base' `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)  
	estimates store m6
restore

* save the results (esttab) using overleaf_dir
esttab m1 m2 m5 m6 using "$overleaf_dir/margin_did_both_rule_robustness_forward.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear

****** Appendix Tabld D2

*** DID regressions (30% and Loss: Treat X Covariates) ***
*reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `controls_treated' `controls_treated_loss' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
*estimates store m1
*reghdfe log_margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `controls_treated' `controls_treated_loss' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
*estimates store m2

*** DID regressions (30% and Loss: ROBUSTNESS E-balancing) ***

use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

gen control = 0 
replace control = 1 if treated == 0 & treated_loss == 0

gen treated_one = 1 if treated == 1 & treated_loss == 0
replace treated_one = 0 if treated_one == .
gen treated_one_post = treated_one * post

gen treated_two = 1 if treated == 0 & treated_loss == 1
replace treated_two = 0 if treated_two == .
gen treated_two_post = treated_two * post
 
gen treated_three = 1 if treated == 1 & treated_loss == 1
replace treated_three = 0 if treated_three == .
gen treated_three_post = treated_three * post

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local treated_bi "treated_one treated_one_post treated_two treated_two_post treated_three treated_three_post"

reghdfe margin_bps `treated_bi' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)

****** most robustness

gen treated_all = 1 if treated == 1 | treated_loss == 1
replace treated_all = 0 if treated_all == .

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

ebalance treated_all `controls'

reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls' [pweight=_webal], absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls' `controls_post' [pweight=_webal], absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
*estimates store m4

* save the results (esttab) using overleaf_dir
esttab m3 using "$overleaf_dir/margin_did_both_rule_robustness_2.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear

*** Appendix Table: Log Margin results with prev_3yr and prev_5yr definitions
* Appendix Table D1: Logged Margin
reghdfe log_margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe log_margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
preserve
	/*drop treated treated_post treated_loss treated_loss_post
	rename (treated_prev_3yr treated_prev_3yr_post treated_loss_prev_3yr treated_loss_prev_3yr_post) (treated treated_post treated_loss treated_loss_post)
	reghdfe log_margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m3
	reghdfe log_margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m4 */
	
	drop treated treated_post treated_loss treated_loss_post
	rename (treated_prev_5yr treated_prev_5yr_post treated_loss_prev_5yr treated_loss_prev_5yr_post) (treated treated_post treated_loss treated_loss_post)
	reghdfe log_margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m5
	reghdfe log_margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m6
restore
* save the results (esttab) using overleaf_dir
esttab m1 m2 m5 m6 using "$overleaf_dir/log_margin_did_both_rule.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear

****** Firms that are in both periods

preserve
	use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

	bysort gvkey: egen max_post = max(post)
	bysort gvkey: egen min_post = min(post)
	keep if max_post != min_post

	local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
	local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
	local controls_post "log_at_post cash_flows_by_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post sales_growth_post dividend_payer_post nol_post ret_vol_post"

	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
	estimates store m1
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
	estimates store m2

	* save the results (esttab) using overleaf_dir
	esttab m1 m2 using "$overleaf_dir/margin_did_both_rule_balance_panel.tex", replace ///
	nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
	star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
	est clear
restore

/*********** 
	Regressions with Other Loan Terms 
	***********/

*** DID regressions (30% and Loss: Perf Pricing and Num Fin Cov) ***

reghdfe perf_pricing_dummy treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe num_fin_cov treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
*** DID regressions (covenant tightness)
reghdfe pviol treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3

*** DID regressions (30% and Loss: Loan Size and Maturity) ***

local deal_controls_2 "leveraged secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

reghdfe deal_amount_converted treated treated_post treated_loss treated_loss_post `controls' `deal_controls_2', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m4

reghdfe log_deal_amount_converted treated treated_post treated_loss treated_loss_post `controls' `deal_controls_2', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m5

reghdfe maturity treated treated_post treated_loss treated_loss_post `controls' `deal_controls_2', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m6

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 m5 m6 using "$overleaf_dir/other_terms_did_both_rule.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear

*********** Dynamic Regressions ***********
local dynamic_treated "treated_year_2014 treated_year_2015 treated_year_2016 treated_year_2018 treated_year_2019 treated_year_2020 treated_year_2021 treated_year_2022 treated_year_2023"
local dynamic_treated_loss "treated_loss_year_2014 treated_loss_year_2015 treated_loss_year_2016 treated_loss_year_2018 treated_loss_year_2019 treated_loss_year_2020 treated_loss_year_2021 treated_loss_year_2022 treated_loss_year_2023"

*** Both Rule ***
reghdfe margin_bps treated treated_loss `dynamic_treated' `dynamic_treated_loss' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_both_ff48.csv", replace mlab(none)

* drop 2020 and re run the regression
drop if year == 2020
reghdfe margin_bps treated treated_loss `dynamic_treated' `dynamic_treated_loss' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_both_ff48_no2020.csv", replace mlab(none)

*** Loss ***
reghdfe margin_bps treated_loss `dynamic_treated_loss' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_loss_ff48.csv", replace mlab(none)

* drop 2020 and re run the regression
drop if year == 2020
reghdfe margin_bps treated_loss `dynamic_treated_loss' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_loss_ff48_no2020.csv", replace mlab(none)

*** 30% Rule ***

reghdfe margin_bps treated `dynamic_treated' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_ff48.csv", replace mlab(none)

reghdfe margin_bps treated `dynamic_treated' `controls' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_gvkey.csv", replace mlab(none)

*********** Dynamic Regressions (num of financial covenants) ***********
reghdfe num_fin_cov treated `dynamic_treated' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/num_fin_cov_did_dynamic_ff48.csv", replace mlab(none)

reghdfe num_fin_cov treated `dynamic_treated' `controls' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/num_fin_cov_did_dynamic_gvkey.csv", replace mlab(none)

*********** Dynamic Regressions (perf_pricing_dummy) ***********
reghdfe perf_pricing_dummy treated `dynamic_treated' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/perf_pricing_dummy_did_dynamic_ff48.csv", replace mlab(none)

reghdfe perf_pricing_dummy treated `dynamic_treated' `controls' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/perf_pricing_dummy_did_dynamic_gvkey.csv", replace mlab(none)

*********** Dynamic Regressions (sweep_dummy) ***********
reghdfe sweep_dummy treated `dynamic_treated' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/sweep_dummy_did_dynamic_ff48.csv", replace mlab(none)

reghdfe sweep_dummy treated `dynamic_treated' `controls' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/sweep_dummy_did_dynamic_gvkey.csv", replace mlab(none)

*********** Binscatters ***********
* binscatters
binscatter margin_bps year, by(treated_loss) controls(`controls' `deal_controls' i.ff_48 i.sp_rating_num) legend(label(1 "Control (Loss)") label(2 "Treated (Loss)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("Interest Spread (Basis Points)") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_margin_bps_treated_loss.png") replace

binscatter log_margin_bps year, by(treated_loss) controls(`controls' `deal_controls' i.ff_48 i.sp_rating_num) legend(label(1 "Control (Loss)") label(2 "Treated (Loss)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("Log Interest Spread") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_log_margin_bps_treated_loss.png") replace

binscatter margin_bps year, by(treated) controls(`controls' `deal_controls' i.ff_48 i.sp_rating_num) legend(label(1 "Control (30% rule)") label(2 "Treated (30% rule)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("Interest Spread (Basis Points)") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_margin_bps_treated.png") replace

binscatter log_margin_bps year, by(treated) controls(`controls' `deal_controls' i.ff_48 i.sp_rating_num) legend(label(1 "Control (30% rule)") label(2 "Treated (30% rule)") position(1) ring(0)) msymbol(o X) mcolor(blue red) lcolor(blue red) ///
xtitle("Year") ytitle("Log Interest Spread") xline(2018) xlabel(2014(1)2023) savegraph("$fig_dir/binscatter_log_margin_bps_treated.png") replace

/***********
	Mechanism Tests
	***********/
	
	*** Competition

*** construct firm-level and industry-level competition measures
* firm
use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear
keep if year <= 2017
bysort gvkey: egen avg_number_of_lead_byfirm = mean(number_of_lead_arrangers)
egen median_number_of_lead = median(avg_number_of_lead_byfirm)

gen high_competition = 1 if avg_number_of_lead_byfirm >= median_number_of_lead
replace high_competition = 0 if high_competition == .

keep gvkey high_competition
duplicates drop 
tempfile firm_competition_measure
save `firm_competition_measure'

* firm post and change (INDUSTRY_LEVEL INSTEAD!!!)
use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

replace lender_parent_id = lender_id if lender_parent_id == .
* KKR and Everbank have missing lender_parent_id
bysort gvkey: egen pre_avg_number_of_lead_byfirm = mean(number_of_lead_arrangers) if post == 0
bysort gvkey: egen post_avg_number_of_lead_byfirm = mean(number_of_lead_arrangers) if post == 1
bysort gvkey: egen pre_number_of_lead_byfirm = max(pre_avg_number_of_lead_byfirm)
bysort gvkey: egen post_number_of_lead_byfirm = max(post_avg_number_of_lead_byfirm)
gen diff_num_lead_byfirm = post_number_of_lead_byfirm - pre_number_of_lead_byfirm
keep if diff_num_lead_byfirm != .

egen median_diff_num_lead_byfirm = median(diff_num_lead_byfirm)

gen increase_competition = 1 if diff_num_lead_byfirm > median_diff_num_lead_byfirm
replace increase_competition = 0 if diff_num_lead_byfirm < median_diff_num_lead_byfirm

* firm-level 
local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local treat_vars "treated treated_post treated_loss treated_loss_post"

fvset base 1 ff_48
fvset base 1 gvkey

gen treated_post_increase_comp = treated_post * increase_competition
gen treated_loss_post_increase_comp = treated_loss_post * increase_competition
gen treated_increase_competition = treated * increase_competition
gen treated_loss_increase_comp = treated_loss * increase_competition

reghdfe margin_bps treated_loss treated_loss_post `controls' `deal_controls', absorb(year gvkey sp_rating_num) 

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.gvkey ib2.sp_rating_num if increase_competition == 1
estimates store m1 

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.gvkey ib2.sp_rating_num if increase_competition == 0
estimates store m2

suest m1 m2, vce(cluster gvkey)
test [m1_mean]treated_loss_post = [m2_mean]treated_loss_post

*** industry level 

* industry
use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear
keep if year <= 2017

replace lender_parent_id = lender_id if lender_parent_id == .
* KKR and Everbank have missing lender_parent_id
bysort ff_48: egen number_of_lead_byindustry = nvals(lender_parent_id)
egen median_number_of_lead = median(number_of_lead_byindustry)
gen high_competition_industry = 1 if number_of_lead_byindustry >= median_number_of_lead
replace high_competition_industry = 0 if high_competition_industry == .

keep ff_48 high_competition_industry
duplicates drop 
tempfile industry_competition_mesaure
save `industry_competition_mesaure'

*** merge back to data for regressions
use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear
merge m:1 gvkey using `firm_competition_measure', nogen
merge m:1 ff_48 using `industry_competition_mesaure', nogen

save "../3. Data/Processed/tranche_level_ds_compa_wlabel_withcomp.dta", replace

use "../3. Data/Processed/tranche_level_ds_compa_wlabel_withcomp.dta", clear

*** industry-level cross-sectional 
replace lender_parent_id = lender_id if lender_parent_id == .
* KKR and Everbank have missing lender_parent_id
bysort ff_48: egen pre_avg_number_of_lead_byind = mean(number_of_lead_arrangers) if post == 0
bysort ff_48: egen post_avg_number_of_lead_byind = mean(number_of_lead_arrangers) if post == 1
bysort ff_48: egen pre_number_of_lead_byind = max(pre_avg_number_of_lead_byind)
bysort ff_48: egen post_number_of_lead_byind= max(post_avg_number_of_lead_byind)
gen diff_num_lead_byind = post_number_of_lead_byind - pre_number_of_lead_byind
keep if diff_num_lead_byind != .

egen median_diff_num_lead_byind = median(diff_num_lead_byind)

gen increase_competition_ind = 1 if diff_num_lead_byind > median_diff_num_lead_byind
replace increase_competition_ind = 0 if diff_num_lead_byind <= median_diff_num_lead_byind

* regressions
local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local treat_vars "treated treated_post treated_loss treated_loss_post"

*** split sample tests
fvset base 1 ff_48
fvset base 1 gvkey

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if increase_competition_ind == 1
estimates store m1

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if increase_competition_ind == 0
estimates store m2

suest m1 m2, vce(cluster ff_48)
test [m1_mean]treated_loss_post = [m2_mean]treated_loss_post

* save the results (esttab) using overleaf_dir
esttab m1 m2 using "$overleaf_dir/margin_did_both_rule_competition.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(`treat_vars')
est clear

* triple interaction 
gen treated_post_inc_comp_ind = treated_post * increase_competition_ind
gen treated_loss_post_inc_comp_ind = treated_loss_post * increase_competition_ind
gen treated_inc_comp_ind = treated * increase_competition_ind
gen treated_loss_inc_comp_ind = treated_loss * increase_competition_ind
gen post_inc_comp_ind = post * increase_competition_ind

local triple_inter "treated_post_inc_comp_ind treated_loss_post_inc_comp_ind treated_inc_comp_ind treated_loss_inc_comp_ind post_inc_comp_ind"

reghdfe margin_bps `treat_vars' `triple_inter' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)


	*** Relationship Lending
	use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

gen treated_relationship = treated * relationship
gen treated_loss_relationship = treated_loss * relationship
gen post_relationship = post * relationship
gen treated_post_relationship = treated_relationship * post
gen treated_loss_post_relationship = treated_loss_relationship * post

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local treat_vars "treated treated_post treated_loss treated_loss_post"
local relationship_vars "relationship post_relationship treated_relationship treated_post_relationship treated_loss_relationship treated_loss_post_relationship"

reghdfe margin_bps `treat_vars' `relationship_vars' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe log_margin_bps `treat_vars' `relationship_vars' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
reghdfe margin_bps treated_loss treated_loss_post relationship post_relationship treated_loss_relationship treated_loss_post_relationship `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3
reghdfe log_margin_bps treated_loss treated_loss_post relationship post_relationship treated_loss_relationship  treated_loss_post_relationship `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m4

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 using "$overleaf_dir/margin_did_both_rule_relationship.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(`treat_vars' `relationship_vars')
est clear

	*** Reputation
	use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

gen treated_reputation = treated * reputation
gen treated_loss_reputation = treated_loss * reputation
gen post_reputation = post * reputation
gen treated_post_reputation = treated_reputation * post
gen treated_loss_post_reputation = treated_loss_reputation * post	
	
local treat_vars "treated treated_post treated_loss treated_loss_post"
local reputation_vars "reputation post_reputation treated_reputation treated_post_reputation treated_loss_reputation treated_loss_post_reputation"
local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

reghdfe margin_bps `treat_vars' `reputation_vars' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe log_margin_bps `treat_vars' `reputation_vars' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
reghdfe margin_bps treated_loss treated_loss_post reputation post_reputation treated_loss_reputation treated_loss_post_reputation `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3
reghdfe log_margin_bps treated_loss treated_loss_post reputation post_reputation treated_loss_reputation  treated_loss_post_reputation `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m4

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 using "$overleaf_dir/margin_did_both_rule_reputation.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(`treat_vars' `reputation_vars')
est clear

****** Split Sample Tests
	use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local treat_vars "treated treated_post treated_loss treated_loss_post"

fvset base 1 ff_48
fvset base 1 gvkey

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if relationship == 1
estimates store m1

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if relationship == 0
estimates store m2

suest m1 m2, vce(cluster gvkey)
test [m1_mean]treated_loss_post = [m2_mean]treated_loss_post

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if reputation == 1
estimates store m3

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if reputation == 0
estimates store m4

suest m3 m4, vce(cluster gvkey)
test [m3_mean]treated_loss_post = [m4_mean]treated_loss_post

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 using "$overleaf_dir/margin_did_both_rule_mechanism.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(`treat_vars')
est clear

****** Subsample Tests
use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local treat_vars "treated treated_post treated_loss treated_loss_post"

*** generate indicator that each gvkey has both pre and post periods 
bysort gvkey: egen max_post = max(post)
bysort gvkey: egen min_post = min(post)
order gvkey year post max_post min_post
* keep only if max_post != min_post (so that borrower has both pre and post periods)
keep if min_post == 0

fvset base 1 ff_48

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if relationship == 1
estimates store m1

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if relationship == 0
estimates store m2

suest m1 m2, vce(cluster gvkey)
test [m1_mean]treated_loss_post = [m2_mean]treated_loss_post

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if reputation == 1
estimates store m3

reg margin_bps `treat_vars' `controls' `deal_controls' i.year i.ff_48 ib2.sp_rating_num if reputation == 0
estimates store m4

suest m3 m4, vce(cluster gvkey)
test [m3_mean]treated_loss_post = [m4_mean]treated_loss_post

/***********
	Falsification Tests
	***********/

import delimited "../3. Data/Processed/tranche_level_ds_compa_all.csv", clear

keep if year <= 2017

drop post
gen post = 1 if year >= 2014
replace post = 0 if post == .
rename excess_interest_30 treated
rename excess_interest_loss treated_loss
gen treated_post = treated * post
gen treated_loss_post = treated_loss * post

* gen logged bps
gen log_margin_bps = log(margin_bps)
gen log_at = log(at)
gen log_deal_amount_converted = log(deal_amount_converted)

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

* generate interaction between controls and post
foreach var in `controls' {
    gen `var'_post = `var' * post
	gen `var'_treated = `var' * treated
	gen `var'_treated_loss = `var' * treated_loss
}

local controls_post "log_at_post cash_flows_by_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post sales_growth_post dividend_payer_post nol_post ret_vol_post"

* winsorize at 1% and 99%
foreach var in margin_bps log_margin_bps `controls' `deal_controls' `controls_post' `controls_treated' `controls_treated_loss' {
    winsor2 `var', cuts(1 99) replace
}

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

label variable treated "Excess Interest (30\% Rule)"
label variable post "Post"
label variable treated_post "Excess Interest (30\% Rule) x Post"
label variable treated_loss "Excess Interest (Loss)"
label variable treated_loss_post "Excess Interest (Loss) x Post"
	
clean_rating

reghdfe margin_bps treated treated_post treated_loss treated_loss_post `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 using "$overleaf_dir/margin_did_both_rule_falsification.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')
est clear

/***********
	Robustness Tests 
	***********/

use "../3. Data/Processed/tranche_level_ds_compa_wlabel.dta", clear

gen excess_interest_scaled_post = excess_interest_scaled * post

label var excess_interest_scaled "Excess Interest Expense (Scaled)"
label var excess_interest_scaled_post "Excess Interest Expense (Scaled) x Post"

local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer nol ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post cash_flows_by_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post sales_growth_post dividend_payer_post nol_post ret_vol_post"

* keep only 
binscatter margin_bps excess_interest_scaled, controls(`controls' `deal_controls') by(post)

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2

*drop if year == 2020 | year == 2021 

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 using "$overleaf_dir/margin_ie_excess.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')
est clear

*** split by median

bysort year: egen median_excess = median(excess_interest_scaled)
bysort year: egen p80_excess = pctile(excess_interest_scaled), p(80)
*gen next_year_excess_treat = 1 if next_year_excess_interest_total > median_excess
gen ie_excess_treat = 1 if excess_interest_scaled > 0
replace ie_excess_treat = 0 if ie_excess_treat == .

gen ie_excess_treat_post = ie_excess_treat * post

reghdfe margin_bps ie_excess_treat ie_excess_treat_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)


*** close log
log close
