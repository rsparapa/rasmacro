%put NOTE: You have called the macro _BIBREF, 2016-02-26.;
%put NOTE: Copyright (c) 2011-2016 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2011-08-31

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

%macro _bibref(infile=REQUIRED, file=REQUIRED, debug=, nonotes=0,
    upcase=0, log=);

%_require(&file &infile);

%if %length(&log) %then %_printto(log=&log);

%local scratch i j reftype oldref newref badref;

%let scratch=%_scratch;

%if "&file"="&infile" %then x "dos2unix -o &file 2> /dev/null";
%else x "dos2unix -n &infile &file 2> /dev/null";;

x "dos2unix -c Mac -o &file 2> /dev/null";

proc format;
    value yearz
        .='YY'
        other=[z2.]
    ;
run;

data &scratch(index=(newref));
    length name name1 name2 oldref newref reftype $ 200;
    infile "&file";
    
    input @'@' oldref;

    if lowcase(oldref) in:('article', 'book', 'inbook', 'inproceedings', 'misc', 'techreport');   
    
    input @'author' @;
    input @'=' @;
    input @'{' @;
    input name &;      
    input @'year' @;
    input @'=' @;
    input @'{' @;
    input year 4.;
    
    drop i;
    
    obs=_n_;
    
    year=year-int(year/100)*100;
    
    reftype=scan(oldref, 1, '{');
    oldref=scan(oldref, 2, '{,');
            
    i=index(name, '},');
    
    if i then name=substr(name, 1, i-1);
            
    name=compress(name, '\"''{}');
    *name=compress(name, '\"{}');
    *name=compress(scan(name, 1, '}'), '\"{');
    
    i=index(name, ' and ');
    
    if i then do;
        name1=substr(name, 1, i-1);
        name2=trim(substr(name, i+5));
        
        i=index(name2, ' and ');
        
        if i then name2=substr(name2, 1, i-1);
        
        i=index(name1, ',');
        
        if i then newref=substr(compress(name1), 1, min(i-1, 4));
        else do;
            i=index(name1, '. ');

            if i then do; 
                name1=substr(name1, i+2);
                
                i=index(name1, '. '); 
    
                if i then name1=substr(name1, i+2);
            end;
            else do;
                if scan(name1, 3, ' ')>'' then name1=scan(name1, 3, ' ');
                else name1=scan(name1, 2, ' ');
            end;
            
            newref=substr(compress(name1), 1, min(length(compress(name1)), 4));
        end;
        
        i=index(name2, ',');
        
        if i then newref=trim(newref)||substr(compress(name2), 1, min(i-1, 4))||put(year, yearz2.);
        else do;
            i=index(name2, '. '); 
                
            if i then do;
                name2=substr(name2, i+2);
                i=index(name2, '. '); 
    
                if i then name2=substr(name2, i+2);
            end;
            else do;
                if scan(name2, 3, ' ')>'' then name2=scan(name2, 3, ' ');
                else name2=scan(name2, 2, ' ');
            end;
            
            newref=trim(newref)||substr(compress(name2), 1, min(length(compress(name2)), 4))||put(year, yearz2.);
        end;
    end;
    else do;
        name1=name;
        
        i=index(name, ',');
        
        if i then newref=substr(compress(name), 1, min(i-1, 4))||put(year, yearz2.);
        else do;
            i=index(name1, '. '); 
            
            if i then do;
                name1=substr(name1, i+2);
                i=index(name1, '. '); 
    
                if i then name1=substr(name1, i+2);
            end;
            else do;
                if scan(name1, 3, ' ')>'' then name1=scan(name1, 3, ' ');
                else name1=scan(name1, 2, ' ');
            end;
            
            newref=substr(compress(name1), 1, min(length(compress(name1)), 4))||put(year, yearz2.);
        end;
    end;
    
    if newref=:',' then newref='Anon'||put(year, yearz2.);
    else if length(newref)<=3 then do;
        _error_=0;
        
    %if %length(&debug) %then %do;
        put reftype=;
        put oldref=;
        put newref=;
    %end;

        delete;
    end;
run;

