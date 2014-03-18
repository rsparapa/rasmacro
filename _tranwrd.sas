%put NOTE: You have called the macro _TRANWRD, 2009-11-19;
%put NOTE: Copyright (c) 2009 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2009-10-07

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

/*  _TRANWRD Documentation
    The DATASTEP function TRANWRD().
    
    POSITIONAL Parameters
    
    ARG1        the text to be translated

    ARG2        the word to be replaced
                
    ARG3        the word to be substituted
*/

%macro _tranwrd(arg1, arg2, arg3);

%qsysfunc(tranwrd(&arg1, &arg2, &arg3))

%mend _tranwrd;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
%put %_tranwrd(please dont eat the daisies, dont, do);
%put %_tranwrd(please dont eat the daisies, do, do not);
*/
