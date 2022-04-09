%put NOTE: You have called the macro _REDCAP, 2021-09-08.;
%put NOTE: Copyright (c) 2021 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2021-08-19

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

%macro _redcap(data=&syslast, var=REQUIRED, prefix=No, library=library,
    attrib=, by=, firstobs=, drop=, keep=, obs=, rename=, sortedby=, where=, log=);

%_require(&var);

%if %length(&log) %then %_printto(log=&log);

%let list=%_blist(var=&var, data=&data);
%let vars=%_blist(var=&var, data=&data, nofmt=1);

data cntlin;
    length fmtname $ 32 label $ 256;
    set &data(keep=&vars);
    keep fmtname label type start end;
    retain type 'n';
    if _n_=1 then do;
%do i=1 %to %_count(&list);
    %let fmt=%scan(&list, &i, %str( ));
    %let j=%_indexc(&fmt, .);
    %if &j %then %do;
        %put VAR=&var FMT=&fmt;
        fmtname="%_substr(&fmt, 1, &j-1)";
        call label(&var, label);
        label=scan(label, 2, ':()');
        start=1;
        end=1;
        output;
        label="&prefix "||label;
        start=0;
        end=0;
        output;
    %end;
    %else %do;
        %let var=&fmt;
        %let fmt=;
    %end;
%end;
    end;
    stop;
run;

proc format cntlin=cntlin library=&library;
run;

%if %length(&log) %then %_printto;

%mend _redcap;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/
