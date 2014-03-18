%put NOTE: You have called the macro _LEVEL, 2011-09-01.;
%put NOTE: Copyright (c) 2002-2011 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2002-00-00

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

/*  _LEVEL Documentation
    Create a list of values from a variable in each observation of
    a SAS DATASET.  Note that character variables that contain
    macro symbols should not cause any troubled since this macro
    has been hardened; see the example below.
    
    REQUIRED Parameters
    
    VAR=            variable name to create list from
    
    NAMED Parameters
                
    DATA=_LAST_     default SAS DATASET to use
                        
    FORMAT=         only used if specified, no default
                    
    NOTES=          default is to not display the returned value in a NOTE,
                    if set to something, then do display
    
    SPLIT=\         the split character separating the items,
                    defaults to \
                    
    UNIQUE=1        default is to produce a list of unique items
                    (the SAS DATASET should be unique prior to 
                    calling this SAS Macro for performance reasons),
                    to produce a list of non-unique items, set UNIQUE=0
*/  
    
%macro _level(data=&syslast, var=REQUIRED, format=, split=\, unique=1, notes=);
    %_require(&var)

    %local nobs i j k rc type item list;

    %let list=&split;

    %let nobs=%_nobs(data=&data, notes=&notes);

    %if &nobs %then %do;
        %let data=%sysfunc(open(&data));
        %let var=%sysfunc(varnum(&data, &var));
        %let type=%sysfunc(vartype(&data, &var));

        %if &var %then %do;
            %do i=1 %to &nobs;
                %let rc=%sysfunc(fetchobs(&data, &i));

                %let item=%qtrim(%nrbquote(%qsysfunc(getvar&type(&data, &var))));
                
                %if %length(&format) %then 
                    %let item=%qsysfunc(put&type(&item, &format));
/*
                %if &unique=0 %then %let list=%nrbquote(&list)%nrbquote(&item)&split;
                %else %if %index(%nrbquote(&list), &split%nrbquote(&item)&split)=0 %then 
                    %let list=%nrbquote(&list)%nrbquote(&item)&split;
*/

                %if &unique=0 %then %let list=&list.&item.&split;
                %else %if %index(&list, &split.&item.&split)=0 %then %let list=&list.&item.&split;
            %end;
        %end;

        %let rc=%sysfunc(close(&data));&list
    %end;

    %if %length(&notes) %then %put NOTE: _LEVEL returns &list;
%mend _level;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

%let scratch=%_scratch;

data &scratch;
length dollar $ 5;
do i=100 to 1 by -1;
price=i;
dollar='$'||put(i, 6.2);
output;
end;
run;

%put OUTPUT=%_level(data=&scratch, var=dollar);
%put OUTPUT=%_level(data=&scratch, var=price);

*Example 10.1 (The GLMMOD Procedure, SAS Technical Report P-229, pg. 193;

data plants;
input type $ @;

do block=1 to 3;
	input stem @;
	output;
end;

cards;
clarion 32.7 32.3 31.5
clinton 32.1 29.7 29.1
%knox   35.7 35.9 33.1
o&neill 36.0 34.2 31.2
compost 31.8 28.0 29.2
wabash  38.2 37.8 31.9
webster 32.5 31.1 29.7
;
run;

%put OUTPUT=%_level(data=plants, var=stem, format=6.3);
%put OUTPUT=%_level(data=plants, var=type, format=$7.);
endsas;

Local Variables:
ess-sas-submit-command-options: "-noautoexec"
End:

*/
