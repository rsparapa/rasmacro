%put NOTE: You have called the macro _PDFJAM, 2018-01-02.;
%put NOTE: Copyright (c) 2017-2018 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2017-00-00

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

%macro _pdfjam(file=, root=, ext=pdf, options=--landscape --paper letter,
    debug=2> /dev/null);

%local i list;

%if %length(&file)>0 %then %do;
    %let root=%scan(&file, 1, .);
    %let ext=%scan(&file, 2, .);
%end;

%if %length(&root)=0 %then %do;
    %_fn;
    %let root=&fnroot;
%end;

%*put FILENAME=&root..&ext;

%if %_exist(&root..&ext) %then %do;
    %let list=;
    %let i=1;

    %do %while(%_exist(&root.&i..&ext));
        %let list=&list &root.&i..&ext;
        %let i=%eval(&i+1);
        %end;

    %if &i=1 %then 
        %put NOTE: graphics records written to &root..&ext;
    %else %do;
        x "pdfjam &options -o &root..pdf &root..&ext &list &debug";
        %if "&ext"="pdf" %then x "rm &list";
        %else x "rm &root..&ext &list";;

        %if %_exist(&root..pdf) %then
            %put NOTE: graphics records written to &root..pdf;;
    %end;
%end;

%mend _pdfjam;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/
