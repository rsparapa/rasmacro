%put NOTE: You have called the macro _ATTRIB, 2001-05-31.;
%put NOTE: Copyright (c) 2001 Rodney Sparapani;
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

%macro _attrib(data=&syslast, var=, format=1, label=1, length=1);

    %local i j count name var0 varfmt varlabel varlen;

    %let var=%upcase(%_list(&var));
    %let count=%_count(&var);

    %do j=1 %to &count;
        %local var&j;
        %let var&j=%scan(&var, &j, %str( ));
    %end;

    %let data=%sysfunc(open(&data));

    %do i=1 %to %sysfunc(attrn(&data, nvars));
        %let j=1;
        %let var0=;
	%let name=%upcase(%sysfunc(varname(&data, &i)));

        %if &count=0 %then %let var0=&name;
        %else %do %until(%length(&var0) | &j>&count);
            %if &name=&&var&j %then %let var0=&name;
            %let j=%eval(&j+1);
        %end;

        %if %length(&var0) %then %do;
            %if &format %then %do;
                %let varfmt=%sysfunc(varfmt(&data, &i));
                %if %length(&varfmt) %then %let varfmt=FORMAT=&varfmt;
            %end;

            %if &label %then %do;
                %let varlabel=%sysfunc(varlabel(&data, &i));
                %if %length(&varlabel) %then %let varlabel=LABEL="&varlabel";
            %end;

            %if &length %then %do;
                %let varlen=%sysfunc(vartype(&data, &i));

                %if &varlen=C %then %let varlen=$;
                %else %let varlen=;
                
                %let varlen=LENGTH=&varlen%sysfunc(varlen(&data, &i));
            %end;

            %if %length(&varfmt) | %length(&varlabel) | %length(&varlen) %then
                &var0 &varfmt &varlabel &varlen;
        %end;
    %end;

    %let i=%sysfunc(close(&data));

%mend _attrib;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

proc format;
    value test
        0='A'
        1='B'
    ;

    value $test
        '0'='A'
        '1'='B'
    ;
run;

data;

label x='Label of variable X';
format x best7. y $test. z;
z=.;
output;

run;

data;
*y='y';
attrib %_attrib(data=data1);
output;
run;

data;
*y='y';
attrib %_attrib(data=data1,var=y z w);
output;
run;

*/
