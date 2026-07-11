/* jenner-check bundle t005_macro_repeat
   Source: _repeat.sas from rsparapa/rasmacro
   %_repeat is documented as a variant of the DATA step REPEAT()
   function that returns one fewer repeat than REPEAT() itself -- a
   more natural way to think about "repeat this string N times".
   Definition copied verbatim from upstream.
*/

%macro _repeat(arg1, arg2);

%if &arg2>0 %then %sysfunc(repeat(&arg1, &arg2-1));

%mend _repeat;

/* caller adapted from the macro's own commented examples */
%let two=%_repeat(0, 2);
%let one=%_repeat(0, 1);
%let zero=%_repeat(0, 0);
%put TWO=&two;
%put ONE=&one;
%put ZERO=&zero;

%let pad5=%_repeat(0, 5);
%let pad3=%_repeat(-, 3);
%let pad0=%_repeat(x, 0);

data work.padded;
    length label $12 padded $20;
    label = "pad to 5 zeros"; padded = "&pad5.9"; output;
    label = "pad to 3 dashes"; padded = "&pad3.|"; output;
    label = "no repeat"; padded = "&pad0.done"; output;
run;

proc print data=work.padded noobs;
    title '_repeat used to left-pad a few sample values';
run;
