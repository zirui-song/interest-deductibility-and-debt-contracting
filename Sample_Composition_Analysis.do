*log using Dealscan_Analysis.log, replace

if "`c(hostname)'" == "mphill-surface4" {
global overleaf_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\Tax Incidence and Loan Contract Negotiations\Tables"
global fig_dir "C:\Users\mphill\Dropbox\Apps\Overleaf\Tax Incidence and Loan Contract Negotiations\Figures"
	
}

global overleaf_dir "/Users/zrsong/MIT Dropbox/Zirui Song/Apps/Overleaf/Tax Incidence and Loan Contract Negotiations/Tables"
global fig_dir "/Users/zrsong/MIT Dropbox/Zirui Song/Apps/Overleaf/Tax Incidence and Loan Contract Negotiations/Figures"

* Check if the directory exists, if not create it
cap mkdir "$overleaf_dir"


/***********
	Begin File
	***********/

use "../3. Data/Processed/dta_analysis.dta", clear

gen log_at = log(at)
gen cash_flows_by_at = oancf/at
gen ppent_by_at = ppent/at
gen debt_by_at = debt/at
gen cash_by_at = che/at

gen roa = ni/at

gen post = 1 if fyear >= 2018
replace post = 0 if post == .
gen treated = excess_interest_30 
gen treated_loss = excess_interest_loss
gen treated_post = treated * post 
gen treated_loss_post = treated_loss * post

local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol"

* generate interaction between controls and post
foreach var in `controls' {
    gen `var'_post = `var' * post
	gen `var'_treated = `var' * treated
	gen `var'_treated_loss = `var' * treated_loss
}
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post"

* winsorize at 1% and 99%
foreach var in `controls' `controls_post' ebitda roa cash_flows_by_at {
    winsor2 `var', cuts(1 99) replace
}

sicff sic, ind(48)

* generate continuous measures
gen excess_interest_scaled = interest_expense_total_excess / xint

gen excess_interest_scaled_post = excess_interest_scaled * post

*** quartile splits
gen ie_excess_q4 = 1 if excess_interest_scaled > 0.89999
gen ie_excess_q3 = 1 if inrange(excess_interest_scaled, 0.6, 0.89999)
gen ie_excess_q2 = 1 if inrange(excess_interest_scaled, 0.300001, 0.59999)
gen ie_excess_q1 = 1 if inrange(excess_interest_scaled, 0.00001, 0.3)

forv i = 1/4 {
	replace ie_excess_q`i' = 0 if excess_interest_scaled == 0
	replace ie_excess_q`i' = 0 if ie_excess_q`i' == .
}

forv i = 1/4 {
	gen ie_excess_q`i'_post = ie_excess_q`i' * post
}

label var excess_interest_scaled "Excess Interest Expense (Scaled)"
label var excess_interest_scaled_post "Excess Interest Expense (Scaled) x Post"
label var ie_excess_q1 "Excess Interest Expense Q1"
label var ie_excess_q2 "Excess Interest Expense Q2"
label var ie_excess_q3 "Excess Interest Expense Q3"
label var ie_excess_q4 "Excess Interest Expense Q4"
label var ie_excess_q1_post "Excess Interest Expense Q1 x Post"
label var ie_excess_q2_post "Excess Interest Expense Q2 x Post"
label var ie_excess_q3_post "Excess Interest Expense Q3 x Post"
label var ie_excess_q4_post "Excess Interest Expense Q4 x Post"

local treat_cts "excess_interest_scaled excess_interest_scaled_post"
local treat_quartiles "ie_excess_q1 ie_excess_q1_post ie_excess_q2 ie_excess_q2_post ie_excess_q3 ie_excess_q3_post ie_excess_q4 ie_excess_q4_post"


* label controls and treated, post, and treated_post
label variable log_at "Ln(Total Assets)"
label variable cash_flows_by_at "Cash Flows / Assets"
label variable market_to_book "Market to Book Ratio"
label variable ppent_by_at "PP\&E / Assets"
label variable debt_by_at "Debt / Assets"
label variable cash_by_at "Cash / Assets"
label variable sales_growth "Sales Growth"
label variable dividend_payer "Dividend Payer"
label variable z_score "Z-Scor
label variable nol "Net Operating Loss"
label variable ret_buy_and_hold "Buy and Hold Return"
label variable ret_vol "Return Volatility"

