/********************************************************************************************/
/* FILENAME:        Step3_CalculatePVIOL.sas                                                      */
/* AUTHOR:          Edward Owens                            					            */
/* PURPOSE:         compute probability of covenant violation for dealscan packages         */
/* FILES USED:		matdatatwoYYYY (from Step 1); covslackYYYY (from Step 2)                */
/* KEY FILES MADE:	PVIOL                                                                   */
/********************************************************************************************/

*	define libraries;
libname perm 'insert path where you store your permanent datasets';
* note: the worktemp library helps with the operation of the simulation...helps with SAS processing glitches;
libname worktemp 'insert path where you store your Compustat data' filelockwait=30;

* NOTE: before running, delete all files out of the worktemp library;
%MACRO iterate;

%DO j=1995 %TO 2013;
data worktemp.covslack&j; set perm.covslack&j;
	drop Max__Capex Max__Loan_to_Value; /* these covenants aren't included in the measure*/
	run; 

*	delete all observations without full slack data (which means accounting data were missing);
data worktemp.covslack&j; set worktemp.covslack&j;
	array toot(*) slack_INTCOV slack_CASHINTCOV slack_FIXEDCC slack_DEBTSC slack_DEBT2EBITDA slack_SRDEBT2EBITDA slack_LEV slack_SRLEV slack_DEBT2TNW 
					slack_DEBT2EQUITY slack_CRATIO slack_QRATIO slack_EBITDA slack_NW slack_TNW;
	do i=1 to dim(toot);
		if missing(toot(i))=1 then delete;
		end;
	drop i;
	run; 

*	note: not deleting observations already in violation of covenant at loan inception, or with negative slack data...no need to, conceptually;

data worktemp.covslack&j; set worktemp.covslack&j; 
	if missing(rank_atroa)=0; /* recall that rank_atroa was created in the Step 1 program - here is where it is used */
	run; 

*	bring in panel data file (from Step 1) used to draw nonparametric vectors;
data worktemp.matdata&j; set perm.matdatatwo&j; run; 

* delete missings to set up panel from which simulation draws will be taken;
data worktemp.matdata&j; set worktemp.matdata&j;
	array toot(*) d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15;
	do i=1 to dim(toot);
		if missing(toot(i))=1 then delete;
		end;
	drop i;
	run; 

* now, with covslack file and matdata file in place, can compute PVIOL;  
proc sort data=worktemp.matdata&j;
	by rank_atroa;
	run;
*	randomly draw realized data vectors (from matdata) from firms in the same size/performance bin as the borrower:;
proc surveyselect data=worktemp.matdata&j out=worktemp.nonparviol&j method = urs n = (1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000
	1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000) seed = 1234 outhits;
	strata rank_atroa;
	run;

proc sql;
	create table worktemp.covslack&j
	as select a.*, b.rank_atroa as brank_atroa, b.d1 as bd1, b.d2 as bd2, b.d3 as bd3, b.d4 as bd4, b.d5 as bd5, b.d6 as bd6, b.d7 as bd7, b.d8 as bd8, 
					b.d9 as bd9, b.d10 as bd10, b.d11 as bd11, b.d12 as bd12, b.d13 as bd13, b.d14 as bd14, b.d15 as bd15
	from worktemp.covslack&j a left join worktemp.nonparviol&j b
	on a.rank_atroa=b.rank_atroa;
	quit;

data worktemp.covslack&j; set worktemp.covslack&j;
	keep PackageID BorrowerCompanyID DealActiveDate gvkey fdateq datadate
		INTCOV CASHINTCOV FIXEDCC DEBTSC DEBT2EBITDA SRDEBT2EBITDA LEV SRLEV DEBT2TNW DEBT2EQUITY CRATIO QRATIO EBITDA NW TNW
		slack_INTCOV slack_CASHINTCOV slack_FIXEDCC slack_DEBTSC slack_DEBT2EBITDA slack_SRDEBT2EBITDA slack_LEV slack_SRLEV slack_DEBT2TNW 
		slack_DEBT2EQUITY slack_CRATIO slack_QRATIO slack_EBITDA slack_NW slack_TNW bd1 bd2 bd3 bd4 bd5 bd6 bd7 bd8 bd9 bd10 bd11 bd12 bd13 bd14 bd15;
		run; 

