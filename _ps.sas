%put NOTE: You have called the macro _PS, 2004-03-30.;
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

/* _PS Documentation
    Returns the current setting for PS, i.e. PAGESIZE.
    Shorthand for %SYSFUNC(GETOPTION(PAGESIZE))
            
    NO Parameters  
*/

%macro _ps;
    %sysfunc(getoption(pagesize))
%mend _ps;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

options ps=60;
%put PS=%_ps;
options ps=44;
%put PS=%_ps;

*/