label variable treated "Excess Interest (30\% Rule)"
label variable post "Post"
label variable treated_post "Excess Interest (30\% Rule) x Post"
label variable treated_loss "Excess Interest (Loss)"
label variable treated_loss_post "Excess Interest (Loss) x Post"


save "../3. Data/Processed/full_panel_2013to2023.dta", replace

/***********
	Analysis (Panel)
	***********/
	
************** next-year EBITDA **************
* Make sure data is sorted by gvkey and fyear
sort gvkey fyear

replace ebitda = ebitda / at

* Generate next-year EBITDA for each company
by gvkey: gen next_year_ebitda = ebitda[_n+1] if gvkey == gvkey[_n+1]
gen ebitda_growth_rate = (next_year_ebitda - ebitda) / ebitda * 100 if !missing(next_year_ebitda)
by gvkey: gen next_2year_ebitda = ebitda[_n+2] if gvkey == gvkey[_n+2]

by gvkey: gen next_year_roa = roa[_n+1] if gvkey == gvkey[_n+1]
by gvkey: gen next_year_cash_flows_by_at = cash_flows_by_at[_n+1] if gvkey == gvkey[_n+1]

winsor2 next_year_ebitda next_2year_ebitda ebitda_growth_rate, cuts(1 99) replace

local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol"
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post"

reghdfe next_year_roa excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1
reghdfe next_year_roa excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m2
reghdfe next_year_roa excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m3
reghdfe next_year_roa excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m4

reghdfe next_year_cash_flows_by_at excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1
reghdfe next_year_cash_flows_by_at excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m2
reghdfe next_year_cash_flows_by_at excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m3
reghdfe next_year_cash_flows_by_at excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m4


reghdfe next_year_ebitda excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1
reghdfe next_year_ebitda excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m2
reghdfe next_year_ebitda excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m3
reghdfe next_year_ebitda excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m4

reghdfe next_2year_ebitda excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1
reghdfe next_2year_ebitda excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m2
reghdfe next_2year_ebitda excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m3
reghdfe next_2year_ebitda excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m4

reghdfe ebitda_growth_rate excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1
reghdfe ebitda_growth_rate excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m2
reghdfe ebitda_growth_rate excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m3
reghdfe ebitda_growth_rate excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m4

tempfile main
save `main'

************** Total bank percentage **************
import delimited "../3. Data/Processed/capstrct_2013to2022.csv", clear
keep gvkey fyear totbankdbtpct
merge 1:1 gvkey fyear using `main', nogen

reghdfe totbankdbtpct excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1
reghdfe totbankdbtpct excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m2
reghdfe totbankdbtpct excess_interest_scaled excess_interest_scaled_post `controls', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m3
reghdfe totbankdbtpct excess_interest_scaled excess_interest_scaled_post `controls' `controls_post', absorb(fyear gvkey) vce(cluster gvkey)
estimates store m4

tempfile main2
save `main2'

/***********
	Analysis (Cross-Section at Loan Issuance)
	***********/
	
use "../3. Data/Processed/tranche_level_ds_compa.dta", clear

* gen logged bps
gen log_margin_bps = log(margin_bps)
gen log_at = log(at)
gen log_deal_amount_converted = log(deal_amount_converted)
label variable leveraged "Leveraged"
label variable maturity "Maturity"
label variable log_deal_amount_converted "Log Loan Amount"
label variable secured_dummy "Secured"
label variable tranche_type_dummy "Tranche Type"
label variable tranche_o_a_dummy "Origination"
label variable sponsor_dummy "Sponsored"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
keep gvkey year fyear margin_bps `deal_controls'

merge m:1 gvkey fyear using `main2'

save "../3. Data/Processed/sample_composition_analysis.dta", replace

reghdfe totbankdbtpct excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m1
reghdfe totbankdbtpct excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m2	

reghdfe next_year_roa excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m3
reghdfe next_year_roa excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m4

reghdfe next_year_cash_flows_by_at excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m5
reghdfe next_year_cash_flows_by_at excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m6

reghdfe next_year_ebitda excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m7
reghdfe next_year_ebitda excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m8

esttab m1 m2 m3 m4 m5 m6 m7 m8 using "$overleaf_dir/next_year_risk_tests.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(excess_interest_scaled excess_interest_scaled_post `treat_vars' `controls' `deal_controls')
est clear

	
*** close log
*log close
