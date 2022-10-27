%put NOTE: You have called the macro _CONSTANT, 2022-10-24.;
%put NOTE: Copyright (c) 2021-2022 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2021-12-30

This file is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This file is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this file; see the file COPYING.  If not, write to
the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
*/

/*  _CONSTANT Documentation
    Drop variables that are always the same value
    (based on their current format if any).
    N.B. if a variable is all missing it is also dropped.
    Similarly, if a variable is a non-missing constant
    and missing values exist it is also dropped accordingly.
    
    NAMED Parameters
                
    DATA=_LAST_     default SAS DATASET to use

    DEBUG=0         set to anything else to see .lst output

    OBS=100         in the first pass, we use only the first
                    OBS observations: this speeds up the
                    second pass for large data sets

    VAR=_ALL_       by default, check all variables

*/

%macro _constant(data=&syslast, out=REQUIRED, var=_all_,
    debug=0, obs=100, log=);

%_require(&out)
    
%if %length(&log) %then %_printto(log=&log);

%let data=%upcase(&data);

%if &debug=0 %then %let debug=noprint;
%else %let debug=;

%local h i j count list nobs scratch;

%let list=%_blist(data=&data, var=&var, nofmt=1);
%let count=%_count(&list);

%let scratch=%_scratch;

data &scratch;
    set _null_;
    count=.;
    percent=.;
run;

%let nobs=%_nobs(data=&data);

%if &count>0 %then %do h=1 %to 2;
    %if &h=1 %then %do;
        %if &nobs<&obs %then %let obs=&nobs;
        options obs=&obs;
    %end;
    %else %do;
        %let count=%_count(&list);
        %let obs=&nobs;
        options obs=max;
    %end;

    %if &count>0 %then %do;
    proc freq data=&data;
        %do i=1 %to &count;
            %local var&i;
            %let var&i=%scan(&list, &i, %str( ));
            tables &&var&i / &debug out=&&var&i(where=(percent=100 | count=&obs));
        %end;
    run;

        %do i=1 %to &count;
            %let j=%_nobs(data=&&var&i, notes=);
            %if &j=0 %then %let list=%_tranw(&list, &&var&i, %str( ));
            %else %if &h=2 %then %do;
                    data &scratch;
                        set &scratch &&var&i;
                    run;
            %end;
        %end;
    %end;
%end;

proc print data=&scratch;
run;

data &out;
    set &data;
%if %_count(&list)>0 %then drop &list;;
run;

%if %length(&log) %then %_printto;

%mend _constant;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
data check;
    do i=1 to 10;
        j=i;
        k=i**2;
        l=.;
        m=1;
        n=' ';
        o=put(i, 2.);
        q='a';
        
        output;
    end;
run;

%_constant(data=check, out=check); *drop l n m q;

%_constant(data=check, out=check); *drop nothing;

*/
