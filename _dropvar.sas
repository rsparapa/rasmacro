%put NOTE: You have called the macro _DROPVAR, 2015-07-17.;
%put NOTE: Copyright (c) 2014-2015 Rodney Sparapani;
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
    Drop variables that are completely missing.
    
    NAMED Parameters
                
    DATA=_LAST_     default SAS DATASET to use
                        
*/

%macro _DROPVAR(data=&syslast, out=REQUIRED, log=);

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

%local char ccount num ncount missing mcount scratch var;

%let num=%_blist(data=&data, var=_numeric_, nofmt=1);
%let ncount=%_count(&num);

%let char=%_blist(data=&data, var=_character_, nofmt=1);
%let ccount=%_count(&char);

proc freq data=&data;
%do i=1 %to &ncount+&ccount;
    %let var=%scan(&num &char, &i, %str( ));

    %if &i<=&ncount %then %do;
    format &var missing11.; 
    tables &var / missing noprint out=&var(where=(percent=100 & put(&var, missing11.)='Missing'));
    %end;
    %else %do;
    format &var $missing11.; 
    tables &var / missing noprint out=&var(where=(percent=100 & put(&var, $missing11.)='Missing'));
    %end;
%end;
run;

%do i=1 %to &ncount+&ccount;
    %let var=%scan(&num &char, &i, %str( ));

    %let mcount=%_nobs(data=&var, notes=);

    %if &mcount=1 %then %let missing=&missing &var;
%end;
 
%if %length(&missing) %then %do;
data &out;
    set &data;
    drop &missing;
run;
%end;

%if %length(&log) %then %_printto;

%mend _DROPVAR;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/
