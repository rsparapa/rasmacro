%put NOTE: You have called the macro _FOOT, 2005-06-24.;
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

/*  _FOOT Documentation   
    Store/restore GLOBAL SAS Macro variables from/to FOOTNOTEs.
    GLOBAL SAS Macro variables are created: FOOT1-FOOT10 for each
    footnote, LFOOT1-LFOOT10 are left-justified, CFOOT1-CFOOT10 are
    center-justified and RFOOT1-RFOOT10 are right-justified.  This SAS
    Macro is useful for storing footnotes when they need to be turned
    off temporarily and you can restore them when necessary.

    Named Parameters
    
    ACTION=STORE    by default, store the footnotes in GLOBAL 
                    SAS macro variables; ACTION=LOAD restores
                    previously stored footnotes
                    
    Common OPTIONAL Parameters
    
    LOG=
*/

%global %_list(foot0-foot10 lfoot1-lfoot10 cfoot1-cfoot10 rfoot1-rfoot10);

%macro _foot(action=store, log=);

%if %length(&log) %then %_printto(log=&log);
%let action=%upcase(&action);

%if "&action"="LOAD" %then %do;
    footnote1 "&foot1 ";
    footnote2 "&foot2 ";
    footnote3 "&foot3 ";
    footnote4 "&foot4 ";
    footnote5 "&foot5 ";
    footnote6 "&foot6 ";
    footnote7 "&foot7 ";
    footnote8 "&foot8 ";
    footnote9 "&foot9 ";
    footnote10 "&foot10 ";
%end;
%else %if "&action"="STORE" %then %do;
%if %_version(6.11) %then %do;
    %local i;

    %let foot0=0;
    %let foot1=; %let foot2=; %let foot3=; %let foot4=; %let foot5=;
    %let foot6=; %let foot7=; %let foot8=; %let foot9=; %let foot10=;
    %let lfoot1=; %let lfoot2=; %let lfoot3=; %let lfoot4=; %let lfoot5=;
    %let lfoot6=; %let lfoot7=; %let lfoot8=; %let lfoot9=; %let lfoot10=;
    %let cfoot1=; %let cfoot2=; %let cfoot3=; %let cfoot4=; %let cfoot5=;
    %let cfoot6=; %let cfoot7=; %let cfoot8=; %let cfoot9=; %let cfoot10=;
    %let rfoot1=; %let rfoot2=; %let rfoot3=; %let rfoot4=; %let rfoot5=;
    %let rfoot6=; %let rfoot7=; %let rfoot8=; %let rfoot9=; %let rfoot10=;
    
    data _null_;
        set sashelp.vtitle(firstobs=1 obs=max);
        where type='F';
        call symput("foot"||left(number), trim(text));
        call symput("foot0", trim(left(number)));
    run;

    %do i=1 %to &foot0;
	%if %length(%bquote(&&foot&i)) %then %do;
	   %let lfoot&i=%_lj(%bquote(&&foot&i));
  	   %let cfoot&i=%_cj(%bquote(&&foot&i));
           %let rfoot&i=%_rj(%bquote(&&foot&i));
	%end;
    %end;
%end;
%else %put ERROR: DICTIONARY.TITLES is only available in SAS 6.11 or higher.;
%end;
%if %length(&log) %then %_printto;

%mend _foot;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

footnote2 "This is footnote2";
footnote8 "This is footnote8";
footnote9 "This is footnote9";
footnote10 "test1=1, test2=2";

%_foot;

%put FOOT0=&foot0;
%put FOOT1=&foot1;
%put FOOT2=&foot2;
%put FOOT3=&foot3;
%put FOOT4=&foot4;
%put FOOT5=&foot5;
%put FOOT6=&foot6;
%put FOOT7=&foot7;
%put FOOT8=&foot8;
%put FOOT9=&foot9;
%put FOOT10=&foot10;
%put LFOOT1=&lfoot1;
%put LFOOT2=&lfoot2;
%put LFOOT3=&lfoot3;
%put LFOOT4=&lfoot4;
%put LFOOT5=&lfoot5;
%put LFOOT6=&lfoot6;
%put LFOOT7=&lfoot7;
%put LFOOT8=&lfoot8;
%put LFOOT9=&lfoot9;
%put LFOOT10=&lfoot10;

options symbolgen;
footnote1 &lfoot1;
footnote2 &lfoot2;
footnote3 &lfoot3;
footnote4 &lfoot4;
footnote5 &lfoot5;
footnote6 &lfoot6;
footnote7 &lfoot7;
footnote8 &lfoot8;
footnote9 &lfoot9;
footnote10 &lfoot10;

proc print data=sashelp.voption;
footnote;
run;

%_foot;

*/

