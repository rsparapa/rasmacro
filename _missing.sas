%put NOTE: You have called the macro _MISSING, 2014-11-13.;
%put NOTE: Copyright (c) 2004 Rodney Sparapani;
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

%macro _missing(data=&syslast, log=);

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
 
/*
calls PROC FREQ too many times leading to lots of .log output and slowness
%let scratch=%_scratch;

%do i=1 %to &ncount+&ccount;
    %let var=%scan(&num &char, &i, %str( ));

proc freq data=&data;
    %if &i<=&ncount %then %do;
    format &var missing11.; 
    tables &var / missing noprint out=&scratch(where=(percent=100 & put(&var, missing11.)='Missing'));
    %end;
    %else %do;
    format &var $missing11.; 
    tables &var / missing noprint out=&scratch(where=(percent=100 & put(&var, $missing11.)='Missing'));
    %end;
run;
 
    %let mcount=%_nobs(data=&scratch, notes=);

    %if &mcount=1 %then %let missing=&missing &var;
%end;
*/

%if %length(&missing) %then %do;
data &data;
    set &data;
    drop &missing;
run;
%end;

%if %length(&log) %then %_printto;

%mend _missing;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/