* create individual covenant violation indicators;
data worktemp.covslack&j; set worktemp.covslack&j;
	v_INTCOV = (slack_INTCOV*bd1 < 1);
	v_CASHINTCOV = (slack_CASHINTCOV*bd2 < 1);
	v_FIXEDCC = (slack_FIXEDCC*bd3 < 1);
	v_DEBTSC = (slack_DEBTSC*bd4 < 1);
	v_DEBT2EBITDA = (slack_DEBT2EBITDA/bd5 < 1);
	v_SRDEBT2EBITDA = (slack_SRDEBT2EBITDA/bd6 < 1);
	v_LEV = (slack_LEV/bd7 < 1);
	v_SRLEV = (slack_SRLEV/bd8 < 1);
	v_DEBT2TNW = (slack_DEBT2TNW/bd9 < 1);
	v_DEBT2EQUITY = (slack_DEBT2EQUITY/bd10 < 1);
	v_CRATIO = (slack_CRATIO*bd11 < 1);
	v_QRATIO = (slack_QRATIO*bd12 < 1);
	v_EBITDA = (slack_EBITDA*bd13 < 1);
	v_NW = (slack_NW*bd14 < 1);
	v_TNW = (slack_TNW*bd15 < 1);
	run;
  
/* doublecheck that no violation will be indicated where the covenant does not exist */
%let s = 9999999999999999999;
data worktemp.covslack&j; set worktemp.covslack&j;
	array slac(*) slack_INTCOV slack_CASHINTCOV slack_FIXEDCC slack_DEBTSC slack_DEBT2EBITDA slack_SRDEBT2EBITDA slack_LEV slack_SRLEV slack_DEBT2TNW 
		slack_DEBT2EQUITY slack_CRATIO slack_QRATIO slack_EBITDA slack_NW slack_TNW;	
	array viol(*) v_INTCOV v_CASHINTCOV v_FIXEDCC v_DEBTSC v_DEBT2EBITDA v_SRDEBT2EBITDA v_LEV v_SRLEV v_DEBT2TNW 
		v_DEBT2EQUITY v_CRATIO v_QRATIO v_EBITDA v_NW v_TNW;	
	do i=1 to dim(slac);
		if slac(i)=&s then viol(i)=0;
		end;
	drop i;
	run;

* calculate the proportion of the 1,000 draws where a covenant violation is indicated;
proc sql;
	create table worktemp.covslack2&j
  	as select packageid, 
            sum(v_INTCOV=1 or v_CASHINTCOV=1 or v_FIXEDCC=1 or v_DEBTSC=1 or v_DEBT2EBITDA=1 or v_SRDEBT2EBITDA=1 or v_LEV=1 or v_SRLEV=1 or v_DEBT2TNW=1 or 
		v_DEBT2EQUITY=1 or v_CRATIO=1 or v_QRATIO=1 or v_EBITDA=1 or v_NW=1 or v_TNW=1)/1000 as PVIOL,
			sum(v_INTCOV=1 or v_CASHINTCOV=1 or v_FIXEDCC=1 or v_DEBTSC=1 or v_DEBT2EBITDA=1 or v_SRDEBT2EBITDA=1 or v_EBITDA=1)/1000 as PVIOL_PCOV,
			sum(v_LEV=1 or v_SRLEV=1 or v_DEBT2TNW=1 or	v_DEBT2EQUITY=1 or v_CRATIO=1 or v_QRATIO=1 or v_NW=1 or v_TNW=1)/1000 as PVIOL_CCOV
   	from worktemp.covslack&j
   	group by packageid;
   	quit; 

proc append base=worktemp.pviolfile data=worktemp.covslack2&j; quit;

proc datasets library=worktemp nolist;
	delete covslack&j covslack2&j matdata&j nonparviol&j;
	quit;

%END;
%MEND;

%iterate;

* save measures to permanent data set;
data perm.PVIOL; set worktemp.pviolfile; run;
