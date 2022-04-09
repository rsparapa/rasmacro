%put NOTE: You have called the macro _CREPAIR, 2021-12-27.;
%put NOTE: Copyright (c) 2021 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2021-11-04

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

/* _CREPAIR Documentation
    CSV files created by R have a gnarly structure.  Excel can
    read these files fine but SAS cannot.  Every field is encased in
    double quotes.  But, long fields are split over lines that are
    only of length 68.  This macro undoes this nonsense re-creating
    a normal CSV file that SAS can read.  However, if the linesize
    is greater than 32767 SAS might still not be able to read it.
    
    REQUIRED Parameters  

    INFILE=                 CSV file to read
    FILE=                   CSV file to write
                            
    
    Specific OPTIONAL Parameters
                            
    EOL=0D                  default end of line
                               
                            
    Common OPTIONAL Parameters
    
    LOG=/dev/null           set to blank to turn on .log                            

    RASMACRO Dependencies
    _EXIST
    _NULL
    _PRINTTO
    _REQUIRE
*/

%macro _crepair(file=REQUIRED, infile=REQUIRED, eol=0d, obs=, log=%_null);

%_require(&infile &file);

%let infile=%scan(&infile, 1, ''"");
%let file=%scan(&file, 1, ''"");
    
%if %_exist(&infile) %then %do;

%if %length(&log) %then %_printto(log=&log);

data _null_;
    infile "&infile" length=len dlm="&eol"x;  
    length line $ 32767;
    file "&file";
    tot=1;
    retain obs 0;

    %if %length(&obs)>0 %then if obs<=&obs;;
    
    do until(substr(line, len, 1)='"');
        input @;
        input line $varying. len;

        put @tot line @;
        tot=tot+len;

        if tot>32767 then do;
            put 'ERROR: linesize exceeds 32767';
            stop;
        end;
    end;

    put;
    obs+1;
run;

%end;
    
%if %length(&log) %then %_printto;

%mend _crepair;
        
