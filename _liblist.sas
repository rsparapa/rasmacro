%put NOTE: You have called the macro _LIBLIST, 2015-10-21.;
%put NOTE: Copyright (c) 2015 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2015-08-11

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

%macro _liblist(libname=REQUIRED, lib=&libname, log=);

%global _liblist;

%_require(&lib);

%if %length(&log) %then %_printto(log=&log);

%local dir files i;

%let dir=%sysfunc(pathname(&lib));

%_fileref(fileref=_liblist, file=%_dir(&dir)*.%scan(%_suffix(), 1, %str( )), out=files);

%let files=%_level(data=files, var=file, split=:);

/*
%let _liblist=%_level(data=files, var=file, split=:);

%_fileref(fileref=_liblist, file=%_dir(&dir)*.%scan(%_suffix(), 3, %str( )), out=files);

%let files=&_liblist%_level(data=files, var=file, split=:);
*/

%let _liblist=;

%do i=1 %to %_count(&files, split=:);
    %let _liblist=&_liblist &lib..%_lib(%_tail(%scan(&files, &i, :), split=%_dirchar()));
%end;

%if %length(&log) %then %_printto;

%mend _liblist;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

libname phi '/data/phi/rsparapa/sas/libname/phi';

%_liblist(lib=phi);

%put &_liblist;

*/
