%put NOTE: You have called the macro _VERIFY, 2022-12-14.;
%put NOTE: Copyright (c) 2021-2022 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2021-12-06

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

/*  _VERIFY Documentation
    
    With the VERIFY() SAS function, explore character variables
specified to discover which of those could be converted to numeric
(since numeric variables can be employed by a wider array of PROC
features as well as SAS macros).  After identification, these
variables are automatically converted to numeric with LENGTH set
appropriate to the magnitude of their content (which can be
over-ridden).

    REQUIRED Parameters

    DATA=_LAST_     default SAS DATASET to use
    
    OUT=REQUIRED    SAS DATASET to create

    VAR=_CHARACTER_ default to all character variables
    
    OPTIONAL Parameters
                
    LENGTH=         to over-ride the LENGTH of one or more
                    variables, e.g., LENGTH=AGE 8

    MISSING=        if missing value is a non-blank character
                    then specify it here

    LOG=            set to /dev/null to turn off .log

    LOGICAL=0       in order to convert TRUE to 1 and FALSE to 0    

*/

%macro _verify(var=_CHARACTER_, data=&syslast, out=REQUIRED,
    length=, missing=, log=, logical=0);

%_require(&out);
    
%if %length(&log) %then %_printto(log=&log);

%local list numeric i j k l miss;

%*let fmt=%_blist(var=&var, data=&data);

%let list=%_blist(var=&var, data=&data, nofmt=1);
%let k=%_count(&list);
%let length=%lowcase(&length);
%let l=%_count(&length);

%if &k=0 %then %do;
%put ERROR: variables "&var" not present on dataset &data;
%end;
%else %do;
    %let j=%_count(&missing);
    
    %if &j=0 %then %let miss=in('');
    %else %do;
        %let miss="%scan(&missing, 1, %str( ))";
        %do i=2 %to &j;
            %let miss=&miss, "%scan(&missing, &i, %str( ))";
        %end;
        %let miss=in(&miss);
    %end;

    %do i=1 %to &k;
        %local var&i len&i max&i lvar&i _var&i;
        %let var&i=%scan(&list, &i, %str( ));
        %let lvar&i=%_substr(l&&var&i, 1, 32);
        %let _var&i=%_substr(_&&var&i, 1, 32);
        %let len&i=3;
        %if &l>0 %then %do j=1 %to &l/2;
            %if "%scan(&length, 2*&j-1, %str( ))"="&&var&i"
                %then %let len&i=%scan(&length, 2*&j, %str( ));
        %end;
    %end;
   data _null_;
       set &data end=last;
       length _check_ $ 11;
       %do i=1 %to &k;
           retain &&_var&i 0 &&lvar&i &&len&i;
           %if &logical %then %do;
               if trim(left(&&var&i))="TRUE" then &&var&i='1';
               else if trim(left(&&var&i))="FALSE" then &&var&i='0';
           %end;
           %*if trim(left(&&var&i))="&missing" then &&var&i=' ';
           if trim(left(&&var&i)) &miss then &&var&i=' ';
           else if trim(left(&&var&i))^=' ' then do;
               if 0<=count(trim(left(&&var&i)), '.')<=1 then do;
                   _check_=".0123456789";
/*
                   if count(trim(left(upcase(&&var&i))), 'E')=1 then
                       _check_="E.0123456789";
                   else _check_=".0123456789";
*/
               end;
               else _check_="0123456789";
               if trim(left(&&var&i)) in:('-', '+') &
                       length(trim(left(&&var&i)))>1 then
                       &&_var&i=max(&&_var&i,
                       verify(substr(trim(left(&&var&i)), 2), trim(_check_)));
               else
                       &&_var&i=max(&&_var&i, verify(trim(left(&&var&i)), trim(_check_)));
           end;
           
        if &&_var&i=0 then do;
           if  abs(&&var&i)^=floor(abs(&&var&i)) |
               abs(&&var&i)>35184372088832 then
               &&lvar&i=8;
           else if abs(&&var&i)>137438953472 then
               &&lvar&i=max(7, &&lvar&i);
           else if abs(&&var&i)>536870912 then
               &&lvar&i=max(6, &&lvar&i);
           else if abs(&&var&i)>2097152 then
               &&lvar&i=max(5, &&lvar&i);
           else if abs(&&var&i)>8192 then
               &&lvar&i=max(4, &&lvar&i);
        end;
        %end;
    if last;
       retain numeric 0;
       %do i=1 %to &k;
       if &&_var&i=0 then numeric+1;     
       call symput("max&i", trim(left(&&_var&i)));
       call symput("len&i", trim(left(&&lvar&i)));
       %end;
       call symput("numeric", trim(left(numeric)));
    run;

    %if &numeric>0 %then %do;
        data &out;
            set &data;
        %do i=1 %to &k;
            %if &&max&i=0 %then %do;
                length &&_var&i &&len&i;
                drop &&var&i;
                rename &&_var&i=&&var&i;
                %if &logical %then %do;
                    if trim(left(&&var&i))="TRUE" then &&var&i='1';
                    else if trim(left(&&var&i))="FALSE" then &&var&i='0';
                %end;
                %*if trim(left(&&var&i))="&missing" then;
                if trim(left(&&var&i)) &miss then;
                else &&_var&i=inputn(trim(left(upcase(&&var&i))),
                    trim(left(length(trim(left(&&var&i)))))||'.');
                %*else &&_var&i=&&var&i;
            %end;
        %end;

        run;
    %end;
%end;

%if %length(&log) %then %_printto;

%mend _verify;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

data check;
length num1-num8 char1-char3 $ 14;
input num1 $ num2 $ num3 $ num4 $ num5 $ num6 $ num7 $ num8 $
    char1 $ char2 $ char3 $;
cards;
-1 .0 +8192 2097152 536870912 137438953472 35184372088832 35184372088833 0.0. -1-1 +2+2
run;

%_verify(data=check, out=check);

proc contents varnum;
run;

proc print;
    var num1  num2  num3  num4  num5  num6  num7  num8  char1  char2  char3; 
    format num1-num8 best14.;
run;

*/
