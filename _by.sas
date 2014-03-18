%put NOTE: You have called the macro _BY, 2005-03-25.;
%put NOTE: Copyright (c) 2001-2005 Rodney Sparapani;
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

/*  _BY Documentation
    Passes a list of variables with or without keywords
    DESCENDING and NOTSORTED depending on the situation;
    GROUPFORMAT is never passed.
    
    POSITIONAL Parameters
    
    ARG1        the list of variables including keywords, if any
                
    NAMED Parameters
    
    PROC=0      defaults to not passing the keywords
                DESCENDING and NOTSORTED, i.e. assume
                that we are not dealing with a PROC
                setting PROC= to something else or
                nothing means to pass DESCENDING and
                NOTSORTED since we are dealing with 
                a PROC that understands them
*/
    
%macro _by(arg1, proc=0);

%local arg0 i;

%let arg1=%upcase(%_list(&arg1));

%do i=1 %to %_count(&arg1);
    %let arg0=%scan(&arg1, &i, %str( ));

    %if "&arg0"^="GROUPFORMAT" %then %do;
        %if &proc=0 %then %do;
             %if "&arg0"^="DESCENDING" & "&arg0"^="NOTSORTED" %then &arg0;
        %end;
        %else &arg0;
    %end;
%end;

%mend _by;
