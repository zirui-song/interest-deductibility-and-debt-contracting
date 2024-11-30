/********************************************************************************************/
/* FILENAME:        Step1_CompustatPanel.sas                                                */
/* AUTHOR:          Edward Owens                            					            */
/* PURPOSE:         construct panel of quarterly compustat-based ratio data for use         */ 
/*					in PVIOL simulations;                                                   */
/* INPUT FILES:		Compustat quarterly ("fundq_i"); Compustat annual ("funda_i")           */
/* FILES CREATED:	"matdata"; a series of "matdatatwoYYYY" files                           */                                   */
/********************************************************************************************/

* 	define libraries;
libname perm 'insert path where you store your permanent datasets';
libname comp 'insert path where you store your Compustat data';

*	load file that contains a Winsorization/Truncation macro (used below) - if you don't have such a macro, ignore this and replace the macro call
	below with your preferred truncation approach ;
%include 'C:\MyResearch\GlobalSAS\Macros.sas';

*	Pull Compustat quarterly data used in standard covenant definitions;
* 	note: fundq_i is the standard Compustat fundq dataset, with some cleaning of historical industry identifiers (not a critical step);
data compdata; set comp.fundq_i;
	where (INDFMT= 'INDL' and DATAFMT='STD' and POPSRC='D' and CONSOL='C' and FYEARQ > 1985);
	keep	gvkey sic datadate fyearq fqtr fyr ajexq ajpq datacqtr datafqtr rdq
			OIBDPQ XINTQ INTPNY DLCQ DLTTQ ATQ INTANQ LTQ ACTQ LCTQ RECTQ CHEQ GDWLQ;
	run; 

*	convert all the YTD variables into quarterly observations;
proc sort data=compdata;
	by gvkey fyearq fqtr;
	run;
data compdata; set compdata;
	if lag1(gvkey)=gvkey and lag1(fyearq)=fyearq and lag1(fqtr)=(fqtr-1) then m1=1; else m1=.;
	lag_INTPNY = lag1(INTPNY)*m1;
	lag_DLCQ = lag1(DLCQ)*m1; * need this for fixed charge coverage ratio;
	run;
data compdata; set compdata;
	INTPNY2 = INTPNY-lag_INTPNY;
	run;
data compdata; set compdata;
	if fqtr=1 then INTPNQ=INTPNY; else INTPNQ=INTPNY2;
	run;

* 	obtain needed variables from Compustat annual file:
* 	note: rent and subordinated debt are not on quarterly file;
* 	note: funda_i is the standard Compustat funda dataset, with some cleaning of historical industry identifiers (not a critical step);
data compann; set comp.funda_i;
	where (INDFMT= 'INDL' and DATAFMT='STD' and POPSRC='D' and CONSOL='C' and FYEAR > 1985);
	keep	gvkey datadate fyear XRENT DS OIBDP XINT DLC DLTT AT INTAN LT ACT LCT RECT CHE GDWL PRCC_F CEQ CSHO;
	run; 
proc sort data=compann;
	by gvkey fyear;
	run;
data compann; set compann;
	if lag1(gvkey)=gvkey and lag1(fyear)=(fyear-1) then m1=1; else m1=.;
	if lag2(gvkey)=gvkey and lag2(fyear)=(fyear-2) then m2=1; else m2=.;
	lag_INTAN = lag1(INTAN)*m1;
	lag_XRENT = lag1(XRENT)*m1;
	lag_DS = lag1(DS)*m1;
	lag_RECT = lag1(RECT)*m1;
	lag_OIBDP = lag1(OIBDP)*m1;
	lag_XINT = lag1(XINT)*m1;
	lag_DLC = lag1(DLC)*m1;
	lag2_DLC = lag2(DLC)*m2;
	lag_DLTT = lag1(DLTT)*m1;
	lag_AT = lag1(AT)*m1;
	lag_LT = lag1(LT)*m1;
	lag_ACT = lag1(ACT)*m1;
	lag_LCT = lag1(LCT)*m1;
	lag_CHE = lag1(CHE)*m1;
	lag_GDWL = lag1(GDWL)*m1;
	run;

* merge annual data into the quarterly file;
proc sql;
	create table compdata
	as select a.*, b.XRENT, b.lag_XRENT, b.DS, b.lag_DS, b.RECT, b.lag_RECT, b.INTAN, b.lag_INTAN, b.GDWL, b.lag_GDWL, b.DLC, b.lag_DLC, b.lag2_DLC,
		b.DLTT, b.lag_DLTT, b.AT, b.lag_AT, b.LT, b.lag_LT, b.ACT, b.lag_ACT, b.LCT, b.lag_LCT, b.CHE, b.lag_CHE, b.OIBDP, b.lag_OIBDP, b.XINT, b.lag_XINT,
		b.PRCC_F, b.CEQ, b.CSHO	
	from compdata a left join compann b
	on a.gvkey=b.gvkey and a.fyearq=b.fyear;
	quit; 

