log using Dealscan_Analysis.log, replace

use "../3. Data/Processed/tranche_level_ds_compa.dta", clear
global overleaf_dir "/Users/zrsong/Dropbox (MIT)/Apps/Overleaf/M&A Debt/Tables"
global fig_dir "/Users/zrsong/Dropbox (MIT)/Apps/Overleaf/M&A Debt/Figures"

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
}
local controls_post "log_at_post cash_flows_by_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post sales_growth_post dividend_payer_post nol_post ret_vol_post"

* winsorize at 1% and 99%
foreach var in margin_bps log_margin_bps `controls' `deal_controls' `controls_post' {
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

label variable treated "Treated (30\% rule)"
label variable post "Post"
label variable treated_post "Treated (30\% rule) x Post"
label variable treated_loss "Treated (Loss rule)"
label variable treated_loss_post "Treated (Loss rule) x Post"

label variable treated_prev_3yr "Treated (30\% rule, Previous 3 Years)"
label variable treated_prev_3yr_post "Treated (30\% rule, Previous 3 Years) x Post"
label variable treated_loss_prev_3yr "Treated (Loss rule, Previous 3 Years)"
label variable treated_loss_prev_3yr_post "Treated (Loss rule, Previous 3 Years) x Post"
label variable treated_prev_5yr "Treated (30\% rule, Previous 5 Years)"
label variable treated_prev_5yr_post "Treated (30\% rule, Previous 5 Years) x Post"
label variable treated_loss_prev_5yr "Treated (Loss rule, Previous 5 Years)"
label variable treated_loss_prev_5yr_post "Treated (Loss rule, Previous 5 Years) x Post"

*** DID regressions (30% and Loss Rule: MAIN RESULT TABLE 1) ***

reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m2

* save the results (esttab) using overleaf_dir
esttab m1 m2 using "$overleaf_dir/margin_did_both_rule.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')
est clear

* Appendix Table D1: Logged Margin
reghdfe log_margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m1
reghdfe log_margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m2

* save the results (esttab) using overleaf_dir
esttab m1 m2 using "$overleaf_dir/log_margin_did_both_rule.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear

*** DID regressions (30% and Loss Rule: ROBUSTNESS RESULT TABLE 2) ***

* Firm FE 
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year gvkey) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year gvkey) vce(cluster gvkey)
estimates store m2
* 3-year and 5-year look backs
preserve  
	drop treated treated_post treated_loss treated_loss_post
	rename (treated_prev_3yr treated_prev_3yr_post treated_loss_prev_3yr treated_loss_prev_3yr_post) (treated treated_post treated_loss treated_loss_post)
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
	estimates store m3
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
	estimates store m4
	
	drop treated treated_post treated_loss treated_loss_post
	rename (treated_prev_5yr treated_prev_5yr_post treated_loss_prev_5yr treated_loss_prev_5yr_post) (treated treated_post treated_loss treated_loss_post)
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
	estimates store m5
	reghdfe margin_bps treated treated_post treated_loss treated_loss_post `controls' `controls_post' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
	estimates store m6
restore 

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 m5 m6 using "$overleaf_dir/margin_did_both_rule_robustness.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear


*** Appendix Table: Log Margin results with prev_3yr and prev_5yr definitions
reghdfe log_margin_bps treated_prev_3yr treated_prev_3yr_post treated_loss_prev_3yr treated_loss_prev_3yr_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m1
reghdfe log_margin_bps treated_prev_3yr treated_prev_3yr_post treated_loss_prev_3yr treated_loss_prev_3yr_post `controls' `controls_post' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m2
reghdfe log_margin_bps treated_prev_5yr treated_prev_5yr_post treated_loss_prev_5yr treated_loss_prev_5yr_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m3
reghdfe log_margin_bps treated_prev_5yr treated_prev_5yr_post treated_loss_prev_5yr treated_loss_prev_5yr_post `controls' `controls_post' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m4

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 using "$overleaf_dir/log_margin_did_both_rule_prev.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated_prev_3yr treated_prev_3yr_post treated_loss_prev_3yr treated_loss_prev_3yr_post ///
treated_prev_5yr treated_prev_5yr_post treated_loss_prev_5yr treated_loss_prev_5yr_post)
est clear

*********** Regressions with Other Loan Terms ***********

*** DID regressions (30% and Loss Rule: Perf Pricing and Num Fin Cov) ***

reghdfe perf_pricing_dummy treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m1
reghdfe num_fin_cov treated treated_post treated_loss treated_loss_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m2

*** DID regressions (30% and Loss Rule: Loan Size and Maturity) ***

local deal_controls_2 "leveraged secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

reghdfe deal_amount_converted treated treated_post treated_loss treated_loss_post `controls' `deal_controls_2', absorb(year ff_48) vce(cluster gvkey)
estimates store m3

