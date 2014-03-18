%put NOTE: You have called the macro _SCRUB, 2013-05-15.;
%put NOTE: Copyright (c) 2001-2013 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2001-00-00
Version: 2001-05-25

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

%macro _scrub(arg0, var=&arg0, low=1, lo=&low, high=1, hi=&high, remove=, to=, from=);
    %local i xremove xto xfrom;
    %let var=%_list(&var);

    %if &remove="" | &remove='' | &remove=''"" | &remove=""'' %then;
    %else %do;
        %let xremove=%scan(&remove, 2, ''"");
        %let remove=%scan(&remove, 1, ''"");
    %end;

    %let xto=%scan(&to, 2, ''"");
    %let to=%scan(&to, 1, ''"");

    %let xfrom=%scan(&from, 2, ''"");
    %let from=%scan(&from, 1, ''"");
    
    %if %length(&from) %then %do;
        %if %length(&to)=0 %then %do;
            %let to=%length(&from);

            %if %upcase(&xfrom)=X %then %let to=%eval(&to/2);

            %let to=%_pad(ls=&to);
        %end;
        %else %let to="&to"&xto;

        %let from="&from"&xfrom;
    %end;
        
    %do i=1 %to %_count(&var);
        %local var&i;
        %let var&i=%scan(&var, &i, %str( ));

        %if %length(&remove) %then
            &&var&i=compress(&&var&i, "&remove"&xremove);;

        %if %length(&from) %then
            &&var&i=translate(&&var&i, &to, &from);;

        %if &lo %then
            &&var&i=translate(&&var&i, repeat(' ', 31), collate(0, 31));;

        %if &hi %then 
            &&var&i=translate(&&var&i, repeat(' ', 128), collate(127, 255));;
    %end;
%mend _scrub;
            
%*VALIDATION TEST STREAM;

/* un-comment to re-validate

data _null_;
    length y $ 6;
    
    y='	1234';
    put y=;
    %_scrub(y, from='33'x);
    put y=;
    %_scrub(y, from=2);
    put y=;
    
    y='12"3"4';
    %_scrub(y, remove="");
    put y=;
run;
    
*/


