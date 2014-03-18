%put NOTE: You have called the macro _LJ, 2004-03-30.;
%put NOTE: Copyright (c) 2001-2004 Rodney Sparapani;
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

/*  _LJ Documentation
    Left-justify text for the current linesize.
    
    POSITIONAL Parameters
    
    ARG1-ARG10      text to justify separated by commas, 
                    single/double quotes allowed but unnecessary
                    
    NAMED Parameters
    
    LS=%_LS         linesize to justify for, defaults to current linesize
                    
    MAX=10          defaults to the number of positional parameters
                    supported, if more are added, then update MAX=
                    accordingly                    
                    
    PAD=            the character used to justify, defaults to blank
*/

%macro _lj(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, max=10,
    pad=, ls=%_ls);

    %local i;

    %do i=1 %to &max;
	%let arg&i=%scan(&&arg&i, 1, ''"");
	%if &i>1 & %length(&&arg&i) %then %let arg1=&arg1, &&arg&i;
    %end;

    %let i=%length(&arg1);
    
    %if &i %then %do;
        %let ls=%eval(&ls-&i);
    
        "&arg1" %_pad(pad=&pad, ls=&ls)
    %end;
    
%mend _lj;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

proc print data=sashelp.voption(obs=1);
title1 %_lj(This is arg1, this is arg2, this is arg3, this is arg4);
title2 %_lj('This is arg1', "this is arg2", this is arg3, this is arg4);
title3 %_lj(This is arg1, this is arg2, this is arg3, this is arg4, pad=+);
title4 %_lj(This is arg1, this is arg2, this is arg3, this is arg4, ls=%_ls-%length(&sysdate)) "&sysdate";
title5 %_lj;
title6 %_lj(This is arg1, this is arg2, this is arg3, this is arg4, ls=-5);
run;

*/
