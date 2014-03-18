%put NOTE: You have called the macro _PAD, 2004-03-30.;
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

/*  _PAD Documentation
    Pad text to the current linesize.
    
    POSITIONAL Parameters
    
    ARG1=           the character used to justify, defaults to blank
                    
    NAMED Parameters
    
    LS=%_LS         linesize to justify for, defaults to current linesize
                    
    PAD=ARG1        alias
*/

%macro _pad(arg1, pad=&arg1, ls=%_ls);

%if %eval(&ls)>0 %then %do;
    %local i x return;

    %let i=%length(&pad);
    
    %if &i %then %do;
        %let x=%upcase(%scan(&pad, 2, ''""));
        %let pad=%scan(&pad, 1, ''"");
    %end;
    %else %do;
        %let pad=20;
        %let x=X;
    %end;

    %let i=%length(&pad);
    
    %if &x=X %then %let i=%eval(&i/2);
    
    %do i=1 %to &ls %by &i;
        %let return=&return.&pad;
    %end;
    
    "&return"&x
%end;

%mend _pad;
    
%*put PAD=%_pad(, ls=10);
