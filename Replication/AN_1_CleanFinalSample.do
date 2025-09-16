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
	Clean Data for Regressions
	***********/

use "$cleandir/tranche_level_ds_compa.dta", clear	
	
do "$codedir/AN_StataFunctions.do"
clean_rating
clean_variables
generate_treat_vars

save "$cleandir/tranche_level_ds_compa_wlabel.dta", replace
