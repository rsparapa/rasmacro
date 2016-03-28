%put NOTE: You have called the macro _BEGIN, 2014-09-29.;
%put NOTE: Copyright (c) 2001-2013 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2014-09-29

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

/*  _BEGIN Documentation
    Creates long IN:() operators.  Replacement for %_IN() SAS macro
    which mysteriously stopped working with SAS v. 9.3 TS1M2.  
    _BEGIN stands for "begins with".
    
    Instead of:
    if hcpcs_cd %_in('63265'-'63285', by=5) then ex15=1;

    Now, we write:
    if hcpcs_cd %_begin('63265'-'63285'@5) then ex15=1; 
    
    POSITIONAL Parameters
    
    N/A
                
    NAMED Parameters

    N/A    
*/

%macro _begin/parmbuff;

%local i j;

%*put SYSPBUFF=&syspbuff;

%let j=%_count(&syspbuff, split=%str(,()));

in:(%do i=1 %to &j;
    %_list(%qscan(&syspbuff, &i, %str(,())), split=%str(,)) %if &i<&j %then ,;
%end;)

%mend _begin;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

data _null_;

    hcpcs_cd='63279';

    if hcpcs_cd %_begin('22100', '22110', '22318', '22319', '22326', '22548', 
        '22590', '22595', '61343', '63180', '63182', '63194', '63196', '63198', 
        '63250', '63265'-'63285', '63300', '63304') then ex15=1;

    put ex15=;
run;
    
*/
