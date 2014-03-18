%put NOTE: You have called the macro _CD, 2007-08-01.;
%put NOTE: Copyright (c) 2007 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2007-07-31

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

/*  _CD Documentation
    Change directory in an OS independent way; currently, only Unix
    and Windows supported.  See examples below for directories with 
    spaces in their names.
    
    POSITIONAL Parameters
    
    ARG             directory
                    
    NAMED Parameters
    
    DIR=ARG	    alias
*/

%macro _cd(arg, dir=&arg);
%local windows;

%if %_indexc(&dir,"")=1 & %index(&dir,:)=3 %then 
    %let windows=%substr(&dir, 2, 2)%str(;); 
%else %if %_indexc(&dir,"")=0 & %index(&dir,:)=2 %then 
    %let windows=%substr(&dir, 1, 2)%str(;); 

%_unwind(,&windows)cd &dir

%mend _cd;

%*VALIDATION TEST STREAM;

/* un-comment to re-validate
    
%*Unix Examples;
x "%_cd(/tmp/no_spaces); touch that";
x "%_cd(/tmp/with\ spaces); touch this";
    
%*Windows Examples;
%put "%_cd(\no_spaces\in_directory_name);";
%put "%_cd(%str(")\with spaces\in directory name%str("));";
%put "%_cd(c:\no_spaces\in_directory_name);";
%put "%_cd(%str(")c:\with spaces\in directory name%str("));";

*/
