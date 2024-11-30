/*************************************************************************************************/
/* FILENAME:        Step2_CovenantSlack.sas                                                            */
/* AUTHOR:          Edward Owens                            					                 */
/* PURPOSE:         compile loan package observations from Dealscan and calculate covenant slack */
/* INPUT FILES:		Dealscan datasets; "matdata" (created in the Step 1 program)                 */
/* FILES CREATED:	"covslack"; a series of "covslackYYYY" files                                 */
/*************************************************************************************************/

* 	define libraries;
libname perm 'insert path where you store your permanent datasets';
libname dscan 'insert path where you store your Dealscan data';

/***************************************************************/
/*	Bring in the Dealscan data and compute covenant slack      */
/***************************************************************/

* Need packageid union from Dealscan financial covenant and net worth covenant datasets; 
data financialcov; set dscan.financialcovenant;
	if missing(initialratio)=1 and missing(initialamt)=0 then initialratio=initialamt;
data financialcov; set financialcov;
	keep packageid covenanttype initialratio;
	rename initialratio=base;
data networthcov; set dscan.networthcovenant;
	keep packageid covenanttype baseamt;
	rename baseamt=base;
	if covenanttype = 'NA' then delete;
data allcov; set financialcov networthcov;
	run; 
proc sort data=allcov;
	by packageid;
proc transpose data= allcov out=covenants name=InitialRatio;
	by packageid; 
	id CovenantType;
	run; 
proc sort data=covenants nodupkey;
	by packageid;
	run; 
data covenants; set covenants;
	if missing(packageid)=0;
	run; 

/*	Merge in gvkey matches from the Chava and Roberts file */
*  	first need to bring in Borrower ID and deal date;
data package; set dscan.package;
proc sort data=package nodupkey out=packagecos;
	by packageid;
proc sql;
	create table covenants
	as select a.*, b.BorrowerCompanyID, b.DealActiveDate
	from covenants a left join packagecos b
	on a.PackageID = b.PackageID;
	quit; 
*bring in gvkey;
proc sql;
	create table covenants
	as select a.*, b.gvkey
	from covenants a left join dscan.gvkeylink_aug2012 b
	on a.BorrowerCompanyID = b.bcoid;
	quit; 
* note: filename "gvkeylink_aug2012" is the linking file obtained from Michael Roberts' website (now available on WRDS);

* only keep observations with gvkey link and deal dates;
data covenants; set covenants;
	if gvkey ne '' and missing(DealActiveDate)=0;
	run; 

*	Bring in most recent accounting data for each gvkey as of the DealActiveDate;
* 	accounting data is from the file "matdata", created in the Step 1 program;
proc sql; 
	create table covslack
	as select a.*, b.*
	from covenants a left join perm.matdata b
	on (a.gvkey = b.gvkey) and (b.datadate=(select max(c.datadate) as datadate from perm.matdata as c where c.datadate le a.DealActiveDate
											and a.gvkey = c.gvkey));
	quit; 

*	delete observations with no matching accounting data available;
data covslack; set covslack;
	if gvkey = '' then delete;
	run;

*	if accounting data was more than 135 days (our choice) prior to deal active date, it's stale, so delete;
data covslack; set covslack;
	if (DealActiveDate-datadate)>135 then delete;
	run; 

