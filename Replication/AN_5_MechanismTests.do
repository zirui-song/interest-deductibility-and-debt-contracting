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
	Mechanism Tests
	***********/
	
	*** Table 7: Competition

*** construct firm-level and industry-level competition measures
* firm
use "$cleandir/tranche_level_ds_compa_wlabel.dta", clear

bysort gvkey: egen avg_number_of_lead_byfirm = mean(number_of_lead_arrangers)
egen median_number_of_lead = median(avg_number_of_lead_byfirm)
egen p33_number_of_lead_byfirm = pctile(avg_number_of_lead_byfirm), p(33)
egen p67_number_of_lead_byfirm = pctile(avg_number_of_lead_byfirm), p(67)

gen high_competition = 1 if avg_number_of_lead_byfirm >= p67_number_of_lead_byfirm
replace high_competition = 0 if avg_number_of_lead_byfirm <= p33_number_of_lead_byfirm

keep gvkey high_competition
duplicates drop 
tempfile firm_competition_measure
save `firm_competition_measure'

* industry
use "$cleandir/tranche_level_ds_compa_wlabel.dta", clear

replace lender_parent_id = lender_id if lender_parent_id == .
* KKR and Everbank have missing lender_parent_id
bysort ff_48: egen number_of_lead_byindustry = nvals(lender_parent_id)
bysort ff_48: egen number_of_firms = nvals(gvkey)
replace number_of_lead_byindustry = number_of_lead_byindustry/number_of_firms

egen median_number_of_lead = median(number_of_lead_byindustry)
egen p33_number_of_lead = pctile(number_of_lead_byindustry), p(33)
egen p67_number_of_lead = pctile(number_of_lead_byindustry), p(67)

gen high_competition_industry = 1 if number_of_lead_byindustry >= p67_number_of_lead
replace high_competition_industry = 0 if number_of_lead_byindustry <= p33_number_of_lead

keep ff_48 high_competition_industry
duplicates drop 
tempfile industry_competition_measure
save `industry_competition_measure'

*** merge back to data for regressions
use "$cleandir/tranche_level_ds_compa_wlabel.dta", clear
merge m:1 gvkey using `firm_competition_measure', nogen
merge m:1 ff_48 using `industry_competition_measure', nogen

save "$cleandir/tranche_level_ds_compa_wlabel_withcomp.dta", replace

use "$cleandir/tranche_level_ds_compa_wlabel_withcomp.dta", clear

local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol cash_etr"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post cash_etr_post"	

local treat_vars "treated treated_post treated_loss treated_loss_post"

*** split sample tests with continuous measure

fvset base 1 ff_48
fvset base 1 gvkey

reg margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post' i.year i.ff_48 ib2.sp_rating_num if high_competition_industry == 0
estimates store m1

reg margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post' i.year i.ff_48 ib2.sp_rating_num if high_competition_industry == 1
estimates store m2

suest m1 m2, vce(cluster gvkey)
test [m1_mean]excess_interest_scaled = [m2_mean]excess_interest_scaled
test [m1_mean]excess_interest_scaled_post = [m2_mean]excess_interest_scaled_post

* save the results (esttab) using tabdir
esttab m1 m2 using "$tabdir/margin_did_both_rule_competition_cts.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep( excess_interest_scaled excess_interest_scaled_post)
est clear 

****************** Demand Side Elasticity ******************

*** Table 8: HP Financial Constraint (RFS 2015) and Linn Weagley 2024 Extension 

local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol cash_etr"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post cash_etr_post"	

use "$cleandir/tranche_level_ds_compa_wlabel.dta", clear	
fvset base 1 ff_48
merge m:1 gvkey year using "$rawdir/LinnWeagley_Constraint_Data_2025_01.dta"
keep if _merge == 3

bysort ff_48: egen median_lw_debtcon_full = median(lw_debtcon_full)
bysort ff_48: egen p33_lw_debtcon_full = pctile(lw_debtcon_full), p(33)
bysort ff_48: egen p67_lw_debtcon_full = pctile(lw_debtcon_full), p(67)

gen high_debtcon = 1 if lw_debtcon_full >= p67_lw_debtcon_full
replace high_debtcon = 0 if lw_debtcon_full <= p33_lw_debtcon_full