reghdfe log_deal_amount_converted treated treated_post treated_loss treated_loss_post `controls' `deal_controls_2', absorb(year ff_48) vce(cluster gvkey)
estimates store m4

reghdfe maturity treated treated_post treated_loss treated_loss_post `controls' `deal_controls_2', absorb(year ff_48) vce(cluster gvkey)
estimates store m5

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 m5 using "$overleaf_dir/other_terms_did_both_rule.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(treated treated_post treated_loss treated_loss_post)
est clear

*********** Dynamic Regressions ***********
local dynamic_treated "treated_year_2014 treated_year_2015 treated_year_2016 treated_year_2018 treated_year_2019 treated_year_2020 treated_year_2021 treated_year_2022 treated_year_2023"
local dynamic_treated_loss "treated_loss_year_2014 treated_loss_year_2015 treated_loss_year_2016 treated_loss_year_2018 treated_loss_year_2019 treated_loss_year_2020 treated_loss_year_2021 treated_loss_year_2022 treated_loss_year_2023"

*** Loss Rule ***
reghdfe margin_bps treated_loss `dynamic_treated_loss' `controls' `deal_controls', absorb(year ff_48) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_loss_ff48.csv", replace mlab(none)

* drop 2020 and re run the regression
drop if year == 2020
reghdfe margin_bps treated_loss `dynamic_treated_loss' `controls' `deal_controls', absorb(year ff_48) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_loss_ff48_no2020.csv", replace mlab(none)

*** 30% Rule ***

reghdfe margin_bps treated `dynamic_treated' `controls' `deal_controls', absorb(year ff_48) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_ff48.csv", replace mlab(none)

reghdfe margin_bps treated `dynamic_treated' `controls' `deal_controls', absorb(year gvkey) vce(cluster gvkey)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/margin_did_dynamic_gvkey.csv", replace mlab(none)

*********** Dynamic Regressions (num of financial covenants) ***********
reghdfe num_fin_cov treated `dynamic_treated' `controls' `deal_controls', absorb(year ff_48) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/num_fin_cov_did_dynamic_ff48.csv", replace mlab(none)

reghdfe num_fin_cov treated `dynamic_treated' `controls' `deal_controls', absorb(year gvkey) vce(cluster gvkey)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/num_fin_cov_did_dynamic_gvkey.csv", replace mlab(none)

*********** Dynamic Regressions (perf_pricing_dummy) ***********
reghdfe perf_pricing_dummy treated `dynamic_treated' `controls' `deal_controls', absorb(year ff_48) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/perf_pricing_dummy_did_dynamic_ff48.csv", replace mlab(none)

reghdfe perf_pricing_dummy treated `dynamic_treated' `controls' `deal_controls', absorb(year gvkey) vce(cluster gvkey)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/perf_pricing_dummy_did_dynamic_gvkey.csv", replace mlab(none)

*********** Dynamic Regressions (sweep_dummy) ***********
reghdfe sweep_dummy treated `dynamic_treated' `controls' `deal_controls', absorb(year ff_48) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/sweep_dummy_did_dynamic_ff48.csv", replace mlab(none)

reghdfe sweep_dummy treated `dynamic_treated' `controls' `deal_controls', absorb(year gvkey) vce(cluster gvkey)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "$overleaf_dir/sweep_dummy_did_dynamic_gvkey.csv", replace mlab(none)

*********** Binscatters ***********
* binscatters
binscatter margin_bps year, by(treated_loss) controls(`controls' `deal_controls') legend(label(1 "Control (Loss rule)") label(2 "Treated (Loss rule)") position(1) ring(0)) ///
xtitle("Year") ytitle("Interest Spread (Basis Points)") xline(2017) savegraph("$fig_dir/binscatter_margin_bps_treated_loss.png") replace

binscatter log_margin_bps year, by(treated_loss) controls(`controls' `deal_controls') legend(label(1 "Control (Loss rule)") label(2 "Treated (Loss rule)") position(1) ring(0)) ///
xtitle("Year") ytitle("Log Interest Spread") xline(2017) savegraph("$fig_dir/binscatter_log_margin_bps_treated_loss.png") replace

binscatter margin_bps year, by(treated) controls(`controls' `deal_controls') legend(label(1 "Control (30% rule)") label(2 "Treated (30% rule)") position(1) ring(0)) ///
xtitle("Year") ytitle("Interest Spread (Basis Points)") xline(2017) savegraph("$fig_dir/binscatter_margin_bps_treated.png") replace

binscatter log_margin_bps year, by(treated) controls(`controls' `deal_controls') legend(label(1 "Control (30% rule)") label(2 "Treated (30% rule)") position(1) ring(0)) ///
xtitle("Year") ytitle("Log Interest Spread") xline(2017) savegraph("$fig_dir/binscatter_log_margin_bps_treated.png") replace

*** close log
log close
