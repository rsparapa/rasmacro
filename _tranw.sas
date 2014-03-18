%put NOTE: You have called the macro _TRANW, 2014-01-08;
%put NOTE: Copyright (c) 2014 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2014-01-08

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

/*  _TRANW Documentation
    Replaces all occurrences of a word in a character string. 
    Similar to the DATASTEP function TRANWRD, but instead 
    behaves like INDEXW(), i.e. words rather than strings.
    
    POSITIONAL Parameters
    
    ARG1        the text to be translated

    ARG2        the word to be replaced
                
    ARG3        the word to be substituted
*/

%macro _tranw(arg1, arg2, arg3);

%local i;

%do %until(&i=0);
    %let i=%_indexw(&arg1, &arg2);
    
    %if &i %then %let arg1=%_substr(&arg1, 1, &i-1)&arg3%_substr(&arg1, &i+%length(&arg2));
    %*put &i &arg1;
%end;
&arg1
%mend _tranw;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
%put %_tranw(please dont eat the daisies, dont, do);
%put %_tranw(please dont eat the daisies, do, do not);
*/
