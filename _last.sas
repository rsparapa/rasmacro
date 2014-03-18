%put NOTE: You have called the macro _LAST, 2004-03-30.;
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

/*  _LAST Documentation
    Generate a logical expression that is true for the last observation 
    for each BY-group, if any, otherwise the last observation only.
    Useful for writing SAS Macros that will allow BY-group processing.
    
    POSITIONAL Parameters
    
    ARG1        a list of variables as they would appear in a
                BY statement, if any

    NAMED Parameters
    
    END=END     name given to the temporary variable END= on a 
                INFILE/SET/MERGE/UPDATE statement, if any
*/

%macro _last(arg1, end=end);

%local arg0;

%let arg1=%_by(&arg1);
%let arg0=%_count(&arg1);

(
%if &arg0 %then last.%scan(&arg1, &arg0, %str( ));
%else &end;
)

%mend _last;
