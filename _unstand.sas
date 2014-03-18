%put NOTE: You have called the macro _UNSTAND, 2003-04-03.;
%put NOTE: Copyright (c) 2003 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2003-02-19

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

%global sysfuncran;

%macro _unstand(mean=, std=, loc=&mean, scale=&std, upper=, lower=, var=, 
    funcran=&sysfuncran);

%if %length(&loc) | %length(&scale) | %length(&lower) | %length(&upper) %then %do;
    %if %length(&funcran)=0 %then &var=;
    %if %length(&loc)       %then (&loc)+;
    %if %length(&scale)     %then (&scale)*;

    %if %length(&lower) %then (&lower)+;

    %if %length(&upper) %then %do;
        %if %length(&lower) %then ((&upper)-(&lower))*;
        %else (&upper)*;
    %end;

    %if %length(&funcran)=0 %then &var;
%end;

%mend _unstand;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
        
data rannor;
    seed=1;

    do i=1 to 10000;
        %_rannor(var=x, seed=seed);
        %_unstand(var=x, mean=10, std=5);
        output;
    end;
run;

proc univariate plot;
    var x;
run;

*/