data compdata2; set compdata;
	* convert annual items into quarterly values;
	XRENTQ = ((fqtr/4)*XRENT + ((4-fqtr)/4)*lag_XRENT);
	DSQ = ((fqtr/4)*DS + ((4-fqtr)/4)*lag_DS);
	* some balance sheet items are on both files - if missing from quarterly, replace with weighted annual;
	if missing(RECTQ)=0 then RECTQ=RECTQ; else RECTQ = ((fqtr/4)*RECT + ((4-fqtr)/4)*lag_RECT);
	if missing(INTANQ)=0 then INTANQ=INTANQ; else INTANQ = ((fqtr/4)*INTAN + ((4-fqtr)/4)*lag_INTAN);
	if missing(GDWLQ)=0 then GDWLQ=GDWLQ; else GDWLQ = ((fqtr/4)*GDWL + ((4-fqtr)/4)*lag_GDWL);
	if missing(DLCQ)=0 then DLCQ=DLCQ; else DLCQ = ((fqtr/4)*DLC + ((4-fqtr)/4)*lag_DLC);
	if missing(lag_DLCQ)=0 then lag_DLCQ=lag_DLCQ; else lag_DLCQ = ((fqtr/4)*lag_DLC + ((4-fqtr)/4)*lag2_DLC);
	if missing(DLTTQ)=0 then DLTTQ=DLTTQ; else DLTTQ = ((fqtr/4)*DLTT + ((4-fqtr)/4)*lag_DLTT);
	if missing(ATQ)=0 then ATQ=ATQ; else ATQ = ((fqtr/4)*AT + ((4-fqtr)/4)*lag_AT);
	if missing(LTQ)=0 then LTQ=LTQ; else LTQ = ((fqtr/4)*LT + ((4-fqtr)/4)*lag_LT);
	if missing(ACTQ)=0 then ACTQ=ACTQ; else ACTQ = ((fqtr/4)*ACT + ((4-fqtr)/4)*lag_ACT);
	if missing(LCTQ)=0 then LCTQ=LCTQ; else LCTQ = ((fqtr/4)*LCT + ((4-fqtr)/4)*lag_LCT);
	if missing(CHEQ)=0 then CHEQ=CHEQ; else CHEQ = ((fqtr/4)*CHE + ((4-fqtr)/4)*lag_CHE);
	* income/cash flow statement items that are on both files - add an extra q here, then replace after proc expand below;
	OIBDPQQ = ((fqtr/4)*OIBDP + ((4-fqtr)/4)*lag_OIBDP);
	XINTQQ = ((fqtr/4)*XINT + ((4-fqtr)/4)*lag_XINT);
	run;  

*   Use only firm-quarter observations with positive leverage;
data compdata2; set compdata2;
	where (DLCQ>0 or DLTTQ>0);
	run;

*	eliminate duplicate data records;
proc sort data=compdata2 nodupkey;
	by gvkey datadate;
	run; 

*	Set up for proc expand  - need a moving 4 quarter sum for all of the income statement variables;
* 	Create a fiscal quarter date variable for use with proc expand;
data compdata2; set compdata2;
	calmonth = fqtr*3;
data compdata2; set compdata2;
	fdateq = intnx('QTR',mdy(calmonth,1,FYEARQ),0,'END');
data compdata2; set compdata2;
	format fdateq date9.;
	label fdateq = "Fiscal Quarter";
	run;
data compdata2; set compdata2;
	if missing(datadate)=0 and missing(fdateq)=0;
	run; 
proc sort data=compdata2 out=compdata2 nodupkey;
	by gvkey fdateq;
	run;

*	note: if you want to assume that missing values for any of the variables in the proc expand can be replaced with zeroes, 
	now would be the time to impose that assumption - this code does not do so;
proc expand data=compdata2 method=none out=compdata3 from=qtr to=qtr align=end;
   	by gvkey;
    id fdateq;
	convert datadate;
    convert OIBDPQ  = OIBDPQ4 / transformout = (nomiss movsum 4 trimleft 3) method=none;
	convert XINTQ  = XINTQ4 / transformout = (nomiss movsum 4 trim 3) method=none;
	convert INTPNQ  = INTPNQ4 / transformout = (nomiss movsum 4 trim 3) method=none;
	run; 

