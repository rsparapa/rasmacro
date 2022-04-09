%put NOTE: You have called the macro _MISSING, 2022-01-01.;
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

/*  _MISSING Documentation
    Drop variables that are completely missing.
    
    NAMED Parameters
                
    DATA=_LAST_     default SAS DATASET to use

*/

%macro _MISSING(data=&syslast, out=REQUIRED, log=);

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
    char clause count ccount format num ncount nobs missing mcount scratch var;

%let num=%_blist(data=&data, var=_numeric_, nofmt=1);
%let ncount=%_count(&num);

%let char=%_blist(data=&data, var=_character_, nofmt=1);
%let ccount=%_count(&char);

%let var=&num &char;
%let count=%eval(&ccount+&ncount);
%let nobs=%_nobs(data=&data);

%let scratch=%_scratch;

data &scratch;
    point=1;
    set &data point=point;
    output;
    point=&nobs;
    set &data point=point;
    output;
    stop;
run;

proc freq data=&scratch;
%do i=1 %to &count;
    %local var&i;
    %let var&i=%scan(&var, &i, %str( ));
    %if &i<=&ncount %then %let format=missing11.;
    %else %let format=$missing11.;
    format &&var&i &format;
    tables &&var&i / missing noprint
        out=&&var&i(where=(count=2 & put(&&var&i, &format)='Missing'));
%end;
run;

%do i=1 %to &count;
    %let mcount=%_nobs(data=&&var&i, notes=);

    %if &mcount=0 %then %do;
        %if &i<=&ncount %then %let num=%_tranw(&num, &&var&i, %str( ));
        %else %let char=%_tranw(&char, &&var&i, %str( ));
    %end;
%end;
 
%let var=&num &char;
%let ncount=%_count(&num);
%let ccount=%_count(&char);
%let count=%eval(&ccount+&ncount);

%if &count>0 %then %do;

proc freq data=&data;
%do i=1 %to &count;
    %local var&i;
    %let var&i=%scan(&var, &i, %str( ));
    %if &i<=&ncount %then %let format=missing11.;
    %else %let format=$missing11.;
    format &&var&i &format;
    tables &&var&i / missing noprint
        out=&&var&i(where=(count=&nobs & put(&&var&i, &format)='Missing'));
%end;
run;

%do i=1 %to &count;
    %let mcount=%_nobs(data=&&var&i, notes=);

    %if &mcount=1 %then %do;
        %let missing=&missing &&var&i;
        proc print data=&&var&i;
        run;
    %end;
%end;

%end;

data &out;
    set &data;
%if %length(&missing) %then drop &missing;;
run;

%if %length(&log) %then %_printto;

%mend _MISSING;

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

%_missing(data=check, out=check); *drop l and n;
%_missing(data=check, out=check); *drop nothing;
    
*/
