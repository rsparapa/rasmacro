/* jenner-check bundle t006_macro_unwind
   Source: _unwind.sas from rsparapa/rasmacro
   %_unwind is the library's OS-dispatch primitive: it picks one of up
   to six branches (Unix / DOS-OS2-Windows / Mac / VMS / CMS / MVS)
   based on the &sysscp automatic macro variable, so other macros in
   the library (e.g. _suffix, _dirchar) can stay platform-agnostic.
   Definition copied verbatim from upstream.
*/

%macro _unwind(arg1, arg2, arg3, arg4, arg5, arg6,
    unix=&arg1, dos=&arg2, os2=&dos, windows=&os2, mac=&arg3,
    vms=&arg4, cms=&arg5, mvs=&arg6);

%if "&sysscp"="WIN" | "&sysscp"="" | "&sysscp"="PC DOS" |
    "&sysscp"="OS2" %then &windows;
%else %if "&sysscp"="MAC" %then &mac;
%else %if "&sysscp"="VMS" | "&sysscp"="VMS_AXP" %then &vms;
%else %if "&sysscp"="CMS" %then &cms;
%else %if "&sysscp"="OS" %then &mvs;
%else &unix;

%mend _unwind;

/* caller adapted from the macro's own VALIDATION TEST STREAM comment */
%let platform=%_unwind(UNIX, WINDOWS, MAC);
%let dirsep=%_unwind(/, \, :);
%put PLATFORM=&platform (SYSSCP=&sysscp);
%put DIRSEP=&dirsep;

data work.platforminfo;
    length item $20 value $20;
    item = "sysscp";           value = "&sysscp"; output;
    item = "_unwind branch";   value = "&platform"; output;
    item = "dir separator";    value = "&dirsep"; output;
run;

proc print data=work.platforminfo noobs;
    title '_unwind dispatching on the engine''s SYSSCP automatic macro variable';
run;
