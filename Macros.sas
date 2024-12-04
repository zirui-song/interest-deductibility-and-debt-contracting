%macro WT(data=, out=, byvar=, vars=, type=T, pctl=1 99, drop=n);
    /* Step 1: Create a dataset for storing percentile thresholds */
    proc sort data=&data out=sorted_data;
        by &byvar;
    run;

    proc univariate data=sorted_data noprint;
        by &byvar;
        var &vars;
        output out=percentiles
            pctlpts=&pctl
            pctlpre=P;
    run;

    /* Step 2: Merge the percentiles back into the original data */
    data &out;
        merge sorted_data percentiles;
        by &byvar;
        
        /* Step 3: Truncate (Winsorize) each variable */
        %let var_list = %sysfunc(tranwrd(&vars, %str( ), %str(,)));
        %let num_vars = %sysfunc(countw(&vars, %str( )));
        
        %do i = 1 %to &num_vars;
            %let var = %scan(&vars, &i);
            %let PctlLow = P&var&low;
            %let PctlHigh = P&var&high;
            
            /* Truncate variable to upper and lower bounds */
            if &var < P1_&var then &var = P1_&var;
            if &var > P99_&var then &var = P99_&var;
        %end;
    run;
%mend WT;