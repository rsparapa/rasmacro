/* jenner-check bundle t002_macro_ifelse
   Source: _ifelse.sas from rsparapa/rasmacro
   %_ifelse handles boolean expressions containing equal signs, which
   trip up the macro processor if passed positionally (they read as
   invalid parameter names). Definition copied verbatim from upstream.
*/

%macro _ifelse(arg1, arg2, arg3, if=&arg1, then=&arg2, else=&arg3);

%if &if %then &then;
%else &else;

%mend _ifelse;

/* caller adapted from the macro's own VALIDATION TEST STREAM comment */
%let j=5;

%put RESULT=%_ifelse(if=&j=5, then=true, else=false);
%put RESULT=%_ifelse(%eval(&j=5), true, false);

/* _ifelse resolves at macro-compile time, so drive it from a macro loop
   over literal values (its documented use case) rather than a DATA step
   variable, then land the per-value verdicts into a dataset to print. */
%macro classify;
data work.classify;
    length n 8 verdict $8;
    %local i n;
    %let i=1;
    %do %while(%length(%scan(5 -3 0 17 -1, &i, %str( ))));
        %let n=%scan(5 -3 0 17 -1, &i, %str( ));
        n=&n;
        verdict="%_ifelse(if=%eval(&n>=0), then=nonneg, else=neg)";
        output;
        %let i=%eval(&i+1);
    %end;
run;
%mend classify;
%classify;

proc print data=work.classify noobs;
    title '_ifelse-driven classification of a small dataset';
run;
