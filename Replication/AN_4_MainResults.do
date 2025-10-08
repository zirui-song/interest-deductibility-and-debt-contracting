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
	Main Results
	***********/

use "$cleandir/tranche_level_ds_compa_wlabel.dta", clear

*** VIF Analysis ***
local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post"	

reg margin_bps excess_interest_scaled excess_interest_scaled_post `deal_controls' i.year i.ff_48 i.sp_rating_num
estat vif
reg margin_bps excess_interest_scaled excess_interest_scaled_post `deal_controls' `controls' i.year i.ff_48 i.sp_rating_num
estat vif
reg margin_bps excess_interest_scaled excess_interest_scaled_post `deal_controls' `controls' `controls_post' i.year i.ff_48 i.sp_rating_num
estat vif
*** *** *** 

******************	Table 4: Main Results  ******************

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3

* save the results (esttab) using tabdir
esttab m1 m2 m3 using "$tabdir/margin_ie_excess.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')

* save one without control variables 
esttab m1 m2 m3 using "$tabdir/margin_ie_excess_noctrl.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post' `controls' `deal_controls')
est clear

******************	Table 4: Main Results (B + BB Only)  ******************

preserve
	keep if inrange(sp_rating_num, 7, 15) == 1

	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m1

	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m2

	reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
	estimates store m3

	* save the results (esttab) using tabdir
	esttab m1 m2 m3 using "$tabdir/margin_ie_excess_clo.tex", replace ///
	nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
	star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')

	* save one without control variables 
	esttab m1 m2 m3 using "$tabdir/margin_ie_excess_clo_noctrl.tex", replace ///
	nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
	star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post' `controls' `deal_controls')
	est clear
restore

******************	Figure 4: Main Results Binscatter  ******************
binscatter margin_bps excess_interest_scaled, controls(`controls' `deal_controls') by(post) ///  
    xtitle("Excess Interest Expense (Scaled)") ///
    ytitle("Margin (bps)") 
graph export "$figdir/binscatter_margin_ie_prepost.png", as(png) replace	

******************	Table C1: Logged Main Results  ******************

reghdfe log_margin_bps excess_interest_scaled excess_interest_scaled_post `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1

reghdfe log_margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2

reghdfe log_margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3

* save the results (esttab) using tabdir
esttab m1 m2 m3 using "$tabdir/log_margin_ie_excess.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')
est clear

******************	Main Results: Dynamic  ******************

local years 2014 2015 2016 2017 2018 2019 2022 2023
* generate year-specific treated dummies
foreach y of local years {
    gen treated_all_year_`y' = (treated_all == 1 & year == `y')
    replace treated_all_year_`y' = 0 if treated_all != 1 | year != `y'
	gen indicator_year_`y' = 1 if year == `y'
	replace indicator_year_`y' = 0 if indicator_year_`y' == .
	gen excess_interest_scaled_year_`y' = excess_interest_scaled * indicator_year_`y'
}

local dynamic_treated_all "treated_all_year_2015 treated_all_year_2016 treated_all_year_2017  treated_all_year_2018 treated_all_year_2019 treated_all_year_2022 treated_all_year_2023"

local dynamic_treated_excess_interest "excess_interest_scaled_year_2014 excess_interest_scaled_year_2015 excess_interest_scaled_year_2016 excess_interest_scaled_year_2018 excess_interest_scaled_year_2019 excess_interest_scaled_year_2022 excess_interest_scaled_year_2023"

* Q3 and Q4
gen treated_q = 1 if ie_excess_q3 == 1 | ie_excess_q4 == 1
replace treated_q = 0 if treated_q == .

foreach y of local years {
    gen treated_q_year_`y' = (treated_q == 1 & year == `y')
    replace treated_q_year_`y' = 0 if treated_q != 1 | year != `y'
}

local dynamic_treated_q "treated_q_year_2015 treated_q_year_2016 treated_q_year_2017 treated_q_year_2018 treated_q_year_2019 treated_q_year_2022 treated_q_year_2023"

*** Both Rule ***
reghdfe margin_bps treated_all `dynamic_treated_all' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$tabdir/margin_did_dynamic_all_ff48.csv", replace mlab(none)

*** Treated (Q3 and Q4) ***
reghdfe margin_bps treated_q `dynamic_treated_q' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$tabdir/margin_did_dynamic_q_ff48.csv", replace mlab(none)

*** Excess Interest ***
reghdfe margin_bps excess_interest_scaled `dynamic_treated_excess_interest' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$tabdir/margin_ie_excess_dynamic.csv", replace mlab(none)

******************	Table 6: Other Terms  ******************

*** DID regressions (Perf Pricing and Num Fin Cov) ***

reghdfe perf_pricing_dummy excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe sweep_dummy excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
reghdfe num_fin_cov excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m3
*** DID regressions (covenant tightness)
reghdfe pviol excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m4

local deal_controls3 "leveraged maturity log_deal_amount_converted tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

reghdfe secured_dummy excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls3' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m8

*** DID regressions (Loan Size and Maturity) ***

local deal_controls_2 "leveraged secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

reghdfe deal_amount_converted excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' maturity `deal_controls_2', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m5

reghdfe log_deal_amount_converted excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' maturity  `deal_controls_2', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m6

reghdfe maturity excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' log_deal_amount_converted `deal_controls_2', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m7

* save the results (esttab) using tabdir
esttab m5 m6 m7 m8 m1 m2 m3 m4 using "$tabdir/other_terms_ie_excess.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(excess_interest_scaled excess_interest_scaled_post)
est clear
