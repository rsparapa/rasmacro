%put NOTE: You have called the macro _CATEXT, 2004-11-10.;
%put NOTE: Copyright (c) 2001-2004 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2001-08-21

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

%macro _catext(arg1, version=&arg1);

%if %length(&version) %then %do;
    %local i;
    %let version=%upcase(&version);

    %if %_substr(&version, 1, 1)=V %then %let version=%_substr(&version, 2);

    %let i=%index(&version, .);

    %if &i %then %let version=%_substr(&version, 1, &i-1)%_substr(&version, &i+1);

    %let version=&version%_repeat(0, 3-%length(&version));
    
    %if &version>=700 %then sas7bcat;
    %else %if &version=607 | &version=609 %then sct??;
    %else %if &version=608 | &version=610 %then sc2;
    %else %if &version=603 %then sct;
    %else %_unwind(sct??, sc2, sct??);
%end;
%else %do;
    %if %_version(7) %then sas7bcat;
    %else %_unwind(sct??, sc2, sct??);
%end;

%mend _catext;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

%put v6=%_catext(v6);
%put V6=%_catext(V6);
%put 6=%_catext(6);
%put 6.=%_catext(6.);
%put 6.0=%_catext(6.0);
%put 6.03=%_catext(6.03);
%put v6.03=%_catext(v6.03);
%put V6.03=%_catext(V6.03);
%put v603=%_catext(v603);
%put V603=%_catext(V603);
%put 6.04=%_catext(6.04);
%put 604=%_catext(604);
%put 6.06=%_catext(6.06);
%put 606=%_catext(606);
%put 6.07=%_catext(6.07);
%put 607=%_catext(607);
%put 6.08=%_catext(6.08);
%put 608=%_catext(608);
%put 6.09=%_catext(6.09);
%put 609=%_catext(609);
%put 6.10=%_catext(6.10);
%put 610=%_catext(610);
%put 6.11=%_catext(6.11);
%put 611=%_catext(611);
%put 6.12=%_catext(6.12);
%put 612=%_catext(612);
%put 7=%_catext(7);
%put 7.=%_catext(7.);
%put 8.=%_catext(8.);
%put 8.0=%_catext(8.0);
%put 80=%_catext(80);
%put 8.1=%_catext(8.1);
%put 81=%_catext(81);
%put 8.2=%_catext(8.2);
%put 82=%_catext(82);
%put 9.=%_catext(9.);
%put 9.0=%_catext(9.0);
%put 90=%_catext(90);

*/
