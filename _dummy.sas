%put NOTE: You have called the macro _DUMMY, 2006-01-30.;
%put NOTE: Copyright (c) 2001-2006 Rodney Sparapani;
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

/*  _DUMMY Documentation
    Make dummy variables.  A GLOBAL SAS Macro variable is created
    which is the same name as the DATASTEP variable that contains 
    a list of the dummy variables, i.e. DATASTEP DUMMY creates
    GLOBAL DUMMY=DUMMY0-DUMMY# where # is the number of different
    values that DUMMY takes and 0 is for missingness (see MISSING=
    below).
    
    REQUIRED Parameters
    
    OUT=            name of SAS DATASET to create
            
    VAR=            list of variables to create dummies for,
                    one set of dummies for each variable
                
    Specific OPTIONAL Parameters
    
    COMPARE==       by default, each possible value has its
                    own dummy, this can be changed, for
                    example STEP=1 sets COMPARE=>=
                                            
    DATA=_LAST_     SAS DATASET to use, defaults to _LAST_
                    
    INT=1           sets the first sorted value to be the
                    intercept by default, INT=2 to change to
                    the second sorted value, etc.  INT= uses
                    the last sorted value
                                            
    MISSING=GLM     by default, a missing value is considered
                    dummy category 0, 
                    MISSING=MISSING results in all dummy categories
                    being missing for missing values
                    MISSING=EFFECT results in all dummy categories
                    being -1 for missing values
    
    PARAM=GLM       by default, GLM coding is performed,
                    PARAM=EFFECT specifies EFFECT coding with
                    the INT= setting which cannot be over-ridden
    
    STEP=0          see COMPARE=
    
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
*/

%macro _dummy(data=&syslast, out=REQUIRED, var=REQUIRED, compare==, 
    int=1, missing=GLM, param=GLM, step=0, attrib=, by=, drop=, firstobs=, if=, 
    keep=, obs=, rename=, where=, log=);

    %_require(&var &out);
    %if %length(&log) %then %_printto(log=&log);
    %local i j k h var0 list0;
    %let missing=%upcase(&missing);
    %let param=%upcase(&param);

    %if "&param"="EFFECT" %then %let int=;
    
    %let out=%upcase(&out);
    %let var=%upcase(&var);
    %let var0=%_count(&var);
    %if &step %then %let compare=>=;

    %_sort(data=&data, out=&out, attrib=&attrib, by=&by, drop=&drop,
	firstobs=&firstobs, if=&if, keep=&keep, obs=&obs, rename=&rename,
        where=&where);

    %do i=1 %to &var0;
        %local var&i list&i data&i;
        %let var&i=%scan(&var, &i, %str( ));
        %let data&i=%_scratch(data=work);

        %_sort(data=&out, out=&&data&i, by=&&var&i, keep=&&var&i, sort=nodupkey);

        %let list&i=%_level(var=&&var&i);
    %end;

    data &out;
        set &out;

        %do i=1 %to &var0;
            %global &&var&i;
            %let var=;

            %let list0=%_count(&&list&i, split=\);
            %if %length(&int)=0 %then %let int=&list0;
            %let h=0;
            
            %do j=1 %to &list0;
                %let list=%bquote(%scan(&&list&i, &j, \));

                %if "&list"^=" " & "&list"^="." %then %do;
                    %let h=%eval(&h+1);
                    
                    %if &h^=&int %then %let var=&var &&var&i..&h;
                    
                if &&var&i>' ' then do;
                    &&var&i..0=0;
                    
                    &&var&i..&h=(&&var&i..&compare"&list");
                    
                    %if &h=&int & "&param"="EFFECT" %then %do k=1 %to &h-1;
                        if &&var&i..&h then &&var&i..&k=-1;
                    %end;

                    %if "&list">"A" %then %do;
                        %let k=%_indexc(&list, ''"");

                        %if &k %then %scan(&list, 1, ''"")_%scan(&list, 2, ''"")=&&var&i..&h;
                        %else %_substr(&list, 1, 8)=&&var&i..&h;;
                    %end;
                end;
                %if "&missing"="GLM" %then %do;
                else do;
                    &&var&i..&h=0;
                    &&var&i..0=1;
                end;
                %end;
                %else %if "&missing"="EFFECT" %then %do;
                else do;
                    &&var&i..&h=-1;
                    &&var&i..0=1;
                end;
                %end;
            
                label &&var&i..&h="&&var&i..&compare.&list";
                %end;
            %end;

            %if &int=&list0 %then %let int=;
            
            %if "&missing"="MISSING" %then %do;
                %let &&var&i=&var;
                drop &&var&i..0;
            %end;
            %else %do;
                %let &&var&i=&var &&var&i..0;
                label &&var&i..0="nmiss(&&var&i)";
            %end;
                
            %put NOTE:  &&var&i=%superq(&&var&i);
        %end;
    run;

%if %length(&log) %then %_printto;

%mend _dummy;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

*Example 10.1 (The GLMMOD Procedure, SAS Technical Report P-229, pg. 193;

data plants;
input type $ @;
infile cards missover;

do block=1 to 3;
	input stem @;
	output;
end;

cards;
clarion 32.7 32.3 31.5
clinton 32.1 29.7 29.1
knox    35.7 35.9 33.1
o'neill 36.0 34.2 31.2
compost 31.8 28.0 29.2
wabash  38.2 37.8 31.9
webster 32.5 31.1 29.7
;
run;

%_dummy(data=plants, out=nomiss, var=block type);

title 'GLM Coding';
proc print label;
run;
                    
%_dummy(data=plants, out=nomiss, param=effect, var=block type);

title 'EFFECT Coding';
proc print label;
run;
endsas;
data plants;
    set plants;
    if block=3 then block=.;
run;

%_dummy(data=plants, out=glm, var=block);

proc print label;
    var block:;
    title 'GLM coding';
run;

%_dummy(data=plants, out=effect, missing=effect, var=block);

proc print label;
    var block:;
    title 'EFFECT coding';
run;
    
%_dummy(data=plants, out=missing, missing=missing, var=block);

proc print label;
    var block:;
    title 'Case-deletion coding';
run;

*/
