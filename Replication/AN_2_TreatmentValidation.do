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

*** 

use "$cleandir/tranche_level_ds_compa.dta", clear
drop treated*

merge m:1 gvkey fyear using "$cleandir/ds_gvkey_treatment_assignment.dta"
keep if _merge == 3
drop _merge
gen treated_post = treated * post

gen treated1_post = treated1 * post
gen treated2_post = treated2 * post
gen treated3_post = treated3 * post

gen treated_loss = treated2 + treated3
replace treated_loss = 0 if treated_loss == .
gen treated_loss_post = treated_loss * post

keep if year >= 2014
drop if year == 2020 | year == 2021

* gen logged bps
gen log_margin_bps = log(margin_bps)

* list of controls in regression 
gen log_at = log(at)
gen log_deal_amount_converted = log(deal_amount_converted)

local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

* generate interaction between controls and post
foreach var in `controls' {
    gen `var'_post = `var' * post
	gen `var'_treated = `var' * treated
}

local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post"
local controls_treated "log_at_treated market_to_book_treated ppent_by_at_treated debt_by_at_treated cash_by_at_treated dividend_payer_treated ret_vol_treated"

* winsorize at 1% and 99%
foreach var in margin_bps log_margin_bps `controls' `deal_controls' `controls_post' `controls_treated' `controls_treated_loss' {
    winsor2 `var', cuts(1 99) replace
}

local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol"
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

drop if year == 2020 | year == 2021

do "$codedir/AN_StataFunctions.do"
clean_rating

save "$cleandir/tranche_level_ds_compa_wlabel1.dta", replace

/***********
	Exposure Regression 
	***********/

use "$cleandir/tranche_level_ds_compa_wlabel1.dta", clear
	
gen excess_interest_30_post = excess_interest_30 * post
gen excess_interest_loss_post = excess_interest_loss * post
gen excess_interest_scaled_post = excess_interest_scaled * post 

label variable excess_interest_30 "Excess Interest (30\% Rule)"
label variable excess_interest_loss "Excess Interest (Loss)"
label variable excess_interest_30_post "Excess Interest (30\% Rule) X Post"
label variable excess_interest_loss_post "Excess Interest (Loss) X Post"

local treated_vars "excess_interest_30 excess_interest_loss"

local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post"
	
reghdfe next_year_excess_interest_total	`treated_vars' `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe next_year_excess_interest_total `treated_vars' `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2
	
reghdfe next_year_excess_interest_total `treated_vars' `controls' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
estimates store m3
reghdfe next_year_excess_interest_total `treated_vars' `controls' `controls_post' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
estimates store m4

* save the results (esttab) using tabdir
esttab m1 m2 m3 m4 using "$tabdir/next_year_excess_interest_total_validation.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(`treated_vars' `controls' `deal_controls')
est clear

label variable excess_interest_scaled "Excess Interest Expense (Scaled)"

reghdfe next_year_excess_interest_total	excess_interest_scaled `controls' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m1
reghdfe next_year_excess_interest_total excess_interest_scaled `controls' `controls_post' `deal_controls', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store m2

reghdfe next_year_excess_interest_total	excess_interest_scaled `controls' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
estimates store m3
reghdfe next_year_excess_interest_total excess_interest_scaled `controls' `controls_post' `deal_controls', absorb(year gvkey sp_rating_num) vce(cluster gvkey)
estimates store m4

* save the results (esttab) using tabdir
esttab m1 m2 m3 m4 using "$tabdir/next_year_excess_interest_total_validation_cts.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep(excess_interest_scaled `controls' `deal_controls')
est clear

*** BINSCATTERS

binsreg next_year_excess_interest_total excess_interest_scaled `controls' `deal_controls', nbins(50)

* original binscatter
binscatter next_year_excess_interest_total excess_interest_scaled, ///
	xtitle("Current-Year Excess Interest Expense (Scaled)") ///
    ytitle("Next-Year Excess Interest Expense (Scaled)") 
graph export "$figdir/binscatter_ie_current_next.png", as(png) replace	

binscatter next_year_excess_interest_total excess_interest_scaled, ///
    controls(`controls' `deal_controls') ///
    xtitle("Current-Year Excess Interest Expense (Scaled)") ///
    ytitle("Next-Year Excess Interest Expense (Scaled)")
graph export "$figdir/binscatter_ie_current_next_wcontrols.png", as(png) replace
