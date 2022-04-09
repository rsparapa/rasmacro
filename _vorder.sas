%put NOTE: You have called the macro _VORDER, 2022-02-12.;
%put NOTE: Copyright (c) 2006-2022 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2006-06-29

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

/*  _VORDER Documentation
    Re-order variables on a SAS DATASET.  Variables not listed
    are now kept (use to be dropped).
            
    REQUIRED Parameters
                
    OUT=            name of SAS DATASET to create
            
    VAR=            variable name to read and re-create 

    RASMACRO Dependencies
    _COUNT
    _LIST
    _REQUIRE
*/

%macro _vorder(data=&syslast, out=REQUIRED, var=REQUIRED);

%_require(&out &var);

%local i;

%*options dkricond=nowarn;

%let var=%_list(&var);

data &out;
    set &data; *to process dataset options if any;
run;

data &out;
    merge 
    %do i=1 %to %_count(&var); 
        &out(keep=%scan(&var, &i, %str( ))) 
    %end; &out;
run;

%*options dkricond=warn;

%mend _vorder;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

*/
