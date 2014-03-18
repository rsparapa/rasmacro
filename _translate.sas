%put NOTE: You have called the macro _TRANSLATE, 2009-10-07.;
%put NOTE: Copyright (c) 2001-2009 Rodney Sparapani;
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

/*  _TRANSLATE Documentation
    The DATASTEP function TRANSLATE().
    
    POSITIONAL Parameters
    
    ARG1        the text to be translated

    ARG2        the characters to be substituted
                
    ARG3        the characters to be replaced
                
    NAMED Parameters
    
    FROM=       the characters to be translated from
    
    TO=         the characters to be translated to
*/

%macro _translate(arg1, arg2=, arg3=, to=&arg2, from=&arg3);

%qsysfunc(translate(&arg1, &to, &from))

%mend _translate;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
%put %_tr(please dont eat the daisies,from=eai,to=xyz);
%put %_tr(please_dont_eat_the_daisies,from=_ai,to=...);
*/
