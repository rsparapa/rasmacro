%put NOTE: You have called the macro _MIN, 2017-11-08.;
%put NOTE: Copyright (c) 2001-2017 Rodney Sparapani;
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

/*  _MIN Documentation
    Two-parameter function similar to the DATASTEP function MIN(),
    i.e. if only one expression is supplied, then it is the min.
    
    POSITIONAL Parameters
    
    ARG1-ARG2   the two expressions to compare
*/

%macro _min(arg1, arg2);
    %if %length(&arg2)=0 %then %eval(&arg1);
    %else %if %length(&arg1)=0 %then %eval(&arg2);
    %else %if (&arg1)<=(&arg2) %then %eval(&arg1);
    %else %eval(&arg2);
%mend _min;

/*
%put MIN=%_min(7+2, 8);
%put MIN=%_min(9);
%put MIN=%_min( , 9);
%put MIN=%_min(g, 9);
%put MIN=%_min(a, b);
*/
