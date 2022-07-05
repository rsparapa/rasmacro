%put NOTE: You have called the macro _CIMPORT, 2022-06-30.;
%put NOTE: Copyright (c) 2004-2022 Rodney Sparapani;
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

/* _CIMPORT Documentation
    Import a CSV/Stata file into a SAS Dataset.  This macro assumes
    that the first line contains variable names.  The following
    characters in variable names are converted to underscore:
    _.-[]()@ and space.  All other non-alphanumeric characters are 
    removed.  Don't forget to turn off file-locking when necessary: 
    -filelocks none DIRECTORY-NAME.
    
    REQUIRED Parameters  

    INFILE=                 CSV file to read
    OUT=                    SAS dataset created
                            
    Specific OPTIONAL Parameters
                            
    ATTRIB=                 ATTRIB statement;
                            see the SAS manual with respect to the
                            ATTRIB statement for more details
                            
    DAY0='01JAN1960'D       set to the date which represents 0
                            in the file which you are importing;
                            see also the NUMDATES= option;
                            the default is valid for SAS and Stata;
                            for Excel, try DAY0='30DEC1899'D
                            however, Excel dates prior to 01MAR1900  
                            are uncertain since the non-existant
                            leap year date of 29FEB1900 is a valid 
                            choice for day 60 in Excel, whereas other
                            Excel-compatible spreadsheet applications 
                            may have no leap year in 1900 and define 
                            day 60 as 28FEB1900 so that 01MAR1900, and 
                            beyond, agree 
    
    DLM=2C                  default comma delimiter (in HEX) besides 
                            carriage return (0D) which is automatic
                            since it is needed for DOS line-endings:
                            for TAB delimited DLM=09
                            
    EOL=0D                  default end of line
                                
    FILE=INFILE             alias

    FIRSTOBS=2              the line on which data starts
                            
    HEADER=1                the line on which headings can be found
                            
    INFORMAT=               INFORMAT statement; for formatted data,
                            such as dates, list the variables followed 
                            by their informat  
                            Ex. INFORMAT=birthd date7. 
                            see the SAS manual with respect to the
                            INFORMAT statement for more details
    
    LENGTH=200              default maximum length of character variables
                            actual length is determined from all records
                            but it will be no longer than LENGTH
                            
    LINESIZE=32767          default line length
    LS=LINESIZE             alias
                            
    NVARS=                  to skip blank columns, specify the
                            number of variables to be expected
                            
    NUMDATES=               list of numeric dates containing
                            optional formats (rather than 
                            character dates, for those see
                            INFORMAT= above); supply these
                            for a DAY0= correction

    CHECK=MAX               defaults to using all observations
                            to determine which fields are
                            character vs. numeric
                            however, with a large file this 
                            can be very time-consuming
                            therefore, if it is not sparse, 
                            you may want to try CHECK=100

    LOWCASE=/UPCASE=        list of variables to lower/upper case
                            
    Common OPTIONAL Parameters
    
    LOG=/dev/null           set to blank to turn on .log                            

    BY=
                
    DROP=
    
    IF=

    KEEP=

    OBS= 

    SORT=
                                
    RENAME=
    
    WHERE=

    RASMACRO Dependencies
    _COUNT
    _LIST
    _NULL
    _PRINTTO
    _REQUIRE
    _SORT
*/

%macro _cimport(file=REQUIRED, infile=&file, out=REQUIRED, attrib=, by=,
    check=max, day0='01JAN1960'd, dlm=2C, eol=0d, drop=, informat=,
    length=200, linesize=32767, ls=&linesize, lowcase=, numdates=,
    firstobs=2, header=1, obs=max, nvars=, if=, index=, keep=, rename=,
    sort=, upcase=, where=, log=%_null);

%_require(&infile &out);

%let infile=%scan(&infile, 1, ''"");
    
%if %_exist(&infile) %then %do;

%if %length(&log) %then %_printto(log=&log);

%local i j %_list(var0-var256); %* BEWARE: more than 256 variables is trouble!;                            

%if "%upcase(&obs)"^="MAX" %then %let obs=%eval(&obs+&header);

