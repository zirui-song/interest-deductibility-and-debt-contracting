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
	Appendix Tables
	***********/	
	
use "$cleandir/tranche_level_ds_compa_wlabel.dta", clear	
	
local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol cash_etr"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post cash_etr_post"	

*** Table C2: Quartile Exposures

local treat_quartiles "ie_excess_q1 ie_excess_q1_post ie_excess_q2 ie_excess_q2_post ie_excess_q3 ie_excess_q3_post ie_excess_q4 ie_excess_q4_post"

reghdfe margin_bps `treat_quartiles' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps `treat_quartiles' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
reghdfe margin_bps `treat_quartiles' `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3
reghdfe log_margin_bps `treat_quartiles' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m4
reghdfe log_margin_bps `treat_quartiles' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m5
reghdfe log_margin_bps `treat_quartiles' `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m6

* save the results (esttab) using tabdir
esttab m1 m2 m3 m4 m5 m6 using "$tabdir/margin_ie_excess_quartiles.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(`treat_quartiles')
est clear

*** Table C3: Lender FEs (no variation on the lender side)

preserve 
	keep if primary_role == "Admin agent"
	* continuous measure
	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `deal_controls', absorb(year ff_48 sp_rating_num lender_parent_id) vce(cluster gvkey)
	estimates store m1

	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num lender_parent_id) vce(cluster gvkey)
	estimates store m2

	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num lender_parent_id) vce(cluster gvkey)
	estimates store m3

	* quartile exposure
	reghdfe margin_bps `treat_quartiles' `deal_controls', absorb(year ff_48 sp_rating_num lender_parent_id) vce(cluster gvkey)
	estimates store m4

	reghdfe margin_bps `treat_quartiles' `controls' `deal_controls', absorb(year ff_48 sp_rating_num lender_parent_id) vce(cluster gvkey)
	estimates store m5

	reghdfe margin_bps `treat_quartiles' `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num lender_parent_id) vce(cluster gvkey)
	estimates store m6

	* save the results (esttab) using tabdir
	esttab m1 m2 m3 m4 m5 m6 using "$tabdir/margin_ie_excess_lenderfe.tex", replace ///
	nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
	star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post' `deal_controls' `controls')
restore

*** Table C4: Entropy Balance

ebalance treated_all `controls'

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' [pweight=_webal], absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post' [pweight=_webal], absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2

reghdfe margin_bps `treat_quartiles' `controls' `deal_controls' [pweight=_webal], absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3
reghdfe margin_bps `treat_quartiles' `controls' `deal_controls' `controls_post' [pweight=_webal], absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m4

* save the results (esttab) using tabdir
esttab m1 m2 m3 m4 using "$tabdir/margin_did_both_rule_robustness_ebal.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(excess_interest_scaled excess_interest_scaled_post `treat_quartiles')
est clear

*** Table C6: MNC / Foreign Pretax Income
************ ROBUSTNESS (MNC / Pifo txfo)

preserve 
	keep if mnc == 0
	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m1
	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m2
	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m3
restore

	lab var pifo "Pretax Foreign Income"
	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post pifo `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m4
	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post pifo `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m5
	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post pifo `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m6
	
* save the results (esttab) using tabdir
esttab m1 m2 m3 m4 m5 m6 using "$tabdir/margin_ie_excess_pifo_robust.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(excess_interest_scaled excess_interest_scaled_post)
est clear
