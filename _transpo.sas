%put NOTE: You have called the macro _TRANSPO, 2007-11-09.;
%put NOTE: Copyright (c) 2001-2007 Rodney Sparapani;
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

/*  _TRANSPO Documentation
    This SAS Macro would be best described as anti-transpose;
    it more or less performs the opposite data transformation of 
    PROC TRANSPOSE.  So, the name is a little misleading. 
    
    REQUIRED Paremeters
    
    OUT=            SAS DATASET to create
                
    NAMED Parameters
    
    CHAR=           list of character variables to transform
                    
    DATA=_LAST_     SAS DATASET to be used, defaults to _LAST_
                    
    NUM=            list of numeric variables to transform
    VAR=NUM         alias
                    
    Specific OPTIONAL Parameters
    
    COPY=           list of variables to copy without transformation
                    
    FORMAT=BEST.    default format used to create the text variable
                    from a numeric variable
                    
    INFORMAT=?? 32. default informat used to create the numeric variable
                    from a character variable
                    
    LABEL=_LABEL_   default name of the text variable to store the label of 
                    the variable responsible for creating each observation
                    
    LENGTH=_LENGTH_ default name of the numeric variable used to record
                    the necessary length of the TEXT= variable; this 
                    variable is DROPped, however, a way to name it is 
                    necessary to avoid name collisions
                    
    MISSING=.Z      two-item list of numeric missing value and
                    character missing value; only numeric/character
                    values greater than these will pass through; 
                    numeric missing defaults to .Z and character to blank
                    
    NAME=_NAME_     default name of the text variable to store the name of 
                    the variable responsible for creating each observation
    
    TEXT=_TEXT_     default name of the text variable to store the value of 
                    the variable responsible for creating each observation
                    
    VALUE=_VALUE_   default name of the numeric variable to store the value of 
                    the variable responsible for creating each observation
                    
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
    
    SORT=
    
    WHERE=
*/
    
%macro _transpo(data=&syslast, out=REQUIRED, char=, var=_numeric_, num=&var, 
    copy=, missing=.Z, name=_NAME_, label=_LABEL_, value=_VALUE_, text=_TEXT_, 
    length=_LENGTH_, format=best., informat=?? 32., attrib=, by=, firstobs=, 
    if=, drop=, keep=, obs=, rename=, sort=, where=, log=);

%_require(&out);

%if %length(&log) %then %_printto(log=&log);
%local i char0 num0;

%_sort(data=&data, out=&out, attrib=&attrib, by=&by, firstobs=&firstobs, drop=&drop, 
        if=&if, keep=&keep, obs=&obs, rename=&rename, sort=&sort, where=&where);

%if %length(&char) %then %let char=%upcase(%_blist(&char, data=&out, nofmt=1));
%if %length(&num) %then %let num=%upcase(%_blist(&num, data=&out, nofmt=1));
%let char0=%_count(&char);
%let num0=%_count(&num);

%let by=%upcase(&by);
%let copy=%upcase(&copy);

data &out;
    set &out;

    length &name $ 32 
	%if %length(&text) %then &text $ 200 
	%if %length(&label) %then &label $ 40;
    ;

    keep &by &name &copy &label &value &text;
    array _miss(2) $ %length(&missing) _temporary_ ("%scan(&missing, 1, %str( ))", "%scan(&missing, 2, %str( )) ");
    retain &length 0;

%do i=1 %to &num0;
    %let var=%scan(&num,&i,%str( ));
        
    %if %sysfunc(indexw(&by &copy, &var))=0 %then %do;
	&name="&var";

	%if %length(&label) %then call label(&var,&label);
	;

	&value=&var;

	%if %length(&text) %then %do;
		&text=put(&value, &format);
		if length(&text)>&length then &length=length(&text);
	%end;

	if &var>_miss(1) then output;
    %end;
%end;

%if %length(&text) %then %do i=1 %to &char0;
    %let var=%scan(&char,&i,%str( ));
    
    %if %sysfunc(indexw(&by &copy, &var))=0 %then %do;
	&name="&var";

	%if %length(&label) %then call label(&var,&label);
	;

	&text=trim(&var);
	&value=input(&text, &informat);
	if length(&text)>&length then &length=length(&text);
	if &var>_miss(2) then output;
    %end;
%end;

%if %length(&text) %then %do;
	call symput("length", &length);
    run;

    data &out;
	length &text $ &length;
	set &out;
%end;

run;

%if %length(&by) %then %do;
    proc sort data=&out;
	by &by;
    run;
%end;

%if %length(&log) %then %_printto;
%mend _transpo;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

proc print data=sashelp.voption(obs=10);
run;

%_transpo(data=sashelp.voption, char=optname setting, out=voption, by=optdesc,
	attrib=optdesc format=$20., obs=10);

proc print;
run;

*/
