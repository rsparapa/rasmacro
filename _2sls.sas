%put NOTE: You have called the macro _2SLS, 2014-08-30.;
%put NOTE: Copyright (c) 2009-2014 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2009-01-23

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

%macro _2sls(data=&syslast, out=REQUIRED, by=, t=REQUIRED, x=REQUIRED, 
    y=REQUIRED, z=REQUIRED, attrib=, classx=, classz=, 
    class1=&classx &classz, class2=&classx, where=, where1=&where, 
    link=, repeated=, subject=&repeated, log=, stage1=, stage2=,
    title=);

%_require(&out &by &t &x &y &z);

%if %length(&log) %then %_printto(log=&log);

%local scratch scratch1 scratch2 i j conf inst;
%let scratch=%_scratch;
%let z=%lowcase(%_list(&z)); %*21AUG14;
%let x=%lowcase(%_list(&x)); %*21AUG14;
     
%if %length(&title)=0 %then %do;
    %_title;
    %let title=%eval(&title0+1);
%end;

%do i=1 %to %_count(&z);
    %local inst&i;
    %let inst&i=%scan(&z, &i, %str( ));

    %if %index(&&inst&i, *) %then %do j=1 %to %_count(&&inst&i, split=*);
        %if %_indexw(&inst, %scan(&&inst&i, &j, *))=0 %then
            %let inst=&inst %scan(&&inst&i, &j, *);
    %end;    
    %else %if %index(&&inst&i, |) %then %do j=1 %to %_count(&&inst&i, split=|);
        %if %_indexw(&inst, %scan(&&inst&i, &j, |))=0 %then
            %let inst=&inst %scan(&&inst&i, &j, |);
    %end;
    %else %if %_indexw(&inst, &&inst&i)=0 %then %let inst=&inst &&inst&i;
%end;

%do i=1 %to %_count(&x);
    %local conf&i;
    %let conf&i=%scan(&x, &i, %str( ));

    %if %index(&&conf&i, *) %then %do j=1 %to %_count(&&conf&i, split=*);
        %if %_indexw(&conf, %scan(&&conf&i, &j, *))=0 & 
            "%scan(&&conf&i, &j, *)"^="hat_&t" %then
            
            %let conf=&conf %scan(&&conf&i, &j, *);
    %end;    
    %else %if %index(&&conf&i, |) %then %do j=1 %to %_count(&&conf&i, split=|);
        %if %_indexw(&conf, %scan(&&conf&i, &j, |))=0 %then
            %let conf=&conf %scan(&&conf&i, &j, |);
    %end;
    %else %if %_indexw(&conf, &&conf&i)=0 %then %let conf=&conf &&conf&i;
%end;
   
data &scratch;
    set &data;
    keep &by &class1 &class2 &t &conf &y &inst %scan(&subject, 1, /);
    attrib &attrib;
    where n(&y, &t, %_list(&conf, split=%str(,)), %_list(&inst, split=%str(,)))=%eval(2+%_count(&conf)+%_count(&inst))
    %if %length(&where) %then & &where;;
run;

%let conf=;

%do i=1 %to %_count(&x);
    %let conf&i=%scan(&x, &i, %str( ));

    %if %index(&&conf&i, *hat_&t)=0 & %index(&&conf&i, hat_&t*)=0 %then %let conf=&conf &&conf&i;
%end;
            
%let scratch1=%_scratch;
    
proc glm &stage1 noprint data=&scratch outstat=&scratch1(where=(_type_='SS1'));
    %*where &where1;
    class &class1;
    model &t=&conf / solution;
run; 
 
proc univariate noprint data=&scratch1;
    var df ss;
    output out=&scratch1 sum=df ss;
run;

%let scratch2=%_scratch;

title&title 'Stage 1';
proc glm &stage1 data=&scratch outstat=&out(where=(_type_^='SS3'));
    %*where &where1;
    class &class1;
    model &t=&z &conf / solution;
    output out=&scratch2(keep=&by hat_&t) predicted=hat_&t;
run;   
     
proc univariate noprint data=&out;
    var df ss;
    by _type_;
    output out=&out sum=df ss;
run;

data &out;
    merge 
        &scratch1(rename=(ss=ss_reduced df=df_reduced))
        &out(where=(_type_='SS1')   rename=(ss=ss_full df=df_full))
        &out(where=(_type_='ERROR') rename=(ss=ss_error df=df_error))
    ;
    drop _type_;

    partial_f=(ss_full-ss_reduced)*df_error/((df_full-df_reduced)*ss_error);
run;

proc print data=&out;
run;

/*
proc gplot;
    plot &t*hat_&t;
run;
quit;

proc univariate plot;
    var hat_&t;
    id &by;
run;
*/

data &scratch;
    merge &scratch2 &scratch;
    by &by;
    
    output;

    &y=.;
    hat_&t=&t;
    output;
run;

title&title 'Stage 2';
%if %length(&subject) %then %do;
proc genmod &stage2;
    class &class2 %scan(&subject, 1, /);
    model &y=hat_&t &x / type3 %if %length(&link) %then link=&link;;
    repeated subject=&subject;
    make 'Type3' out=&out;
    output out=&scratch predicted=hat_&y;
run;    
%end;
%else %do;
proc glm &stage2 outstat=&out;
    class &class2;
    model &y=hat_&t &x / solution;
    output out=&scratch predicted=hat_&y;
run;    
%end;

data &scratch;
    merge 
        &scratch(keep=hat_&y &y rename=(hat_&y=ivhat_&y) where=(nmiss(&y))) 
        &scratch(where=(n(&y)))
    ;
    
    resid=&y-hat_&y;
    ivresid=&y-ivhat_&y;
run;
    
proc univariate noprint;
    var resid ivresid;
    output out=&scratch css=sse ivsse;
run;

%if %length(&subject) %then %do;
data &out;
    set &out;
    
    if _n_=1 then set &scratch point=_n_;
    
    iv=sse/ivsse;
run;
%end;
%else %do;
data &out;
    set &out;
    retain iv ddf;
    drop iv ddf sse ivsse;
    
    if _n_=1 then do;
        set &scratch point=_n_;
        ddf=df;
        iv=ss/ivsse;
        ivf=iv;
    end;
    else do;
        if _type_='SS1' then delete;
        
        ivf=iv*f;
        ivprob=1-probf(ivf, df, ddf);
    end;
run;
%end;

proc print data=&out;
run;

title&title;

%if %length(&log) %then %_printto;

%mend _2sls;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/
