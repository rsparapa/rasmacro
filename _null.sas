%put NOTE: You have called the macro _NULL, 2004-03-30.;
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

/*  _NULL Documentation
    Return the null device for your OS.  Only Unix and Windows are
    currently supported.
    
    NO Parameters
*/

%macro _null;

%_unwind(/dev/null, NUL:)

%mend _null;

%*VALIDATION TEST-STREAM;
/*un-comment to re-validate

%put Your OS is &sysscp and your null file is %_null;

%_printto(print=%_null);

proc contents data=work._all_;
title "This should NOT be in your output.";
run;

%_printto;

proc contents data=work._all_;
title "This should be in your output.";
run;

%_printto(log=%_null);

%put This should NOT be in your log.;

proc datasets lib=work;
run;

%_printto;

%put This should be in your log.;

proc datasets lib=work;
run;
*/