%let reftype=%_level(data=&scratch, var=reftype, unique=0, split=%str(,));
%let oldref=%_level(data=&scratch, var=oldref, split=%str(,));
%let newref=%_level(data=&scratch, var=newref, split=%str(,));

%if %_count(&oldref, split=%str(,))^=%_count(&newref, split=%str(,)) %then %do;
    %put WARNING: Mismatch between the number of RefWorks and BibTeX references.;
    %put WARNING: Most likely, the BibTeX references are not unique (see below).;
    %put WARNING: Taking defensive action, i.e. appending a-z;
    
    %let newref=%_level(data=&scratch, var=newref, unique=0, split=%str(,));
    
    %do i=1 %to %_count(&newref, split=%str(,));
        %local newref&i;
        
        %let newref&i=%scan(&newref, &i, %str(,));
        
        %if &i>1 %then %do;
            %let j=%eval(&i-1);
            
            %if "&&newref&i"="&&newref&j" %then %put &&newref&i;
        %end;
    %end;
    
    data &scratch;
        set &scratch;
        by newref;
        retain letter 'abcdefghijklmnopqrstuvwxyz';
        
        %_retain(var=dupe=0, by=newref);
        
        dupe+1;
        
        if not(first.newref & last.newref) then substr(newref, length(newref)+1, 1)=substr(letter, dupe, 1);
    run;

    %_sort(data=&scratch, out=&scratch, by=obs);
    
    %let reftype=%_level(data=&scratch, var=reftype, unique=0, split=%str(,));
    %let oldref=%_level(data=&scratch, var=oldref, split=%str(,));
    %let newref=%_level(data=&scratch, var=newref, split=%str(,));
%end;

/*
%if %length(&debug) %then %do;
    %put REFTYPE=&REFTYPE;
    %put OLDREF=&OLDREF;
    %put NEWREF=&newREF;
%end;
*/
    
data _null_;
    infile "&file" sharebuffers expandtabs lrecl=32767;
    file "&file";

%do i=1 %to %_count(&oldref, split=%str(,));
    %local reftype&i oldref&i newref&i;
    %let reftype&i=%scan(&reftype, &i, %str(,));
    %let oldref&i=%scan(&oldref, &i, %str(,));
    %let newref&i=%scan(&newref, &i, %str(,));
        
        input @"@&&reftype&i{&&oldref&i," @;
    
        put "@&&reftype&i{&&newref&i," %_pad(ls=%eval(%length(&&oldref&i)-%length(&&newref&i)));

        input;
%end;

run;

%* sed has no 1 or more wild card, +, so use \{1,\};

%* u diaresis;
x "sed 's/\\u\([^r][^l]\)/\\\""{u}\1/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

x "sed 's/\\{u}/\\\""{u}/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

%* o diaresis;
x "sed 's/\\o/\\\""{o}/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

x "sed 's/\\{o}/\\\""{o}/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

%* RefWorks uses underscores which LaTeX thinks are math mode subscript operators;
x "sed 's/ *<last_page> */-/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

x "sed 's/publication_type/publication-type/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

x "sed 's/full_text/full-text/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

/* too dangerous
%* RefWorks will occasionally produce imbalanced curly braces;
x "sed 's/{{/{/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

x "sed 's/}}/}/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";
*/

%if &nonotes %then %do;
%* RefWorks produces notes which are rarely wanted;    
x "sed 's/note={[^\\P]/OPTnote={/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";
%end;

%if &upcase %then %do;
%* RefWorks defaults to what BibTeX thinks is all lower case titles;
x "sed 's/title={\(.*\)}/title={{\1}}/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

x "sed 's/ *}}/}}/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

%* Journals that RefWorks will lower case by default;
x "sed 's/Statistics in medicine/Statistics in Medicine/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";

x "sed 's/Statistical methods in medical research/Statistical Methods in Medical Research/g' &file > &sysjobid..txt";
x "mv -f &sysjobid..txt &file";
%end;

%if %length(&log) %then %_printto;

%mend _bibref;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

%*_bibref(infile=~/Documents/0831refw.bib, file=~/Documents/0831.bib);
%_bibref(infile=~/Documents/laud-Export.txt, file=~/Documents/laud-Export.bib);

proc print;
    var year name1 name2 reftype oldref newref;
run;
            
*/

            
