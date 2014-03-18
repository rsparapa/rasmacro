%put NOTE: You have called the macro _REORDER, 2011-04-20.;
%put NOTE: Copyright (c) 2006-2011 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2006-04-26

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

/*  _REORDER Documentation
    Re-create variables so that their new numeric ordering matches
    their desired formatted ordering.  Based on the _ORDER macro;
    some experimental features that never really worked have been 
    jettisoned, allowing a more simplistic approach to be taken.  
    The original variable label is attached to the re-created 
    variable as you would expect.
            
    REQUIRED Parameters
                
    FORMAT=         format of the original variable VAR=
    
    OUT=            name of SAS DATASET to create
            
    VAR=            variable name to read and re-create 

    Specific OPTIONAL Parameters
                    
    DUMMY=_DUMMY_   the temporary name to use for the new variable
                    which will be RENAMEd VAR=, you will need to
                    change this if you already a have a variable
                    by that name in your SAS DATASET

        
    FMTNAME=VAR_    the name of the format to create for the
                    new variable VAR, defaults to the variable
                    name followed by an underscore
    
    MISSING=_       defaults to largest numeric missing value, 
                    according to character representation, 
                    anything equal to or less than this value results 
                    in a missing value in the re-ordered values;
                    for a character variable use MISSING=%str( )
                    which is the default when ORDER= is left blank
                    
    ORDER=          a list of values separated by the SPLIT=
                    character in the order that you want the new
                    variable to appear; leave it blank if you 
                    want to re-code a character variable as a
                    numeric, but then only non-blank strings
                    are re-coded (see MISSING= above)
                    
    OTHER=Other     default for values that were not specified by ORDER=


    SPLIT=\         defaults to \, see ORDER= above
                    
    Common OPTIONAL Parameters
    
    ATTRIB=
    
    BY=
    
    DROP=
    
    FIRSTOBS=
    
    IF=
    
    KEEP=
    
    LOG=
    
    OBS=
    
    RENAME=
    
    WHERE=                    

    RASMACRO Dependencies
    _COUNT
    _LEVEL
    _PRINTTO
    _REQUIRE
    _SCRATCH, _SORT
*/

%macro _reorder(data=&syslast, format=REQUIRED, out=REQUIRED, var=REQUIRED,  
    dummy=_dummy_, fmtname=%_substr(&var, 1, 7)_, order=, other=Other, split=\, 
    missing=_, /*.\A\B\C\D\E\F\G\H\I\J\K\L\M\N\O\P\Q\R\S\T\U\V\W\X\Y\Z\_,*/ 
    attrib=, by=, firstobs=, drop=, keep=, obs=, rename=, sortedby=, where=, 
    log=);

%_require(&format &out &var);

%if %length(&log) %then %_printto(log=&log);

%_sort(data=&data, out=&out, attrib=&attrib, by=&by, firstobs=&firstobs, drop=&drop,
    keep=&keep, obs=&obs, rename=&rename, sortedby=&sortedby, where=&where);
    
%local i order0 scratch temp string label;

%let scratch=%_scratch;

%if %length(%nrbquote(&order))=0 %then %do;
    data &scratch;
        length &var $ 40;
        set &out;
        keep &var;
    
        &var=put(&var, &format-L);
        
        if &var>" ";
    run;
    
    %_sort(data=&scratch, out=&scratch, by=&var, sort=nodupkey);
    
    %let temp=%_level(data=&scratch, var=&var, split=&split, unique=0)&split &split;
    %let order0=%_count(&temp, split=&split);
                    
    %do i=1 %to &order0;
        %let order=&order.&split.%str(%')%qscan(&temp, &i, ''""&split)%str(%');
    %end;
%end;
%else %do;
    %let temp=&order.&split.&missing.&split;
    %let order0=%_count(&temp, split=&split);
    %let order=;
    
    %do i=1 %to &order0;
        %let order=&order.&split.%str(%')%qscan(&temp, &i, ''""&split)%str(%');
    %end;

    %if &order0<3 %then %do;
        %put ERROR: There must be at least 2 categories.;

        %_abend;
    %end;
