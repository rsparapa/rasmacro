%put NOTE: You have called the macro _DATATYP, 2008-10-29.;
%put NOTE: Copyright (c) 2008 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2008-02-27

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

/* _DATATYP Documentation
    Extend DATATYP to lists.  Note also that this gives us the
    opportunity to over-ride some faulty behaviors of DATATYP, 
    e.g. %DATATYP(1.)=CHAR while %_DATATYP(1.)=NUMERIC.  Other
    over-rides include missing values recognized as NUMERIC.
    In the future, more over-rides can be added as more bugs in
    %datatyp() are discovered providing us with a necessary
    replacement.  Also, %_datatyp has been hardened for various 
    types of character input.
    
    POSITIONAL Parameters  
            
    ARGS            arguments
    
    OPTIONAL Parameters
    
    SPLIT=\         split character           

    STRING=CHAR     default return code for a string literal
*/

%macro _datatyp(args, split=\, string=CHAR);

%local arg arg0 i j rc;

%if %_indexc(&args, ""'') %then %let rc=&string;
%else %do;
    %let i=0;
    %let arg0=%_count(&args, split=&split);

    %if &arg0>0 %then %do %until("&rc"="CHAR" | &i=&arg0);
        %let i=%eval(&i+1);
        %let arg=%qscan(&args, &i, &split);
        %let j=%length(&arg);

        %if (&j=1 | &j=2) & "%_substr(&arg, 1, 1)"="." %then %do;
            %if &j=1 |
                %index(ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789, %upcase(%_substr(&arg, 2, 1))) 
            
                %then %let rc=NUMERIC;
            %else %let rc=CHAR;
        %end;
        %else %if "%_substr(&arg, &j, 1)"="." & 
            "%datatyp(%bquote(&arg))"="CHAR" &
            "%datatyp(%bquote(%_substr(&arg, 1, &j-1)))"="NUMERIC" %then %let rc=NUMERIC;
        %else %let rc=%datatyp(%bquote(&arg));
    %end; 
%end;

&rc

%mend _datatyp;

%*VALIDATION TEST STREAM;

/* un-comment to re-validate
            
%put CHAR=%_datatyp("with space", split=%str( ));
%put CHAR=%_datatyp('with space', split=%str( ));
%put BLANK=%_datatyp();
%put CHAR=%_datatyp(with\space);
%put CHAR=%_datatyp(with space, split=%str( ));
%put NUMERIC=%_datatyp(1\2\3\4);
%put NUMERIC=%_datatyp(1 2 3 4, split=%str( ));
%put NUMERIC=%_datatyp(1.\2\3\4);
%put NUMERIC=%_datatyp(1. 2 3 4, split=%str( ));
%put NUMERIC=%_datatyp(.Z\2\3\4);
%put NUMERIC=%_datatyp(.Z 2 3 4, split=%str( ));
%put NUMERIC=%_datatyp(1.);
%put NUMERIC=%_datatyp(1., split=%str( ));
%put !NUMERIC!=%datatyp(1.);
            
*/
