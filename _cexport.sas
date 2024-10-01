%put NOTE: You have called the macro _CEXPORT, 2024-06-11.;
%put NOTE: Copyright (c) 2004-2024 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2004-00-00

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

/* _CEXPORT Documentation
    Export a CSV file from a SAS Dataset.  PROC EXPORT
    can fail without an obvious way to fix it.  Therefore, this 
    SAS macro can generally be used under those circumstances
    to reliably produce a CSV.
    
    REQUIRED Parameters  

    FILE=                   CSV file to create

    Specific OPTIONAL Parameters

    CFORMAT=$char&length..   default format for character variables 

    DATA=_LAST_         default SAS dataset used
    
    EOL=                if blank, then defaults to native; on Unix, set to DOS
                        for CR/LF

    LENGTH=200          default maximum length of CSV fields to create
    
    NAMES=1             produces variable names on the first
                        line of CSV file, if set to anything
    
    NFORMAT=best9.      default format for numeric variables

    VAR=_all_           default list of variables to be included
                            
    Common OPTIONAL Parameters
    
    ATTRIB= 

    WHERE=
                            
    LOG=                    set to /dev/null to turn off .log                            
*/

%macro _cexport(file=REQUIRED, data=&syslast, var=_all_, 
    length=200, cformat=$char&length.., eol=, nformat=best9., 
    names=1, attrib=, where=, log=);

%_require(&file);

%let file=%scan(&file, 1, ''"");
    
%if %length(&log) %then %_printto(log=&log);

%local i j k char format num scratch var0;

%let var=%_blist(data=&data, var=&var, nofmt=1);

%let scratch=%_scratch;

data &scratch;
    set &data;
    attrib &attrib;
    where &where;
    keep &var;
run;

%let data=&scratch;

%let var0=%_count(&var);    
%let char=%_blist(data=&data, var=_character_);
%let num =%_blist(data=&data, var=_numeric_);

%do i=1 %to &var0;
    %local var&i;
    %let var&i=%scan(&var, &i, %str( ));
%end;

%let format=;

%do i=1 %to &var0;
    %local format&i;
    %let j=%_indexw(&num, &&var&i);
    %let k=%_indexw(&char, &&var&i);

    %if &j>0 %then %do;
        %let format&i=%scan(%_substr(&num, &j), 2, %str( ));
        %if %index(&&format&i,.)=0 %then %let format&i=&nformat;
    %end;
    %else %if &k>0 %then %do;
        %let format&i=%scan(%_substr(&char, &k), 2, %str( ));
        %if %index(&&format&i,.)=0 %then %let format&i=&cformat;
    %end;
%end;

data _null_;
    set &data;
    
    array __string(&var0) $ &length _string1-_string&var0;
    file "&file" linesize=32767;
    
    if _n_=1 & %length(&names)>0 then 
    put %do i=1 %to &var0-1; "&&var&i," %end; "&&var&var0";

    linesize=&var0;
    
    %do i=1 %to &var0; 
        __string(&i)=trim(put(&&var&i, &&format&i-l));
        if indexc(__string(&i), ',') then 
        __string(&i)=putc(__string(&i), '$quote', 
        min(&length, length(__string(&i))+2));
        %if %index(&&format&i,$)>0 %then 
            if &&var&i=' ' then __string(&i)="0D"x;
        %else if nmiss(&&var&i) then __string(&i)="0D"x;;
    
        linesize=length(__string(&i))+linesize;    
    %end; 
    
    if linesize>32767 then 
        put 'ERROR: linesize exceeds 32767 characters:' linesize=;
    else put _string1 %if &var0>1 %then (_string2-_string&var0) (+(-1) ',');;
run;

x "cp &file &file..";
x "tr -d \\015 < &file.. > &file";
x "rm &file..";

%if %length(eol) %then %do;
    %if " %upcase(&eol)"=" %_unwind(DOS)" %then x "unix2dos &file &file";;
%end;

%if %length(&log) %then %_printto;

%mend _cexport;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

*/
