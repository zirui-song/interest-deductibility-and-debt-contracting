
use "../3. Data/Processed/tranche_level_ds_compa.dta", clear
global overleaf_dir "/Users/zrsong/Dropbox (MIT)/Apps/Overleaf/M&A Debt"

* list of controls in regression 
gen log_at = log(at)
gen secured_dummy = 0 
replace secured_dummy = 1 if secured == "Yes"
local controls "log_at cash_flows_by_at market_to_book ppent_by_at debt_by_at cash_by_at sales_growth dividend_payer z_score nol"
local deal_controls "leveraged deal_amount_converted secured_dummy"

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

label variable leveraged "Leveraged"
label variable deal_amount_converted "Deal Amount ($)"
label variable secured_dummy "Secured"

label variable treated "Treated"
label variable post "Post"
label variable treated_post "Treated x Post"

reghdfe margin_bps treated treated_post, absorb(year ff_48) vce(cluster gvkey)
estimates store m1
reghdfe margin_bps treated treated_post, absorb(year gvkey) vce(cluster gvkey)
estimates store m2
reghdfe margin_bps treated treated_post `controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m3
reghdfe margin_bps treated treated_post `controls', absorb(year gvkey) vce(cluster gvkey)
estimates store m4
reghdfe margin_bps treated treated_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m5
reghdfe margin_bps treated treated_post `controls' `deal_controls', absorb(year gvkey) vce(cluster gvkey)
estimates store m6

* save the results (esttab) using overleaf_dir
esttab m1 m2 m3 m4 m5 m6 using "$overleaf_dir/Tables/margin_did.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant



*********** Dynamic Regressions ***********
local dynamic_treated "treated_year_2010 treated_year_2011 treated_year_2012 treated_year_2013 treated_year_2014 treated_year_2015 treated_year_2016 treated_year_2017 treated_year_2019 treated_year_2020"

reghdfe margin_bps `dynamic_treated' `controls' `deal_controls', absorb(fyear ff_48) vce(cluster ff_48)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "../5. Results/Tables/margin_did_dynamic_ff48.csv", replace mlab(none)

reghdfe margin_bps `dynamic_treated' `controls' `deal_controls', absorb(fyear gvkey) vce(cluster gvkey)
mat c = e(b)'
mata st_matrix("srdvcovbt",sqrt(diagonal(st_matrix("e(V)"))))
mat res = c , srdvcovbt

esttab mat(res) using "../5. Results/Tables/margin_did_dynamic_gvkey.csv", replace mlab(none)
