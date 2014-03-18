%put NOTE: You have called the macro _DIMPORT, 2010-02-08.;
%put NOTE: Copyright (c) 2010 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2010-01-30

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

/* _DIMPORT Documentation
    Import an R "dump" data file into a SAS Dataset.
    
    REQUIRED Parameters  

    INFILE=                 "list" file to read

    OUT=                    SAS dataset created
        
    RENAME=                 optional
                            
    TRANSPOSE=0             TRANSPOSE=1 is to transpose datasets
                            with 1 column into 1 row
    
    VAR=                    defaults to reading the first variable
                            in the dump file; specify a list of
                            variables to read more than one
                            
    Common OPTIONAL Parameters
    
    LOG=                    set to /dev/null to turn off .log                            
*/

%macro _dimport(infile=REQUIRED, out=REQUIRED, rename=, transpose=0, var=, log=);

%_require(&infile &out);

%let infile=%scan(&infile, 1, ''"");
    
%if %length(&log) %then %_printto(log=&log);
    
%local i j k;

proc format;
    invalue na
        'NA'=.n
    ;
run;

%let k=%_count(&var);

%do i=1 %to %_max(1, &k);
    %local var&i row&i col&i data&i;
    
    %if &k>1 %then %let data&i=%_scratch;
    %else %let data&i=&out;
    
    %let var&i=%scan(&var, &i, %str( ));
    
data _null_;
    infile "&infile" dsd dlm='3d63284c2c60'x; 
    length var $ 32;
    input @"`&&var&i" var;
    
    %if %length(&&var&i)=0 %then call symput("var&i", trim(var));;
    
    input @'.Dim' @;
    
    do while(nmiss(col));
        if nmiss(row) then input row @;
        else input col @;
    end;
        
    call symput("row&i", trim(row));
    call symput("col&i", trim(col));        

    stop;
run;

data &&data&i;
    infile "&infile" dsd dlm='0d0a2c29'x;
    drop i;
    input @"`&&var&i.`" @'structure(c(' @;
    
    %let var&i=%_translate(&&var&i, to=_, from=.);
    
    informat &&var&i na.;
    
    i=0;
    
    do while(i<%eval(&&row&i*&&col&i));
        input &&var&i @;

        if &&var&i^=. then do;
            if &&var&i=.n then &&var&i=.;
        
            i=i+1;
            output;
        end;
    end;
run;

    %if &&col&i>1 | &transpose %then %do;
data &&data&i;
    merge
    %if &&col&i=1 %then %do j=1 %to &&row&i;
        &&data&i(rename=(&&var&i=%unquote(&&var&i..&j)) firstobs=&j obs=&j)
    %end;
    %else %do j=1 %to &&col&i;
        &&data&i(rename=(&&var&i=%unquote(&&var&i..&j)) firstobs=%eval(1+(&j-1)*&&row&i) obs=%eval(&j*&&row&i))
    %end;
    ;
            
    %if &k<2 %then rename &rename;;
run;
    %end;
%end;

%if &k>1 %then %do;
data &out;
    merge %do i=1 %to &k; &&data&i %end;;
    rename &rename;
run;
%end;

%if %length(&log) %then %_printto;

%mend _dimport;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

*/


