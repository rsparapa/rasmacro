%put NOTE: You have called the macro _DROPOBS, 2016-09-09.;
%put NOTE: Copyright (c) 2015-2016 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2015-06-30

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

/*  _DROPOBS Documentation
    Drop observations for variables that are occasionally missing.
    
    NAMED Parameters
                
    DATA=_LAST_     default SAS DATASET to use

    FREQ=noprint    default to not printing PROC FREQ output

    IGNORE=         ignore the missingness of these variables
                        
*/

%macro _DROPOBS(data=&syslast, out=REQUIRED, freq=noprint,
    ignore=, log=);

%_require(&out)
    
%if %length(&log) %then %_printto(log=&log);

%*let data=%upcase(&data);
%let ignore=%lowcase(&ignore);
    
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

%local char ccount num ncount missing mcount scratch var;

%let num=%_blist(data=&data, var=_numeric_, nofmt=1);
%let char=%_blist(data=&data, var=_character_, nofmt=1);

%do i=1 %to %_count(&ignore);
    %let var=%scan(&ignore, &i, %str( ));
    %let num=%_tranwrd(&num, &var, %str( ));
    %let char=%_tranwrd(&char, &var, %str( ));
%end;

%let ncount=%_count(&num);
%let ccount=%_count(&char);

proc freq data=&data;
%do i=1 %to &ncount+&ccount;
    %let var=%scan(&num &char, &i, %str( ));

    %if &i<=&ncount %then %do;
    format &var missing11.; 
    tables &var / missing &freq out=&var(where=(percent>0 & put(&var, missing11.)='Missing'));
    %end;
    %else %do;
    format &var $missing11.; 
    tables &var / missing &freq out=&var(where=(percent>0 & put(&var, $missing11.)='Missing'));
    %end;
%end;
run;

%let mtotal=0;
%let missing=0;

%do i=1 %to &ncount+&ccount;
    %let var=%scan(&num &char, &i, %str( ));

    %let mcount=%_nobs(data=&var, notes=);

    %if &mcount=1 %then %do;
        %let mtotal=%eval(&mtotal+1);
        %let missing=&missing,&var;
    %end;
%end;
 
%if %length(&log) %then %_printto;

%put Number of variables: %eval(&ncount+&ccount);
%put Number with missing obs: &mtotal;

data &out(drop=_missing_) missing;
    set &data;
    %if &mtotal>0 %then _missing_=nmiss(&missing);
    %else _missing_=0;;

    if _missing_ then output missing;
    else output &out;
run;

proc freq data=missing;
    tables _missing_;
run;

%let syslast=&out;

%mend _DROPOBS;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/
