%put NOTE: You have called the macro _XPORT, 2012-06-01.;
%put NOTE: Copyright (c) 2012 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2012-06-01

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

%macro _xport(data=REQUIRED, file=,
    attrib=, by=, firstobs=, drop=, keep=, obs=, rename=, sortedby=, where=, log=);

%_require(&data);

%if %length(&log) %then %_printto(log=&log);

%local in;

%let in=%_scratch;

%_sort(data=&data, out=&in, attrib=&attrib, by=&by, firstobs=&firstobs, drop=&drop,
    keep=&keep, obs=&obs, rename=&rename, sortedby=&sortedby, where=&where);
 
%if %length(&file)=0 %then %let file=&data..xpt;

libname out xport "&file";

proc copy in=work out=out;
    select &in / memtype=data;
run;

%if %length(&log) %then %_printto;

%mend _xport;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

data plants;
input type $ @;
infile cards missover;

do block=1 to 3;
	input stem @;
	output;
end;

cards;
clarion 32.7 32.3 31.5
clinton 32.1 29.7 29.1
knox    35.7 35.9 33.1
oneill 36.0 34.2 31.2
compost 31.8 28.0 29.2
wabash  38.2 37.8 31.9
webster 32.5 31.1 29.7
;
run;

%_xport(data=plants);

*/
