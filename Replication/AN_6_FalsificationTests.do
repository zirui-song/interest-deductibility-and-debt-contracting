/***********
	Globals for Paths
	***********/

*** Change repodir and overleafdir paths for different users
global repodir "/Users/zrsong/MIT Dropbox/Zirui Song/Research Projects/MPS_Interest Deductibility and Debt Contracting"
global overleafdir "/Users/zrsong/MIT Dropbox/Zirui Song/Apps/Overleaf/Tax Incidence and Loan Contract Terms"

global datadir "$repodir/3. Data"
global rawdir "$datadir/Raw"
global cleandir "$datadir/Processed"

global tabdir "$overleafdir/Tables"
global figdir "$overleafdir/Figures"

global codedir "$repodir/4. Code/Replication"

/***********
	Falsification Tests
	***********/

import delimited "$cleandir/tranche_level_ds_compa_all.csv", clear

keep if year <= 2017

drop post
gen post = 1 if year >= 2014
replace post = 0 if post == .
rename excess_interest_30 treated
rename excess_interest_loss treated_loss
gen treated_post = treated * post
gen treated_loss_post = treated_loss * post

do "$codedir/AN_StataFunctions.do"
clean_rating
clean_variables
generate_treat_vars

*** relabel variables 

label variable post "Post2014"
label variable treated_post "Excess Interest (30\% Rule) x Post2014"
label variable treated_loss_post "Excess Interest (Loss) x Post2014"
label variable excess_interest_scaled_post "Excess Interest Expense (Scaled) x Post2014"
label var ie_excess_q1_post "Excess Interest Expense Q1 x Post2014"
label var ie_excess_q2_post "Excess Interest Expense Q2 x Post2014"
label var ie_excess_q3_post "Excess Interest Expense Q3 x Post2014"
label var ie_excess_q4_post "Excess Interest Expense Q4 x Post2014"
		
local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol cash_etr"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post  dividend_payer_post ret_vol_post cash_etr_post"
local deal_controls_post "leveraged_post maturity_post log_deal_amount_converted_post secured_dummy_post tranche_type_dummy_post tranche_o_a_dummy_post sponsor_dummy_post"
	
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3

* save the results (esttab) using tabdir
esttab m1 m2 m3 using "$tabdir/margin_did_both_rule_falsification.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')
est clear

*** Table 9: Continuous Measure

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1

* save the results (esttab) using tabdir
esttab m1 using "$tabdir/margin_did_both_rule_falsification_cts.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')

* save the results (esttab) using tabdir
esttab m1 using "$tabdir/margin_did_both_rule_falsification_cts_noctrl.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post' `controls' `deal_controls')
est clear

*** Table C5: Quartile Exposure 

local treat_quartiles "ie_excess_q1 ie_excess_q1_post ie_excess_q2 ie_excess_q2_post ie_excess_q3 ie_excess_q3_post ie_excess_q4 ie_excess_q4_post"

reghdfe margin_bps `treat_quartiles' `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1

* save the results (esttab) using tabdir
esttab m1 using "$tabdir/margin_did_both_rule_falsification_all.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')
