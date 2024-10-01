%put NOTE: You have called the macro _FILEREF, 2015-08-11.;
%put NOTE: Copyright (c) 2006-2012 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2006-10-21

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

/* _FILEREF Documentation
    Replaces _EXPAND.  Executes a FILENAME statement for a list of 
    existing files with wild cards expanded and blanks escaped, if 
    necessary.  WARNING: Unix and Unix-like shells only; others do 
    not expand wild cards automatically via the command line.  NOTE: 
    SAS FILENAME statements do attempt to expand wild cards, but will 
    often fail in both version 8 and 9; this is a very tricky problem 
    to detect since no error/warning is generated and, when the PIPE 
    option is specified, the expansion is not echoed; hence the 
    necessity for this macro.
            
    POSITIONAL Parameters  
            
    ARG1                file(s) to be expanded, escaped,
                        checked for existence and listed
    REQUIRED Parameters
   
    FILEREF=            the name of the FILEREF to create
                        
    FILENAME=           alias for FILEREF=

    NAMED Parameters
    
    COMMAND=            defaults to nothing; if specified,
                        the pipe option is declared

    FILE=               alias for ARG1
    
    OPTION=             command-line option(s) for /bin/ls
                        a common choice may be OPTION=-r
                        for listing files in reverse 
                        alphanumeric order
    
    UNIQUE=0            defaults to a non-unique list of files  
                        set UNIQUE=1 for a unique list
*/

%macro _fileref(arg1, command=, file=&arg1, filename=REQUIRED, 
    fileref=&filename, option=, unique=0, out=);

%_require(&fileref)
    
filename _&sysjobid pipe "/bin/ls -1 &option &file";;

%local return scratch files i;

%if %length(&out) %then %let scratch=&out;
%else %let scratch=%_scratch;

data &scratch;
    length file $ 200;
    infile _&sysjobid length=length;
    input @;
    input file $varying. length;
    drop i;
    
    i=index(file, ' ');
    
    if i>length then i=0;
    
    do while(i);
        substr(file, i, 1)='|';
        i=index(file, ' ');
    
        if i>length then i=0;
    end;
    
    i=index(file, '|');
    
    if i>length then i=0;
    
    do while(i);
        file=substr(file, 1, i-1)||'\ '||substr(file, i+1);
        length=length+1; 
        i=index(file, '|');
    
        if i>length then i=0;
    end;
run;

filename _&sysjobid;    

%*_sort(data=&scratch, out=&scratch, by=file, sort=nodupkey);

%let files=%_level(var=file, split=|, unique=&unique);
%let return=;

%do i=1 %to %_count(&files, split=|);
    %local file&i;
    %let file&i=%qtrim(%scan(&files, &i, |));
    
    %if %_exist(&&file&i) %then %do;
        %if %length(&command) %then %let return=&return &&file&i;
        %else %let return=&return "&&file&i";
    %end;
%end;

filename &fileref
    %if %length(&command) %then pipe "&command &return";
    %else (&return);
;

%mend _fileref;

%*VALIDATION TEST STREAM;
/* uncomment to re-validate

options ls=120;

%_fileref(fileref=check, file=~/[a-zA-Z]*.doc ~/[a-zA-Z]*\ *);

%_fileref(fileref=check, command=gzcat, file=~/[a-zA-Z]*.doc ~/[a-zA-Z]*\ *);
    
proc print;
run;

*/
