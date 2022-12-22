%put NOTE: You have called the macro _CHARDATE, 2022-12-20.;
%put NOTE: Copyright (c) 2022 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2022-12-16

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

/*  _CHARDATE Documentation
    
    Automatic character to numeric conversion for dates only.  

    REQUIRED Parameters

    DATA=_LAST_     default SAS DATASET to use
    
    OUT=REQUIRED    SAS DATASET to create

    INFORMAT=ANYDTDTE. default date informat

    FORMAT=DATE7.   default date format
    
    VAR=_CHARACTER_ default to all character variables
    
    OPTIONAL Parameters
                
    MISSING=        if missing value is a non-blank character
                    then specify it here

    LOG=            set to /dev/null to turn off .log

*/

%macro _chardate(var=_CHARACTER_, data=&syslast, out=REQUIRED,
     format=date7., informat=anydtdte., missing=, log=);

%_require(&out);
    
%if %length(&log) %then %_printto(log=&log);

%local all length list miss vars i j k l;

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
        data &&_var&i;
           set &&var&i end=last;
           length &&_var&i 8;
           format &&_var&i &format;
           retain &&lvar&i 3;
           drop &&var&i &&lvar&i;
           rename &&_var&i=&&var&i;
           if &&var&i &miss then;
           else &&_var&i=inputn(trim(left(&&var&i)), "&informat",
               length(trim(left(&&var&i))));
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

        %if &&lval&i %then %do;
            %let vars=&vars &&_var&i;
            %let length=&length &&var&i &&lval&i;
        %end;
        %else %let vars=&vars &&var&i;
    %end;

data &out;
    length &length;
    merge &out(drop=&list) &vars;
run;
        
%_vorder(data=&out, out=&out, var=&all);

%end;

%mend _chardate;
