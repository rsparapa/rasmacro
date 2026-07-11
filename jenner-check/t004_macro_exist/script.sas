/* jenner-check bundle t004_macro_exist
   Source: _exist.sas from rsparapa/rasmacro
   %_exist is shorthand for %sysfunc(fileexist()) -- checks whether a
   given file (or fileref) exists on disk. Definition copied verbatim
   from upstream.
*/

%macro _exist(arg1);

%sysfunc(fileexist(&arg1))

%mend _exist;

/* caller: write a small file this session actually creates, then use
   %_exist (mirroring the macro's own VALIDATION TEST STREAM pattern) to
   confirm it now exists, alongside a name that should not exist */
data _null_;
    file "scratch_note.txt";
    put "written by t004_macro_exist";
run;

%put RC=%_exist(scratch_note.txt);
%put RC=%_exist(this_file_does_not_exist_anywhere);

data work.filechecks;
    length target $40 exists 8;
    target = "scratch_note.txt (just written)";      exists = %_exist(scratch_note.txt); output;
    target = "this_file_does_not_exist_anywhere";     exists = %_exist(this_file_does_not_exist_anywhere); output;
run;

proc print data=work.filechecks noobs;
    title '_exist checking a freshly-written file vs. a nonexistent one';
run;
