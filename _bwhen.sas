%put NOTE: You have called the macro _BWHEN, 2013-09-05.;
%put NOTE: Copyright (c) 2013 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2001-00-00

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

/*  _BWHEN Documentation
    Creates long WHEN() clauses.  Replacement for %_WHEN() SAS macro
    which mysteriously stopped working with SAS v. 9.3 TS1M2.  The
    B in _BWHEN stands for "better" like %BQUOTE() is a better %QUOTE().
    
    Instead of:
    %_when('63015', '63020', '63040'-'63050', '63051', by=5) post=1; 

    Now, we write:
    %_bwhen('63015', '63020', '63040'-'63050'@5, '63051') post=1; 
    
    POSITIONAL Parameters
    
    N/A
                
    NAMED Parameters

    N/A    
*/

%macro _bwhen/parmbuff;

%local i j;

%*put SYSPBUFF=&syspbuff;

%let j=%_count(&syspbuff, split=%str(,()));

when(%do i=1 %to &j;
    %_list(%qscan(&syspbuff, &i, %str(,())), split=%str(,)) %if &i<&j %then ,;
%end;)

%mend _bwhen;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

data _null_;

    hcpcs_cd='63279';

    select(hcpcs_cd);
        %_bwhen('22100', '22110', '22318', '22319', '22326', '22548', 
            '22590', '22595', '61343', '63180', '63182', '63194', '63196', '63198', 
            '63250', '63265'-'63285', '63300', '63304') ex15=1;
        otherwise;
    end;

    put ex15=;
run;
    
*/
