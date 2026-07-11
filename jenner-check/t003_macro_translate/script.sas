/* jenner-check bundle t003_macro_translate
   Source: _translate.sas from rsparapa/rasmacro
   %_translate is a thin macro-language wrapper around the DATA step
   TRANSLATE() function, letting %-code substitute characters without
   dropping into a data step. Definition copied verbatim from upstream.
*/

%macro _translate(arg1, arg2=, arg3=, to=&arg2, from=&arg3);

%qsysfunc(translate(&arg1, &to, &from))

%mend _translate;

/* caller adapted from the macro's own VALIDATION TEST STREAM comment
   (which calls the sibling/deprecated _tr, exercised here via _translate) */
%put %_translate(please dont eat the daisies, from=eai, to=xyz);
%put %_translate(please_dont_eat_the_daisies, from=_ai, to=...);

data work.scrubbed;
    length raw $40 cleaned $40;
    raw = "please dont eat the daisies";      cleaned = "%_translate(please dont eat the daisies, from=eai, to=xyz)"; output;
    raw = "please_dont_eat_the_daisies";      cleaned = "%_translate(please_dont_eat_the_daisies, from=_ai, to=...)"; output;
    raw = "rasmacro-rsparapani";              cleaned = "%_translate(rasmacro-rsparapani, from=-, to=_)"; output;
run;

proc print data=work.scrubbed noobs;
    title '_translate applied to a few sample strings';
run;
