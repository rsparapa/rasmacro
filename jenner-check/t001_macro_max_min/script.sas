/* jenner-check bundle t001_macro_max_min
   Source: _max.sas, _min.sas from rsparapa/rasmacro
   These are two-parameter macro-language functions mirroring the DATA
   step MAX()/MIN() functions, but usable at macro-compile time (e.g.
   inside %IF conditions before any data step runs). Definitions below
   are copied verbatim from the upstream files; only the trailing
   validation-test-stream comments (already present in the source) are
   exercised as live %PUT calls instead of staying commented out.
*/

%macro _max(arg1, arg2);
    %if %length(&arg2)=0 %then %eval(&arg1);
    %else %if %length(&arg1)=0 %then %eval(&arg2);
    %else %if (&arg1)>=(&arg2) %then %eval(&arg1);
    %else %eval(&arg2);
%mend _max;

%macro _min(arg1, arg2);
    %if %length(&arg2)=0 %then %eval(&arg1);
    %else %if %length(&arg1)=0 %then %eval(&arg2);
    %else %if (&arg1)<=(&arg2) %then %eval(&arg1);
    %else %eval(&arg2);
%mend _min;

/* caller exercising the macros' own documented validation stream */
%put MAX=%_max(7+2, 8);
%put MAX=%_max(9);
%put MAX=%_max( , 9);

%put MIN=%_min(7+2, 8);
%put MIN=%_min(9);
%put MIN=%_min( , 9);

/* _max/_min resolve at macro-compile time, so drive them from a macro
   loop over literal values (as the macros' own documented parameters
   expect) rather than DATA step variables. */
%macro clip_report;
data work.bounds;
    length label $12 lo hi 8 clipped_lo clipped_hi 8;
    %local i lbl raw_lo raw_hi;
    %let i=1;
    %do %while(%length(%scan(temp1|-5|120 temp2|10|80 temp3|-20|200 temp4|15|60 temp5|0|100, &i, %str( ))));
        %let lbl=%scan(%scan(temp1|-5|120 temp2|10|80 temp3|-20|200 temp4|15|60 temp5|0|100, &i, %str( )), 1, |);
        %let raw_lo=%scan(%scan(temp1|-5|120 temp2|10|80 temp3|-20|200 temp4|15|60 temp5|0|100, &i, %str( )), 2, |);
        %let raw_hi=%scan(%scan(temp1|-5|120 temp2|10|80 temp3|-20|200 temp4|15|60 temp5|0|100, &i, %str( )), 3, |);
        label="&lbl"; lo=&raw_lo; hi=&raw_hi;
        clipped_lo=%_max(&raw_lo, 0);
        clipped_hi=%_min(&raw_hi, 100);
        output;
        %let i=%eval(&i+1);
    %end;
run;
%mend clip_report;
%clip_report;

proc print data=work.bounds noobs;
    title '_max/_min clipping bounds to [0,100]';
run;