data compdata4; set compdata3;
	if missing(datadate)=0;
	run; 

*	replacing income/cash flow statement items that are on both files, per above note;
data compdata4; set compdata4;
	if missing(OIBDPQ4)=0 then OIBDPQ4=OIBDPQ4; else OIBDPQ4=OIBDPQQ;
	if missing(XINTQ4)=0 then XINTQ4=XINTQ4; else XINTQ4=XINTQQ;
	run;

*	another decision point here about replacing missing values of certain variables;
data compdata4; set compdata4;
	if missing(XRENTQ)=0 then XRENTQ=XRENTQ; else XRENTQ = 0; * if rent expense missing, replace with zero;
	if missing(INTANQ)=0 then INTANQ=INTANQ; else INTANQ=GDWLQ;* if intangibles missing, replace with goodwill;
	if missing(INTPNQ4)=0 then INTPNQ4=INTPNQ4; else INTPNQ4=XINTQ4; *if interest paid missing, replace with interest expense;
	run;
	
* clean up the dataset;
data compdata4; set compdata4;
	drop lag_INTAN lag_XRENT lag_DS lag_RECT lag_GDWL lag_OIBDP lag_XINT lag_DLC lag2_DLC lag_DLTT
	lag_LT lag_ACT lag_LCT lag_CHE m1;
	run; 

/* Compute covenant standard definitions   */
data matdata; set compdata4;
	INTCOV = OIBDPQ4/XINTQ4;
	CASHINTCOV = OIBDPQ4/INTPNQ4;
	FIXEDCC = OIBDPQ4/(XINTQ4+lag_DLCQ+XRENTQ);
	DEBTSC = OIBDPQ4/(XINTQ4+lag_DLCQ);
	DEBT2EBITDA = (DLTTQ+DLCQ)/OIBDPQ4;
	SRDEBT2EBITDA = (DLTTQ+DLCQ-DSQ)/OIBDPQ4;
	LEV = (DLTTQ+DLCQ)/ATQ;
	SRLEV = (DLTTQ+DLCQ-DSQ)/ATQ;
	DEBT2TNW = (DLTTQ+DLCQ)/(ATQ-LTQ-INTANQ);
	DEBT2EQUITY = (DLTTQ+DLCQ)/(ATQ-LTQ);
	CRATIO = ACTQ/LCTQ;
	QRATIO = (RECTQ+CHEQ)/LCTQ;
	EBITDA = OIBDPQ4;
	NW = ATQ-LTQ;
	TNW = ATQ-LTQ-INTANQ;
	run;

* lag all variables (one quarter lag) for computation of quarter-over-quarter ratio change;
proc sort data=matdata;
	by gvkey fdateq;
data matdata; set  matdata;
    if lag1(gvkey)=(gvkey) then m1=1; else m1 = .;
	lag_INTCOV = lag1(INTCOV)*m1;
	lag_CASHINTCOV = lag1(CASHINTCOV)*m1;
	lag_FIXEDCC = lag1(FIXEDCC)*m1;
	lag_DEBTSC = lag1(DEBTSC)*m1;
	lag_DEBT2EBITDA = lag1(DEBT2EBITDA)*m1;
	lag_SRDEBT2EBITDA = lag1(SRDEBT2EBITDA)*m1;
	lag_LEV = lag1(LEV)*m1;
	lag_SRLEV = lag1(SRLEV)*m1;
	lag_DEBT2TNW = lag1(DEBT2TNW)*m1;
	lag_DEBT2EQUITY = lag1(DEBT2EQUITY)*m1;
	lag_CRATIO = lag1(CRATIO)*m1;
	lag_QRATIO = lag1(QRATIO)*m1;
	lag_EBITDA = lag1(EBITDA)*m1;
	lag_NW = lag1(NW)*m1;
	lag_TNW = lag1(TNW)*m1;
	drop m1;
	run;
* calculate quarter-over-quarter changes (change expressed in ratio form);
data matdata; set matdata;
	d1 = INTCOV/lag_INTCOV;
	d2 = CASHINTCOV/lag_CASHINTCOV;
	d3 = FIXEDCC/lag_FIXEDCC;
	d4 = DEBTSC/lag_DEBTSC;
	d5 = DEBT2EBITDA/lag_DEBT2EBITDA;
	d6 = SRDEBT2EBITDA/lag_SRDEBT2EBITDA; 
	d7 = LEV/lag_LEV;
	d8 = SRLEV/lag_SRLEV;
	d9 = DEBT2TNW/lag_DEBT2TNW;
	d10 = DEBT2EQUITY/lag_DEBT2EQUITY;
	d11 = CRATIO/lag_CRATIO;
	d12 = QRATIO/lag_QRATIO;
	d13 = EBITDA/lag_EBITDA;
	d14 = NW/lag_NW;
	d15 = TNW/lag_TNW;
	run;

