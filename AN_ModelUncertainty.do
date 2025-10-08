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

*** Model Uncertainty Analysis ***
local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol"
local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post"	

/***********
 Model uncertainty: BIC-weighted averaging across m1–m3
 (FE and clustering held fixed)
***********/

* --- Leave-one-out model averaging relative to the full spec (m3) ---

* Full control set:
local full "`deal_controls' `controls' `controls_post'"

tempname H2
tempfile MU2
postfile `H2' str40 model double b_main se_main b_post se_post bic N k using "`MU2'", replace

* 0) Full model (no variable dropped)
quietly reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `full', ///
    absorb(year ff_48 sp_rating_num) vce(cluster gvkey) resid
tempvar u u2
quietly predict double `u', resid
quietly gen double `u2' = `u'^2 if e(sample)
quietly summarize `u2', meanonly
scalar rss = r(sum)
scalar N   = e(N)
scalar k   = e(df_m)
scalar bic = N*ln(rss/N) + k*ln(N)
post `H2' ("full") (_b[excess_interest_scaled]) (_se[excess_interest_scaled]) ///
                 (_b[excess_interest_scaled_post]) (_se[excess_interest_scaled_post]) ///
                 (bic) (N) (k)

* 1) Drop one covariate at a time
foreach v of local full {
    local drop "`v'"
    local THIS : list full - drop

    quietly reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `THIS', ///
        absorb(year ff_48 sp_rating_num) vce(cluster gvkey) resid

    tempvar r r2
    quietly predict double `r', resid
    quietly gen double `r2' = `r'^2 if e(sample)
    quietly summarize `r2', meanonly
    scalar rss = r(sum)
    scalar N   = e(N)
    scalar k   = e(df_m)
    scalar bic = N*ln(rss/N) + k*ln(N)

    post `H2' ("drop: `v'") (_b[excess_interest_scaled]) (_se[excess_interest_scaled]) ///
                     (_b[excess_interest_scaled_post]) (_se[excess_interest_scaled_post]) ///
                     (bic) (N) (k)
}
postclose `H2'

use "`MU2'", clear
egen minbic = min(bic)
gen dBIC = bic - minbic
gen w    = exp(-0.5*dBIC)
egen W   = total(w)
replace w = w/W

foreach which in main post {
    gen v_`which'      = se_`which'^2
    egen bbar_`which'  = total(w * b_`which')
    gen  dev2_`which'  = (b_`which' - bbar_`which')^2
    egen vbar_`which'  = total(w * (v_`which' + dev2_`which'))
    gen  sebar_`which' = sqrt(vbar_`which')
}

display as text "LOO BIC-weighted averages:"
display "excess_interest_scaled (b, se): " %9.4f bbar_main[1] "  " %9.4f sebar_main[1]
display "excess_interest_scaled_post (b, se): " %9.4f bbar_post[1] "  " %9.4f sebar_post[1]

/*
    Confidence bands plot (post only), sorted by ΔBIC for readability
*/
preserve
    sort model
    egen mid = group(model), label
    gen lb_post = b_post - 1.96*se_post
    gen ub_post = b_post + 1.96*se_post
    quietly summarize mid, meanonly
    local ymax = r(max)

    twoway ///
        (rcap ub_post lb_post mid, horizontal lc(red) lwidth(medthick)), ///
        ytitle("") xtitle("beta: excess_interest_scaled_post") legend(off) ///
        xline(0, lc(gs12) lpattern(dash) lwidth(thin)) ///
        ylabel(1(1)`ymax', angle(0) valuelabel labsize(small))

    graph export "$figdir/spec_curve_confidence_bands.pdf", replace
restore
