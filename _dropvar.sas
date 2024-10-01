%put NOTE: You have called the macro _DROPVAR, 2022-11-26.;
%put NOTE: Copyright (c) 2014-2022 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2014-11-12

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

/*  _DROPVAR Documentation
    Drop variables that are completely missing or that are always
    the same value (based on their current format if any).
    DEPRECATED: USE _CONSTANT INSTEAD.
    
    NAMED Parameters
                
    DATA=_LAST_     default SAS DATASET to use

    NONMISSING=0    default to check for missing only.  If not 0, then
                    check for non-missing too based on current format.
*/

%macro _DROPVAR(data=&syslast, out=REQUIRED, nonmissing=0, log=);

%put ERROR: _DROPVAR IS DEPRECATED, USE _CONSTANT INSTEAD.;
%_abend;
    
%_require(&out)
    
%if %length(&log) %then %_printto(log=&log);

%let data=%upcase(&data);

proc format;
    value missing
        ._, ., .A-.Z='Missing'
        other='Non-missing'
    ;    

    value $missing
        ' '='Missing'
        other='Non-missing'
    ;
run;

%local i
    char ccount cclause num ncount nclause nobs missing mcount scratch var;

%let num=%_blist(data=&data, var=_numeric_, nofmt=1);
%let ncount=%_count(&num);

%let char=%_blist(data=&data, var=_character_, nofmt=1);
%let ccount=%_count(&char);

%let nobs=%_nobs(data=&data);

%if "&nonmissing"^="0" %then %do;
        %let nclause=count=&nobs;
        %let cclause=count=&nobs;
/* the following two clauses mysteriously stopped working with SAS 9.4 TS1M6
        %let nclause=percent=100;
        %let cclause=percent=100;
*/
%end;
    
proc freq data=&data;
%do i=1 %to &ncount+&ccount;
    %let var=%scan(&num &char, &i, %str( ));

    %if "&nonmissing"="0" %then %do;
        %let nclause=count=&nobs & put(&var,  missing11.)='Missing';
        %let cclause=count=&nobs & put(&var, $missing11.)='Missing';
/* the following two clauses mysteriously stopped working with SAS 9.4 TS1M6
        %let nclause=percent=100 & put(&var,  missing11.)='Missing';
        %let cclause=percent=100 & put(&var, $missing11.)='Missing';
*/
    %end;

    %if &i<=&ncount %then %do;
    %if "&nonmissing"="0" %then format &var missing11.;; 
    tables &var / missing noprint out=&var(where=(&nclause));
    %end;
    %else %do;
    %if "&nonmissing"="0" %then format &var $missing11.;; 
    tables &var / missing noprint out=&var(where=(&cclause));
    %end;
%end;
run;

%do i=1 %to &ncount+&ccount;
    %let var=%scan(&num &char, &i, %str( ));

    %let mcount=%_nobs(data=&var, notes=);

    %if &mcount=1 %then %do;
        %let missing=&missing &var;
        proc print data=&var;
        run;
    %end;
%end;
 
%*if %length(&missing) %then %do;
data &out;
    set &data;
%if %length(&missing) %then 
    drop &missing;;
run;
%*end;

%if %length(&log) %then %_printto;

%mend _DROPVAR;

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

%_dropvar(data=check, out=missing); *drop l and n;
    
%_dropvar(data=check, out=nonmissing, nonmissing=); *also drop m and q;
*/
