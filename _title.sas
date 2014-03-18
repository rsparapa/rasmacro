%put NOTE: You have called the macro _TITLE, 2005-06-24.;
%put NOTE: Copyright (c) 2001-2005 Rodney Sparapani;
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

/*  _TITLE Documentation
    Store/restore GLOBAL SAS Macro variables from/to TITLEs.
    GLOBAL SAS Macro variables are created: TITLE1-TITLE10 for each
    title, LTITLE1-LTITLE10 are left-justified, CTITLE1-CTITLE10 are
    center-justified and RTITLE1-RTITLE10 are right-justified.  This SAS
    Macro is useful for storing titles when they need to be turned
    off temporarily and you can restore them when necessary.


    Named Parameters
    
    ACTION=STORE    by default, store the titles in GLOBAL 
                    SAS macro variables; ACTION=LOAD restores
                    previously stored titles
                    
    Common OPTIONAL Parameters
    
    LOG=
*/

%global %_list(title0-title10 ltitle1-ltitle10 ctitle1-ctitle10 rtitle1-rtitle10);

%macro _title(action=store, log=);

%if %length(&log) %then %_printto(log=&log);
%let action=%upcase(&action);

%if "&action"="LOAD" %then %do;
    title1 "&title1 ";
    title2 "&title2 ";
    title3 "&title3 ";
    title4 "&title4 ";
    title5 "&title5 ";
    title6 "&title6 ";
    title7 "&title7 ";
    title8 "&title8 ";
    title9 "&title9 ";
    title10 "&title10 ";
%end;
%else %if "&action"="STORE" %then %do;
%if %_version(6.11) %then %do;
    %local i;
    %let title0=0;
    %let title1=; %let title2=; %let title3=; %let title4=; %let title5=;
    %let title6=; %let title7=; %let title8=; %let title9=; %let title10=;
    %let ltitle1=; %let ltitle2=; %let ltitle3=; %let ltitle4=; %let ltitle5=;
    %let ltitle6=; %let ltitle7=; %let ltitle8=; %let ltitle9=; %let ltitle10=;
    %let ctitle1=; %let ctitle2=; %let ctitle3=; %let ctitle4=; %let ctitle5=;
    %let ctitle6=; %let ctitle7=; %let ctitle8=; %let ctitle9=; %let ctitle10=;
    %let rtitle1=; %let rtitle2=; %let rtitle3=; %let rtitle4=; %let rtitle5=;
    %let rtitle6=; %let rtitle7=; %let rtitle8=; %let rtitle9=; %let rtitle10=;
    
    data _null_;
        set sashelp.vtitle(firstobs=1 obs=max);
        where type='T';
        call symput("title"||left(number), trim(text));
        call symput("title0", trim(left(number)));
    run;

    %do i=1 %to &title0;
	%if %length(%bquote(&&title&i)) %then %do;
	   %let ltitle&i=%_lj(%bquote(&&title&i));
  	   %let ctitle&i=%_cj(%bquote(&&title&i));
           %let rtitle&i=%_rj(%bquote(&&title&i));
	%end;
    %end;
%end;
%else %put ERROR: DICTIONARY.TITLES is only available in SAS 6.11 or higher.;
%end;

%if %length(&log) %then %_printto;

%mend _title;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

title2 "This is title2";
title8 "This is title8";
title9 "This is title9";

%_title;

%put TITLE0=&title0;
%put TITLE1=&title1;
%put TITLE2=&title2;
%put TITLE3=&title3;
%put TITLE4=&title4;
%put TITLE5=&title5;
%put TITLE6=&title6;
%put TITLE7=&title7;
%put TITLE8=&title8;
%put TITLE9=&title9;
%put TITLE10=&title10;
%put LTITLE1=&ltitle1;
%put LTITLE2=&ltitle2;
%put LTITLE3=&ltitle3;
%put LTITLE4=&ltitle4;
%put LTITLE5=&ltitle5;
%put LTITLE6=&ltitle6;
%put LTITLE7=&ltitle7;
%put LTITLE8=&ltitle8;
%put LTITLE9=&ltitle9;
%put LTITLE10=&ltitle10;

options symbolgen;
title1 &ctitle1;
title2 &ctitle2;
title3 &ctitle3;
title4 &ctitle4;
title5 &ctitle5;
title6 &ctitle6;
title7 &ctitle7;
title8 &ctitle8;
title9 &ctitle9;
title10 &ctitle10;

proc print data=sashelp.voption;
title;
run;

%_title;
*/
