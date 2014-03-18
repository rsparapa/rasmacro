%put NOTE: You have called the macro _FN, 2006-08-21.;
%put NOTE: Copyright (c) 2001-2006 Rodney Sparapani;
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

%global fn fndir fnpath fnroot fntext;

%macro _fn;
%if %length(&fn)=0 %then %do;
    %let fn=%sysfunc(getoption(sysin));

    %if %length(&fn) & "&fn"^="__STDIN__" %then %do;
        filename fn "&fn";
        %let fnpath=%sysfunc(pathname(fn));
        filename fn;

        %if %_exist(&fn)=0 %then %let fn=&fn..sas;

	%let fn=%_tail(&fn, split=%_dirchar);
        %let fnroot=%_head(&fn, split=.);
        %let fndir=%substr(&fnpath, 1, %length(&fnpath)-%length(&fn));
        %let fntext=&fnroot..txt;

        %put FN=&fn;
        %put FNROOT=&fnROOT;
        %put FNPATH=&fnpath;
        %put FNDIR=&fnDIR;
        %put FNTEXT=&FNTEXT;
    %end;
%end;
%mend _fn;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

%_fn;

*UNIX
Result should be:  FN=_fn.sas
Result should be:  FNROOT=_fn
Result should be:  FNPATH=/cvrct/sasmacro/_fn.sas
Result should be:  FNDIR=/cvrct/sasmacro/
;

*WINDOWS
Result should be:  FN=_FN.SAS
Result should be:  FNROOT=_FN
Result should be:  FNPATH=D:\SASMACRO\_FN.SAS
Result should be:  FNDIR=D:\SASMACRO\
;

*/
