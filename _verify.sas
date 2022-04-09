%put NOTE: You have called the macro _VERIFY, 2022-01-08.;
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

    LOG=            set to /dev/null to turn off .log                            

*/

%macro _verify(var=_CHARACTER_, data=&syslast, out=REQUIRED,
    length=, log=);

%_require(&out);
    
%if %length(&log) %then %_printto(log=&log);

%local list numeric i j k l;

%*let fmt=%_blist(var=&var, data=&data);

%let list=%_blist(var=&var, data=&data, nofmt=1);
%let k=%_count(&list);
%let length=%lowcase(&length);
%let l=%_count(&length);

%if &k=0 %then %do;
%put ERROR: variables "&var" not present on dataset &data;
%end;
%else %do;
    %do i=1 %to &k;
        %local var&i len&i max&i;
        %let var&i=%scan(&list, &i, %str( ));
        %let len&i=3;
        %if &l>0 %then %do j=1 %to &l/2;
            %if "%scan(&length, 2*&j-1, %str( ))"="&&var&i"
                %then %let len&i=%scan(&length, 2*&j, %str( ));
        %end;
    %end;
   data _null_;
       set &data end=last;
       %do i=1 %to &k;
           retain _&&var&i 0 _l&&var&i &&len&i;
           if trim(left(&&var&i))^=' ' then
           _&&var&i=max(_&&var&i, verify(trim(left(&&var&i)),".0123456789"));
           
        if _&&var&i=0 then do;
           if  abs(&&var&i)^=floor(abs(&&var&i)) |
               abs(&&var&i)>35184372088832 then
               _l&&var&i=8;
           else if abs(&&var&i)>137438953472 then
               _l&&var&i=max(7, _l&&var&i);
           else if abs(&&var&i)>536870912 then
               _l&&var&i=max(6, _l&&var&i);
           else if abs(&&var&i)>2097152 then
               _l&&var&i=max(5, _l&&var&i);
           else if abs(&&var&i)>8192 then
               _l&&var&i=max(4, _l&&var&i);
        end;
        %end;
    if last;
       retain numeric 0;
       %do i=1 %to &k;
       if _&&var&i=0 then numeric+1;     
       call symput("max&i", trim(left(_&&var&i)));
       call symput("len&i", trim(left(_l&&var&i)));
       %end;
       call symput("numeric", trim(left(numeric)));
    run;

    %if &numeric>0 %then %do;
        data &out;
            set &data;
        %do i=1 %to &k;
            %if &&max&i=0 %then %do;
                length _&&var&i &&len&i;
                drop &&var&i;
                rename _&&var&i=&&var&i;
                _&&var&i=&&var&i;
            %end;
        %end;

        run;
    %end;
%end;

%if %length(&log) %then %_printto;

%mend _verify;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/
