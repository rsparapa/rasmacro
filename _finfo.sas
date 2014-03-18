%put NOTE: You have called the macro _FINFO, 2013-10-29.;
%put NOTE: Copyright (c) 2013 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2013-10-29

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

/* _FINFO Documentation
    Similar to the FINFO() function, but returns more info like date/time.
                
    POSITIONAL Parameters  
            
    ARG1                file(s) to be expanded, escaped,
                        checked for existence and listed
    
    NAMED Parameters
    
    FILE=               alias for ARG1
    
    OPTION=             command-line option(s) for /bin/ls
                        a common choice may be OPTION=-r
                        for listing files in reverse 
                        alphanumeric order
*/

%macro _finfo(arg1, file=&arg1, option=, return=finfo);

%global &return;

%if %_exist(&file) %then %do;
filename _&sysjobid pipe "/bin/ls -l &option ""&file""";;

data _null_;
    length finfo $ 200;
    infile _&sysjobid length=len;
    input @;
    len=len-%length(&file);
    input finfo $varying. len;
    
    call symput("&return", trim(left(finfo)));
run;

filename _&sysjobid;    
%end;

%mend _finfo;

%*VALIDATION TEST STREAM;
/* uncomment to re-validate

%_finfo(/opt/sasmacro/_finfo.sas);

%put &finfo;
    
*/