reg margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post' i.year i.ff_48 ib2.sp_rating_num if high_debtcon == 0
estimates store m1

reg margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post' i.year i.ff_48 ib2.sp_rating_num if high_debtcon == 1
estimates store m2

suest m1 m2, vce(cluster gvkey)
test [m1_mean]excess_interest_scaled_post = [m2_mean]excess_interest_scaled_post
	
* save the results (esttab) using tabdir
esttab m1 m2 using "$tabdir/hp_finconstr_cross.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant keep( excess_interest_scaled excess_interest_scaled_post)

/***********
	Alternative Mechanism Tests
	***********/

*** Approach 1: Interaction Terms (Full Sample)
display "=========================================="
display "APPROACH 1: INTERACTION TERMS"
display "=========================================="

* Competition - Interaction approach
use "$cleandir/tranche_level_ds_compa_wlabel_withcomp.dta", clear

local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol cash_etr"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post cash_etr_post"

fvset base 1 ff_48

* Create interaction terms
cap drop post_X_highcomp
gen post_X_highcomp = post * high_competition_industry
gen excess_X_highcomp = excess_interest_scaled * high_competition_industry
gen excess_post_X_highcomp = excess_interest_scaled_post * high_competition_industry

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post excess_X_highcomp excess_post_X_highcomp high_competition_industry post_X_highcomp `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store comp_interaction

display "Competition Interaction Test - coefficient on excess_post_X_highcomp:"
test excess_post_X_highcomp = 0

* Label interaction variables
label var excess_X_highcomp "Excess Interest x High Competition"
label var excess_post_X_highcomp "Excess Interest x Post x High Competition"
label var post_X_highcomp "Post x High Competition"

* Save competition interaction table
esttab comp_interaction using "$tabdir/competition_interaction.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) r2 plain lines fragment noconstant ///
order(excess_interest_scaled excess_interest_scaled_post excess_post_X_highcomp excess_X_highcomp post_X_highcomp) ///
keep(excess_interest_scaled excess_interest_scaled_post excess_post_X_highcomp excess_X_highcomp post_X_highcomp)
est clear

* Financial Constraint - Interaction approach
use "$cleandir/tranche_level_ds_compa_wlabel.dta", clear
fvset base 1 ff_48
merge m:1 gvkey year using "$rawdir/LinnWeagley_Constraint_Data_2025_01.dta"
keep if _merge == 3

bysort ff_48: egen median_lw_debtcon_full = median(lw_debtcon_full)
bysort ff_48: egen p33_lw_debtcon_full = pctile(lw_debtcon_full), p(33)
bysort ff_48: egen p67_lw_debtcon_full = pctile(lw_debtcon_full), p(67)

gen high_debtcon = 1 if lw_debtcon_full >= p67_lw_debtcon_full
replace high_debtcon = 0 if lw_debtcon_full <= p33_lw_debtcon_full

* Create interaction terms
cap drop post_X_highdebt
gen post_X_highdebt = post * high_debtcon
gen excess_X_highdebt = excess_interest_scaled * high_debtcon
gen excess_post_X_highdebt = excess_interest_scaled_post * high_debtcon

reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post excess_X_highdebt excess_post_X_highdebt high_debtcon post_X_highdebt `controls' `deal_controls' `controls_post', absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
estimates store fincon_interaction

display "Financial Constraint Interaction Test - coefficient on excess_post_X_highdebt:"
test excess_post_X_highdebt = 0

* Label interaction variables
label var excess_X_highdebt "Excess Interest x High Constraint"
label var excess_post_X_highdebt "Excess Interest x Post x High Constraint"
label var post_X_highdebt "Post x High Constraint"

* Save financial constraint interaction table
esttab fincon_interaction using "$tabdir/finconstraint_interaction.tex", replace ///
nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
star(* 0.10 ** 0.05 *** 0.01) r2 plain lines fragment noconstant ///
order(excess_interest_scaled excess_interest_scaled_post excess_post_X_highdebt excess_X_highdebt post_X_highdebt) ///
keep(excess_interest_scaled excess_interest_scaled_post excess_post_X_highdebt excess_X_highdebt post_X_highdebt)
est clear