*	Setting up for size/BM double-sort groupings;
data matdata; set matdata;
	avg_at = (lag_at+at)/2;
	run;
data matdata; set matdata;
	roa = oibdp/avg_at;
	run;

/* rank by two-way size/roa by year (4 size groups, 3 roa groups within each) */
data matdata; set matdata; 
	if missing(avg_at)=0;
	run; 
proc sort data=matdata;
	by fyearq avg_at;
	run;
proc rank data=matdata groups=4 out=matdata;
	var avg_at;
	ranks quart_at;
	by fyearq;
	run;
proc sort data=matdata;
	by fyearq quart_at roa;
	run;
proc rank data=matdata groups=3 out=matdata;
	var roa;
	ranks rank_sizeroa;
	by fyearq quart_at;
	run;
proc sort data=matdata;
	by fyearq quart_at rank_sizeroa;
	run;
data matdata; set matdata;
	rank_atroa = (10*quart_at)+rank_sizeroa;
	run;

*	note: rank_atroa is the key variable that is later used to match firms for the nonparametric simulation;

/* clean up file */
data matdata; set matdata;
	keep rank_atroa gvkey fdateq datadate fyearq fqtr  
		INTCOV CASHINTCOV FIXEDCC DEBTSC DEBT2EBITDA SRDEBT2EBITDA LEV SRLEV DEBT2TNW DEBT2EQUITY CRATIO QRATIO EBITDA NW TNW /*CAPEX*/ roa btm
		d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15;
	run; 

*	Truncate the ratio change variables at upper and lower 1%, by size/ROA grouping (we use our own macro here - choose your own favorite truncation approach);
%WT(data = matdata, out = matdata, byvar = rank_atroa, vars = d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15,
type = T, pctl = 1 99, drop=n);

*	save to permanent data set;
data perm.matdata; set matdata; run;

*	save data in separate year-range files for rolling 2 year window simulations;
data perm.matdatatwo1995; set perm.matdata;
	if 1993<=fyearq<=1994;
	run;
data perm.matdatatwo1996; set perm.matdata;
	if 1994<=fyearq<=1995;
	run;
data perm.matdatatwo1997; set perm.matdata;
	if 1995<=fyearq<=1996;
	run;
data perm.matdatatwo1998; set perm.matdata;
	if 1996<=fyearq<=1997;
	run;
data perm.matdatatwo1999; set perm.matdata;
	if 1997<=fyearq<=1998;
	run;
data perm.matdatatwo2000; set perm.matdata;
	if 1998<=fyearq<=1999;
	run;
data perm.matdatatwo2001; set perm.matdata;
	if 1999<=fyearq<=2000;
	run;
data perm.matdatatwo2002; set perm.matdata;
	if 2000<=fyearq<=2001;
	run;
data perm.matdatatwo2003; set perm.matdata;
	if 2001<=fyearq<=2002;
	run;
data perm.matdatatwo2004; set perm.matdata;
	if 2002<=fyearq<=2003;
	run;
data perm.matdatatwo2005; set perm.matdata;
	if 2003<=fyearq<=2004;
	run;
data perm.matdatatwo2006; set perm.matdata;
	if 2004<=fyearq<=2005;
	run;
data perm.matdatatwo2007; set perm.matdata;
	if 2005<=fyearq<=2006;
	run;
data perm.matdatatwo2008; set perm.matdata;
	if 2006<=fyearq<=2007;
	run;
data perm.matdatatwo2009; set perm.matdata;
	if 2007<=fyearq<=2008;
	run;
data perm.matdatatwo2010; set perm.matdata;
	if 2008<=fyearq<=2009;
	run;
data perm.matdatatwo2011; set perm.matdata;
	if 2009<=fyearq<=2010;
	run;
data perm.matdatatwo2012; set perm.matdata;
	if 2010<=fyearq<=2011;
	run;
data perm.matdatatwo2013; set perm.matdata;
	if 2011<=fyearq<=2012;
	run;
data perm.matdatatwo2014; set perm.matdata;
	if 2012<=fyearq<=2013;
	run;
data perm.matdatatwo2015; set perm.matdata;
	if 2013<=fyearq<=2014;
	run;
