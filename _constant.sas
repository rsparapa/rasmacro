%put NOTE: You have called the macro _CONSTANT, 2022-01-03.;
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
    
    NAMED Parameters
                
    DATA=_LAST_     default SAS DATASET to use

*/

%macro _constant(data=&syslast, out=REQUIRED, log=);

%_require(&out)
    
%if %length(&log) %then %_printto(log=&log);

%let data=%upcase(&data);

%local i j count list scratch;

%let list=%_blist(data=&data, var=_all_, nofmt=1);
%let count=%_count(&list);
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
    %let var&i=%scan(&list, &i, %str( ));
    tables &&var&i / noprint out=&&var&i(where=(count=2));
%end;
run;

%do i=1 %to &count;
    %let j=%_nobs(data=&&var&i, notes=);
    %if &j=0 %then %let list=%_tranw(&list, &&var&i, %str( ));
%end;
 
%let count=%_count(&list);

%if &count>0 %then %do;
proc freq data=&data;
    %do i=1 %to &count;
        %let var&i=%scan(&list, &i, %str( ));
        tables &&var&i / noprint out=&&var&i(where=(count=&nobs));
    %end;
run;

%do i=1 %to &count;
    %let j=%_nobs(data=&&var&i, notes=);
    %if &j=0 %then %let list=%_tranw(&list, &&var&i, %str( ));
    %else %do;
proc print data=&&var&i;
run;
    %end;
%end;
%end;

%*let list=%left(%trim(&list));

/*
%if %_count(&list)>0 %then %do;
data scratch;
    merge &list;
run;

proc print data=&scratch;
run;
%end;
*/

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
