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
	Sample Composition Analysis
	***********/

/***********
	Clean Data
	***********/

use "$cleandir/dta_analysis.dta", clear

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

save "$cleandir/full_panel_2013to2023.dta", replace

************** next-year EBITDA **************
* Make sure data is sorted by gvkey and fyear

use "$cleandir/full_panel_2013to2023.dta", clear
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

tempfile main
save `main'

************** Total bank percentage **************
import delimited "$cleandir/capstrct_2013to2022.csv", clear
keep gvkey fyear totbankdbtpct
merge 1:1 gvkey fyear using `main', nogen

tempfile main2
save `main2'

use "$cleandir/tranche_level_ds_compa.dta", clear

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

* generate continuous measures
gen excess_interest_scaled = interest_expense_total_excess / xint
do "$codedir/AN_StataFunctions.do"
generate_treat_vars

save "$cleandir/sample_composition_analysis.dta", replace


/***********
	Analysis (Cross-Section at Loan Issuance)
	***********/
	
use "$cleandir/tranche_level_ds_compa_wlabel.dta", clear

drop if sp_rating_num == 0
reghdfe sp_rating_num excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m1
reghdfe sp_rating_num excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(year ff_48) vce(cluster gvkey)
estimates store m2

*** other LHS variables
use "$cleandir/sample_composition_analysis.dta", clear

reghdfe totbankdbtpct excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m3
reghdfe totbankdbtpct excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m4	

reghdfe next_year_roa excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m5
reghdfe next_year_roa excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m6

reghdfe next_year_cash_flows_by_at excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m7
reghdfe next_year_cash_flows_by_at excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m8

reghdfe next_year_ebitda excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m9
reghdfe next_year_ebitda excess_interest_scaled excess_interest_scaled_post `controls' `controls_post' `deal_controls', absorb(fyear ff_48) vce(cluster gvkey)
estimates store m10

esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using "$tabdir/next_year_risk_tests.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(excess_interest_scaled excess_interest_scaled_post `treat_vars' `controls' `deal_controls')
est clear

*** close log
*log close