* if a loan package does not contain a certain covenant, effectively give that covenant infinite slack;
%let s = 9999999999999999999;
data covslack; set covslack;
	if missing(Min__Interest_Coverage)=1 then slack_INTCOV = &s; else slack_INTCOV = INTCOV/Min__Interest_Coverage;
	if missing(Min__Cash_Interest_Coverage)=1 then slack_CASHINTCOV = &s; else slack_CASHINTCOV = CASHINTCOV/Min__Cash_Interest_Coverage;
	if missing(Min__Fixed_Charge_Coverage)=1 then slack_FIXEDCC = &s; else slack_FIXEDCC = FIXEDCC/Min__Fixed_Charge_Coverage;
	if missing(Min__Debt_Service_Coverage)=1 then slack_DEBTSC = &s; else slack_DEBTSC = DEBTSC/Min__Debt_Service_Coverage;
	if missing(Max__Debt_to_EBITDA)=1 then slack_DEBT2EBITDA = &s; else slack_DEBT2EBITDA = Max__Debt_to_EBITDA/DEBT2EBITDA;
	if missing(Max__Senior_Debt_to_EBITDA)=1 then slack_SRDEBT2EBITDA = &s; else slack_SRDEBT2EBITDA = Max__Senior_Debt_to_EBITDA/SRDEBT2EBITDA;
	if missing(Max__Leverage_ratio)=1 then slack_LEV = &s; else slack_LEV = Max__Leverage_ratio/LEV;
	if missing(Max__Senior_Leverage)=1 then slack_SRLEV = &s; else slack_SRLEV = Max__Senior_Leverage/SRLEV;
	if missing(Max__Debt_to_Tangible_Net_Worth)=1 then slack_DEBT2TNW = &s; else slack_DEBT2TNW = Max__Debt_to_Tangible_Net_Worth/DEBT2TNW;
	if missing(Max__Debt_to_Equity)=1 then slack_DEBT2EQUITY = &s; else slack_DEBT2EQUITY = Max__Debt_to_Equity/DEBT2EQUITY;
	if missing(Min__Current_Ratio)=1 then slack_CRATIO = &s; else slack_CRATIO = CRATIO/Min__Current_Ratio;
	if missing(Min__Quick_Ratio)=1 then slack_QRATIO = &s; else slack_QRATIO = QRATIO/Min__Quick_Ratio;
	if missing(Min__EBITDA)=1 then slack_EBITDA = &s; else slack_EBITDA = EBITDA/(Min__EBITDA/1000000);
	if missing(Net_Worth)=1 then slack_NW = &s; else slack_NW = NW/(Net_Worth/1000000);	
	if missing(Tangible_Net_Worth)=1 then slack_TNW = &s; else slack_TNW = TNW/(Tangible_Net_Worth/1000000);	
	run;

data perm.covslack; set covslack; run;

*	save data in separate loan initiation year files to make simulation easier;
data perm.covslack1995; set perm.covslack;
	if fyearq=1995;
	run;
data perm.covslack1996; set perm.covslack;
	if fyearq=1996;
	run;
data perm.covslack1997; set perm.covslack;
	if fyearq=1997;
	run;
data perm.covslack1998; set perm.covslack;
	if fyearq=1998;
	run;
data perm.covslack1999; set perm.covslack;
	if fyearq=1999;
	run;
data perm.covslack2000; set perm.covslack;
	if fyearq=2000;
	run;
data perm.covslack2001; set perm.covslack;
	if fyearq=2001;
	run;
data perm.covslack2002; set perm.covslack;
	if fyearq=2002;
	run;
data perm.covslack2003; set perm.covslack;
	if fyearq=2003;
	run;
data perm.covslack2004; set perm.covslack;
	if fyearq=2004;
	run;
data perm.covslack2005; set perm.covslack;
	if fyearq=2005;
	run;
data perm.covslack2006; set perm.covslack;
	if fyearq=2006;
	run;
data perm.covslack2007; set perm.covslack;
	if fyearq=2007;
	run;
data perm.covslack2008; set perm.covslack;
	if fyearq=2008;
	run;
data perm.covslack2009; set perm.covslack;
	if fyearq=2009;
	run;
data perm.covslack2010; set perm.covslack;
	if fyearq=2010;
	run;
data perm.covslack2011; set perm.covslack;
	if fyearq=2011;
	run;
data perm.covslack2012; set perm.covslack;
	if fyearq=2012;
	run;
data perm.covslack2013; set perm.covslack;
	if fyearq=2013;
	run;
* note: loan package sample currently ends with fiscal year 2013...straightforward to keep going with additional years of data when available;
