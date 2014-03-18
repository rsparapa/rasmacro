%put NOTE: You have called the macro _DELETE, 2008-08-08.;
%put NOTE: Copyright (c) 2001-2008 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2001-06-08

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

/*  _DELETE Documentation
    PROC DELETE was not executing when placed in a SAS macro.
    SCL FDELETE did not work and SCL DELETE was not available.
    Hence this SAS macro.
    
    SAS DATASET files and associated SAS INDEX files are
    removed by OS commands.  Wildcards are OK if your OS allows 
    them.  Currently, only Unix, PC and Mac are supported.
    
    SAS CATALOG files are also removed.  This is necessary
    since PROC CATALOG will not remove CATALOG files from
    an earlier version of SAS; a major hassle in the transition
    from SAS v.8 to v.9.
    
    POSITIONAL Parameters
    
    ARG1        a SAS CATALOG or SAS DATASET to delete along with
                its associated SAS INDEX file, if any
                
    NAMED Parameters
    
    CAT=ARG1    alias

    DATA=ARG1   alias
*/

%macro _delete(arg1, cat=&arg1, data=&cat); 

%local i suffix file;

%let suffix=%_suffix %_catext;

%do i=1 %to %_count(&suffix);
    %let file=%_dir(%sysfunc(pathname(%_lib(&data))))%_data(&data).%scan(&suffix, &i, %str( ));
    
    %if %_exist(&file) %then x "%_unwind(rm -f, del) &file";;
%end;

%mend _delete;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

libname pwd '.';

data pwd._test_(index=(x));
    x=1;
    output;
run;

%_delete(pwd._test_);
%_delete(pwd.imlstor);

proc contents data=pwd._all_;
run;

*/
