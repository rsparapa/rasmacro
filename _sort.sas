%put NOTE: You have called the macro _SORT, 2016-11-16;
%put NOTE: Copyright (c) 2001-2016 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2001-00-00

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
    
/*  _SORT Documentation
    This SAS Macro is designed to be the first SAS Macro called
    by other SAS Macros that deal with SAS DATASETs; specifically
    it handles all of the Common OPTIONAL Parameters documented
    below.  However, it doesn't PROC SORT the SAS DATASET unless
    it is necessary so the name is a little misleading.
    
    REQUIRED Parameters
    
    OUT=            the SAS DATASET to be created
                
    NAMED Parameters
    
    DATA=_LAST_     default SAS DATASET to be used
                    
    Common OPTIONAL Parameters
    
    ATTRIB=         SAS ATTRIB Statement
        
    BY=             list of variables to sort by, no sort if blank
                    
    DROP=           SAS DATASET Option
    
    END=            Name of the END= variable, no default
                    
    FIRSTOBS=       SAS DATASET Option
                    
    IF=             IF statement, useful for subsetting when a WHERE=
                    clause will not due, i.e. with FIRST. or LAST.
                    variables
                    
    INDEX=          SAS DATASET Option, outermost paretheses not allowed?
    
    KEEP=           SAS DATASET Option
    
    LOG=            file or device to re-direct the .log to,
                    quotes allowed but unnecessary
                    
    OBS=            SAS DATASET Option
                    
    RENAME=         SAS DATASET Option, paretheses allowed
                    but unnecessary
    
    SORT=           options passed to the PROC SORT statement
                    
    SORTEDBY=BY     SAS DATASET Option, defaults to BY

    SORTSEQ=        PROC SORT Option specified here that otherwise
                    would require a SORT= and a SORTEDBY=, for example
                    SORTSEQ=EBCDIC is equivalent to SORT=SORTSEQ=EBCDIC 
                    and SORTEDBY=&BY/EBCDIC

    WHERE=          SAS DATASET Option, outermost paretheses allowed
                    but unnecessary
*/

%macro _sort(data=&syslast, out=REQUIRED, testsort=0, attrib=, by=, drop=, 
    end=, firstobs=, if=, index=, keep=, obs=, rename=, sort=, sortedby=&by, 
    sortseq=, where=, log=);
    
%_require(&out);

%if %length(&log) %then %_printto(log=&log);
    
%local i outopt output;

%let outopt=%_option(&out);
%if %length(&index)    %then %let outopt=&outopt index=(&index);

%let sortseq=%upcase(&sortseq);

%if "&sortseq "^=" " %then %let sort=&sort SORTSEQ=&sortseq;

%if %length(&sortedby) %then %do;
    %if "&sortseq "="ASCII " | "&sortseq "="EBCDIC " %then %let sortedby=&sortedby/&sortseq;
    %let outopt=&outopt sortedby=&sortedby;
%end;

/*
%if %length(&sortedby) %then %do;
    %let sortedby=&sortedby%_ifelse("&sortseq"="ASCII" | "&sortseq"="EBCDIC",/&sortseq);
    %let outopt=&outopt sortedby=&sortedby;
%end;
*/

%let out=%_lib(&out).%_data(&out);
%let outopt=&out (&outopt);

%if %length(&if) %then %let output=&out;
%else %do;
    %*Occasionally, there is a problem with PROC SORT when OUT=DATAn 
    (a temporary dataset provided by %_SCRATCH).  Usually, the intent 
    in these cases is to also specify SORT=NODUPKEY.  Fortunately, 
    there is a work around for this scenario:  SORT=NODUP and IF=FIRST...;
    %if %length(&by) & %index(&out, work.data) %then %do;
        %do i=1 %to %_count(&sort);
            %let if=%scan(&sort, &i, %str( ));
        
            %if "&if"="NODUPKEY" %then %let if=NODUP;
        
            %let output=&output &if;
        %end;

        %let sort=&output;
        %let if=%_first(&by);
    %end;
    
    %let output=&outopt;
%end;
        
%if %length(&by) %then %do;
    %if &testsort %then %do;
        %if &syscc %then %_abend;
    
        data _null_;
            set %_lib(&data).%_data(&data) ( %_option(&data)
                %if %length(&firstobs) %then firstobs=&firstobs;
                %if %length(&drop)     %then drop=&drop;
                %if %length(&keep)     %then keep=&keep;
                %if %length(&obs)      %then obs=&obs;
                %if %length(&rename)   %then rename=(%scan((&rename), 1, ()));
                %if %length(&where)    %then where=(&where);
            );

            by %_by(&by, proc=1);
        run;
    
        %if &syscc %then %do;
            %let syscc=0;
    
            proc sort &sort out=&output data=
        %end;
        %else %do;
            data &outopt;
                set
        %end;
    %end;
    %else proc sort &sort out=&output data=;
%end;
%else %do;
    data &output;
	set
%end;

%_lib(&data).%_data(&data) ( %_option(&data)
    %if %length(&firstobs) %then firstobs=&firstobs;
    %if %length(&drop)     %then drop=&drop;
    %if %length(&keep)     %then keep=&keep;
    %if %length(&obs)      %then obs=&obs;
    %if %length(&rename)   %then rename=(%scan((&rename), 1, ()));
    %if %length(&where)    %then where=(&where);
);

    by %_by(&by, proc=1);
run;

%if %length(&if) | %length(&attrib) %then %do;
    data &outopt;
        attrib &attrib;
        set &out %if %length(&end) %then end=&end;;
        by &by;
        %if %length(&if) %then if &if;;
    run;
%end;

%if %length(&log) %then %_printto;
%mend _sort;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

*Based on Example 1 for PROC TRANSPOSE;
*SAS Procedures Guide, pp. 609-610;

options ls=80 ps=60 frmdlim='-' nodate;

data f(index=(c));
input a b c;
cards;
1 4 3
2 3 6
3 2 9
4 1 12
;
run;

proc print data=f;
title 'Before %_EXAMPLE';
run;

%_sort(data=f, out=f, by=b, sort=force);
%_sort(data=f, out=f, by=b);
%_sort(data=f (where=(b)) , if=1;d=a+b, attrib=a format=5.2 label="A+", out=ftransp, by=b);

proc print label data=ftransp;
title 'After Calling %_EXAMPLE Once';
run;

%_sort(data=ftransp, out=dbltrans);

proc print label data=dbltrans;
title 'After Calling %_EXAMPLE Twice';
run;

%_sort(data=dbltrans, out=dbltrans, rename=d=e);

proc print label data=dbltrans;
title 'RENAME Test';
run;

%_sort(data=dbltrans, out=dbltrans, rename=(e=f));

proc print label data=dbltrans;
title 'RENAME Test';
run;

*/