%end;
        
%let fmtname=%scan(&fmtname, 1, .);
%let var=%upcase(&var);

data &scratch;
    length start $ 8 label $ 40;
    fmtname="&fmtname";
    
    label="&other ";
    start="0";
    output;

    %do i=1 %to &order0-1;
        label=%scan(&order,&i,&split);
        start="&i";
        output;
    %end;
run;

proc format cntlin=&scratch;
run;

%let fmtname=&fmtname..;
%let data=%sysfunc(open(&out));
%let label=%sysfunc(varlabel(&data, %sysfunc(varnum(&data, &var))));
%let temp=%sysfunc(close(&data));

data &out;
    set &out;
    format &dummy &fmtname;
    drop &var;
    rename &dummy=&var;
    label &dummy="&label ";

    select;

    %do i=1 %to &order0;
	when(
            %if %length(&format) %then put(&var,&format-L);
            %else &var;

            %if &i=&order0 %then <=;
            %else %if %length(&order)<=2*&order0+1 %then =:;
            %else =;

            %scan(&order,&i,&split)) &dummy=
            
            %if &i=&order0 %then .;
            %else &i;
            ;
    %end;

	otherwise &dummy=0;
    end;
run;

%if %length(&log) %then %_printto;
%mend _reorder;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
    
proc format;
    value yesnona
        0='No'
        1='Yes'
        .='N/A'
    ;
run;

data cards;
    input by q a;
    cards;
    1 1 0
    1 1 1
    1 1 .
    1 2 0
    1 2 1
    2 1 0
    ;
run;

data key1(keep=by) key2(keep=by q);
    set cards;
    by by q;
    if first.by then output key1;
    if first.q then output key2;
run;

%_reorder(data=cards, out=one, var=a, order=Yes\No\N/A, format=yesnona., fmtname=_1_.);

proc print data=one;
run;

%_reorder(data=cards, out=two, where=q=1, var=a, order=Yes\No\N/A, format=yesnona., fmtname=_1_.);

proc print data=two;
run;

%_reorder(data=cards, out=three, by=q, var=a, order=Yes\No\N/A, format=yesnona., fmtname=_1_.);

proc print data=three;
run;

%_reorder(data=cards, out=four, by=by q, var=a, order=Yes\No\N/A, format=yesnona., fmtname=_1_.);

proc print data=four;
run;

*from Example 1:  The FORMAT Procedure, SAS Procedures Guide, v. 6, Third Edition;
data nc;
    input zip cstate $ nstate;
    cards;
    27512 NC 37
    53213 WI 55
    ;
run;

proc format;
    value zipst
        27000-28999='North Carolina'
        53000-53999='Wisconsin'
    ;

    value $state
        'NC'='North Carolina'
        'WI'='Wisconsin'
    ;

    value state
        37='North Carolina'
        55='Wisconsin'
    ;
run;

%_reorder(data=nc, out=one1, var=nstate, order=Wisconsin\North Carolina, format=state., fmtname=_1_.);

proc print;
run;

%_reorder(data=nc, out=one2, var=nstate, order="Wisconsin"\"North Carolina", format=state., fmtname=_1_.);

proc print;
run;

%_reorder(data=nc, out=two1, var=cstate, order=Wisconsin\North Carolina, format=$state., fmtname=_1_.);

proc print;
run;

%_reorder(data=nc, out=two2, var=cstate, order='North Carolina'\'Wisconsin', format=$state., fmtname=_1_.);

proc print;
run;
 
%_reorder(data=nc, out=three, var=cstate, format=$state., fmtname=_1_.);

proc print;
run;
    
data tumor;
    input size;
datalines;
1
2
3
.
;
run;

proc format;
    value tumor 
        1='[0, 2]'
        2='(2, 5]'
        3='>5'
    ;
run;

%_reorder(out=size, var=size, format=tumor., order=%str([0, 2]\%(2, 5]\>5\.));

proc print;
run;

*/
