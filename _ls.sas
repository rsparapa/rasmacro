%put NOTE: You have called the macro _LS, 2004-03-30.;
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

/* _LS Documentation
    Returns the current setting for LS, i.e. LINESIZE.
    Shorthand for %SYSFUNC(GETOPTION(LINESIZE))
            
    NO Parameters  
*/

%macro _ls;
    %sysfunc(getoption(linesize))
%mend _ls;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

options ls=80;
%put LS=%_ls;
options ls=120;
%put LS=%_ls;

*/
