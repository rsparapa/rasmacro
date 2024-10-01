%put NOTE: You have called the macro _CHARNUM2, 2024-08-24.;
%put NOTE: Copyright (c) 2022-2024 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2022-12-15

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

/*  _CHARNUM2 Documentation
    
    Automatic character to numeric conversion including dates.
    Although not originally part of the intent, those variables
    that are non-numeric character have their lengths optimized.
    For example, working with SQL pass-through queries where
    all character variables are arbitrarily long: 200 or 1024
    even for values that are 8 characters or less (that is the
    usual default).  This leads to massively over-sized data sets
    and performance issues that are so easily addressed here.

    REQUIRED Parameters

    DATA=_LAST_     default SAS DATASET to use

    FORMAT=DATE7.   default date format

    INFORMAT=ANYDTDTE. default date informat
    
    OUT=REQUIRED    SAS DATASET to create

    VAR=_CHARACTER_ default to all character variables
    
    OPTIONAL Parameters
  
    R=0             1 sets defaults for R: LOGICAL=1 and MISSING=NA             
                
    LOGICAL=0       in order to convert TRUE to 1 and FALSE to 0  

    FALSE=FALSE     default logical string that is a 0 
                    with upper-casing of this value and the input
                
    TRUE=TRUE       default logical string that is a 1
                    with upper-casing of this value and the input

    MISSING=        if missing value is a non-blank character
                    then specify it here

    NUMLENMIN=3     minimum length for numeric variables
    
    LOG=            set to /dev/null to turn off .log
*/

%macro _charnum2(var=_CHARACTER_, data=&syslast, out=REQUIRED,
    format=date7., informat=anydtdte., missing=, numlenmin=3,
    charlenmin=8, log=, logical=0, false=FALSE, true=TRUE, R=0);

%_require(&out);
    
%if %length(&log) %then %_printto(log=&log);

%local all char length list miss vars i j k l;

%if &R=1 %then %do;
    %let logical=1;
    %if %_indexw(&missing, NA)=0 %then %let missing=NA &missing;
%end;

%let char=;
%let list=%_blist(var=&var, data=&data, nofmt=1);
%let k=%_count(&list);

%if &k=0 %then %do;
%put ERROR: variables "&var" not present on dataset &data;
%end;
%else %do;
    %let all=%_blist(var=_all_, data=&data, nofmt=1);
    %let j=%_count(&missing);
    
    %if &j=0 %then %let miss=in(' ');
    %else %do;
        %let miss=" ";
        %do i=1 %to &j;
            %let miss=&miss, "%scan(&missing, &i, %str( ))";
        %end;
        %let miss=in(&miss);
    %end;

    %let false=%upcase(&false);
    %let true=%upcase(&true);
    
data &out;
    set &data;
run;

    %do i=1 %to &k;
        %local var&i _var&i lvar&i lval&i;
        %let var&i=%scan(&list, &i, %str( ));
        %let _var&i=%_substr(_&&var&i, 1, 32);
        %let lvar&i=%_substr(l&&var&i, 1, 32);
        data &&var&i;
            set &out(keep=&&var&i);
        run;

        %let lval&i=0;
        %do j=1 %to 2;
           %if &&lval&i=0 %then %do;
        data &&_var&i;
           set &&var&i end=last;
           length &&_var&i 8;
           retain &&lvar&i &numlenmin;
           drop &&var&i &&lvar&i;
           rename &&_var&i=&&var&i;
           if &&var&i &miss then;
           %if &j=2 %then %do;
           else &&_var&i=inputn(trim(left(&&var&i)), "&informat",
               length(trim(left(&&var&i))));
           format &&_var&i &format;
           %end;
           %else %do;
              /*  
              %if %_indexc(&logical, .) %then %do;
           else &&_var&i=inputn(trim(left(&&var&i)), "&logical",
               length(trim(left(&&var&i))));
              %end;  
              %else 
              */ 
              %if &logical %then %do;
           else if upcase(trim(left(&&var&i)))="&FALSE" then &&_var&i=0;
           else if upcase(trim(left(&&var&i)))="&TRUE" then &&_var&i=1;
              %end;
           else &&_var&i=&&var&i;
           format &&_var&i;
           %end;
           informat &&_var&i;
           output;
           if _error_ then do;
               _error_=0;
               call symput("lval&i", "0");
               stop;
           end;
           else do;
           if  abs(&&_var&i)^=floor(abs(&&_var&i)) |
               abs(&&_var&i)>35184372088832 then
               &&lvar&i=8;
           else if abs(&&_var&i)>137438953472 then
               &&lvar&i=max(7, &&lvar&i);
           else if abs(&&_var&i)>536870912 then
               &&lvar&i=max(6, &&lvar&i);
           else if abs(&&_var&i)>2097152 then
               &&lvar&i=max(5, &&lvar&i);
           else if abs(&&_var&i)>8192 then
               &&lvar&i=max(4, &&lvar&i);
           if last then
               call symput("lval&i", trim(left(&&lvar&i)));
           end;
        run;
           %end;
        %end;

        %if "&&lval&i"="0" %then %do; *simple case: character;
            %if "&&var&i"="_l_" %then %do;
                %put ERROR: variable name _l_ is used for length;
                %_abend;
            %end;
            data &&var&i; 
                set &&var&i end=last;
                retain &&lvar&i &charlenmin;
                drop _l_ &&lvar&i;
                if &&var&i &miss then do;
                    _l_=0;
                    &&var&i=' ';
                end;
                else _l_=length(&&var&i);
                if _l_>&&lvar&i then &&lvar&i=_l_;
                if last then
                    call symput("lval&i", "$ "||trim(left(&&lvar&i)));
            run;
        %end;
    
        %if "&&lval&i"^="0" %then %do;
            %if %index(&&lval&i, $) %then %do;
                %let vars=&vars &&var&i;
                %let char=&char &&var&i;
            %end;
            %else %let vars=&vars &&_var&i;
            %let length=&length &&var&i &&lval&i;
        %end;
    %end;

data &out;
    length &length;
    merge &out(drop=&list) &vars;
    format &char;
    informat &char;
    /*
    array _char(*) _character_;
    format _character_;
    drop i;
    do i=1 to hbound(_char);
        if _char(i) &miss then _char(i)=' ';
    end;
    */
run;
        
%_vorder(data=&out, out=&out, var=&all);

%end;

%mend _charnum2;