%if "%_datatyp(&header)"="NUMERIC" %then %do;
%if &firstobs<&header %then %let firstobs=%eval(&header+1);
data _null_;
    infile "&infile" dsd firstobs=&header obs=&header ls=&ls dlm="&eol.&dlm"x  
        %if %length(&nvars)=0 %then missover;;
    length var $ 64;
    i=0;
    j=0;
        
    do until( %if %length(&nvars) %then (i-j)=&nvars; %else var=' '; );
        i=i+1;
        input var @;

        if var>' ' then do;
            var=compress(var, '=\`;'',/!#$%^&*+|~:"?{}');
            
            if substr(var, 1, 1) in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9') then
                var='_'||var;
                
            if length(var)>32 then var=substr(var, 1, 32);
            
            var=translate(trim(var), '________', ' -.[]()@');
            var=tranwrd(var, '__', '_');
            
            call symput('var'||left(i), var);
            call symput('var0', trim(left(i)));
        end;
        %if %length(&nvars) %then %do;
        else do;
            j=j+1;
            var='_drop_'||left(j);
                
            call symput('var'||left(i), var);
            call symput('var0', trim(left(i)));
        end;
        
        put i= var=;
        %end;
    end;
run;
%end;
%else %do;
    %local var0;
    
    %let header=%_list(&header);
    %let var0=%_count(&header);
    
    %do i=1 %to &var0; 
        %local var&i;
    
        %let var&i=%scan(&header, &i, %str( ));
    %end;
%end;
    
%do i=1 %to &var0; 
    %local type&i len&i;
                                
    %do j=1 %to &i-1;
        %if "%upcase(&&var&i)"="%upcase(&&var&j)" %then %let var&i=_&&var&i;
    %end;
    
data _null_;
    attrib &attrib;
    informat &informat;
    infile "&infile" dsd firstobs=&firstobs obs=&check ls=&ls dlm="&eol.&dlm"x 
        %if %length(&nvars)=0 %then missover;;

    input %do j=1 %to &i; &&var&j &&type&j %end;;

    if _error_ then do;
        %*_error_=0;
        call symput("type&i", "$");
        stop;
    end;
run;
    
%end;

data &out;    
    %do i=1 %to &var0; 
        %if "&&type&i"="$" %then %do;
            length &&var&i &&type&i &length;
        %end;
    %end;        
            
    attrib &attrib;
    informat &informat;
    infile "&infile" dsd firstobs=&firstobs obs=&obs ls=&ls dlm="&eol.&dlm"x end=_last_
        %if %length(&nvars)=0 %then missover;;

    input %do i=1 %to &var0; &&var&i &&type&i %end;;
    
    %if %length(&numdates) %then %do;
        %let numdates=%_list(&numdates);
        
        %do i=1 %to %_count(&numdates);
            %local num&i;
            %let num&i=%scan(&numdates, &i, %str( ));
            
            %if %index(&&num&i,.)=0 %then &&num&i=&&num&i+&day0;;
        %end;
    %end;
        
    %do i=1 %to &var0; 
        %if "&&type&i"="$" %then %do;
            drop _len&i;
            retain _len&i 1;
    
            _len&i=max(_len&i, length(&&var&i));
            
            if _last_ then call symput("len&i", trim(left(_len&i)));
        %end;
    %end;        

    if %do i=1 %to &var0; 
        %if "&&type&i"="$" %then &&var&i='';
        %else nmiss(&&var&i);
        & 
        %end; 1 then delete;
run;
    
%if %length(&log) %then %_printto;

data &out;
    length %do i=1 %to &var0; 
        %if "&&type&i"="$" %then %do;
            &&var&i &&type&i &&len&i
            
            %if &&len&i=&length %then 
                %put WARNING: maximum character length, &length, possibly exceeded for &&var&i;
        %end;
    %end;;

    set &out;
    
/*
    by &by;
    %if %length(&drop) %then drop &drop;;
    rename &rename;
    where &where;    
            
    %if %length(&if) %then if &if;;
*/
    
    %if %length(&nvars) %then %do;
        %if &var0>&nvars %then drop _drop_:;;
    %end;

    %if %length(&lowcase) %then %do;
        %let lowcase=%_list(&lowcase);
        %do j=1 %to %_count(&lowcase);
        %scan(&lowcase, &j, %str( ))=lowcase(%scan(&lowcase, &j, %str( )));
        %end;
    %end;
    
    %if %length(&upcase) %then %do;
        %let upcase=%_list(&upcase);
        %do j=1 %to %_count(&upcase);
        %scan(&upcase, &j, %str( ))=upcase(%scan(&upcase, &j, %str( )));
        %end;
    %end;
run;
    
%_sort(data=&out, out=&out, by=&by, drop=&drop, if=&if, index=&index,
    keep=&keep, rename=&rename, sort=&sort, where=&where);
    
%end;
%else %do;
    data &out;
        set _null_;
    run;
    
    %put ERROR: "&infile" does not exist.;
%end;
 
%mend _cimport;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/


