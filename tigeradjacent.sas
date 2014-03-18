%put NOTE: You have called the macro TIGERADJACENT, 2008-05-22;
%put NOTE: Copyright (c) 2008 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2008-05-21

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
    
/*  TIGERADJACENT Documentation
    Takes a SAS DATASET with with regions in one state and creates a 
    SAS DATASET with adjacency information for those regions based on
    TIGER/Line file information
    
    REQUIRED Parameters
    
    DIR=            the directory containing the TIGER/Line files
                    and imported geocoding SAS CATALOG and 
                    SAS DATASETS
                    
    FILE=           file to create to export adjacency information 
    
    OUT=            the SAS DATASET to be created
                
    TYPE=           either TRACT, ZIP3 or ZIP
                    (TIGER/Line files have real ZIPs, not ZCTAs)
                       
    NAMED Parameters
    
    DATA=_LAST_     default SAS DATASET to be used
     
    APPEND=         if specified, append to a file, rather than create
                    see FILE= below

    AREA=AREA       numeric variable to create indexing the areas
                    
    CLOSE=1         defaults to close, set to 0 to leave FILE= open 

    MAP=            Optional state postal code of state to use
    
    VAR=            the name of the variable in the input SAS DATASET
                    that represents region, defaults to the value 
                    assigned to TYPE= above
                    TYPE set to ZIP or ZIP3 results in the VAR=
		    variable being handled as a character variable

    WEIGHT=1        default weights for the adjacency matrix

    Common OPTIONAL Parameters
                    
    See _SORT documentation
*/

%macro tigeradjacent(data=&syslast, dir=REQUIRED, out=REQUIRED, type=REQUIRED, 
    append=REQUIRED, area=area, close=1, file=&append, var=&type, weight=1, map=, 
    attrib=, by=, drop=, firstobs=, if=, keep=, obs=, rename=, sort=, sortseq=, 
    where=); 

%_require(&dir &file &out &type);

%local dirchar fips scratch nobs maxarea maxnum;

%let type=%upcase(&type);
%let var=%upcase(&var);

%_sort(data=&data, out=&out, attrib=&attrib, by=&by, drop=&drop, 
    firstobs=&firstobs, if=&if, keep=&keep, obs=&obs, rename=&rename, 
    sort=&sort, sortseq=&sortseq, where=&where);

%if "&type"="ZIP" %then %do;    
    data &out;
        set &out;
        drop &var;
        keep num&var;
        rename num&var=zip;
        where length(&var)=5;
        
        num&var=input(&var, 5.);
    run;
        
    %let var=ZIP;
%end;
%else %if "&type"="ZIP3" %then %do;    
    data &out;
        set &out;
        drop &var;
        keep num&var;
        rename num&var=zip;
        where length(&var)>=3;
        
        num&var=input(substr(&var, 1, 3), 3.)*100;
    run;
        
    %let var=ZIP;
%end;
%else %do;
    data &out;
        set &out;
        keep &var;
        where n(&var);
    run;    
%end;

%_sort(data=&out, out=&out, by=&var, sort=nodupkey, index=&var/unique);

libname street "&dir";    

%let dirchar=%_dirchar; %* directory character for this OS;

%if %length(&map)=0 %then %do;
    %let i=1;
    
    %do %until(&i=57 | %length(&fips));
        %if &i<10 & %_exist(&dir.&dirchar.COUNTS_0&i..TXT) %then %let fips=0&i;
        %else %if &i>=10 & %_exist(&dir.&dirchar.COUNTS_&i..TXT) %then %let fips=&i;
    
        %let i=%eval(&i+1);
    %end;

    %if %length(&fips)=0 %then %put ERROR: DIR=&dir choice invalid.;
    %else %let map=%sysfunc(fipstate(&fips));
%end;
%else %let fips=%sysfunc(stfips(&map)); %* 2-digit FIPS state code;

%if %_dsexist(street.tigerc) %then %do;
    %let scratch=%_scratch;
        
    data &scratch;
        set street.tigerc(keep=statel stater &var.l &var.r);
        keep &var &var.adj;
        where statel=stater & &var.l>0 & &var.r>0 &
        %if "&type"="ZIP" | "&type"="ZIP3" %then 
            zipfips(put(zipl, z5.))=statel & zipfips(put(zipr, z5.))=statel &;
            
        %if "&type"="ZIP3" %then round(zipl, 100)^=round(zipr, 100);
        %else &var.r^=&var.l;;       
        
        %if "&type"="ZIP3" %then %do;
            zipl=round(zipl, 100);
            zipr=round(zipr, 100);
        %end;
        
        &var=&var.l;
        set &out key=&var/unique;
        
        if _error_ then _error_=0;
        else do;
            &var=&var.r;
            set &out key=&var/unique;
            
            if _error_ then _error_=0;
            else do;
                &var.adj=&var.l;
                output;
                
                &var=&var.l;
                &var.adj=&var.r;
                output;
            end;
        end;
    run;
    
    %_sort(data=&scratch, out=&scratch, by=&var &var.adj, sort=nodupkey);
     
    %let nobs=%_nobs(data=&scratch);
    
    data &out;
        merge &out &scratch;
        by &var;
    run;
    
    proc univariate noprint data=&out;
        var &var.adj;
        by &var;
        output out=&scratch n=num;
    run;
        
    data &scratch(index=(&var/unique));
        set &scratch end=last;
        drop maxnum;
        retain maxnum 0;
        
        &area=_n_;
        maxnum=max(num, maxnum);
        
        if last then do;
            call symput('maxarea', left(trim(&area)));
            call symput('maxnum', left(trim(maxnum)));
        end;
    run;
    
    %_lexport(append=&append, close=0, file=&file, n=,
	insert=sumNumNeigh=&nobs, var=num %length(&maxnum).);

    data &out(index=(&var));
        merge &scratch &out;
        by &var;
        drop &var.save;
 
        if num then do;
            %if %length(&weight) %then weights=&weight;;
            &var.save=&var;
            &var=&var.adj;
            
            set &scratch(keep=&var &area rename=(&area=adj)) key=&var/unique;
        
            &var=&var.save;
        end;
        else adj=.;
    run;
    
    data &scratch;
        set &out;
        where num;
    run;

    %if %length(&weight) %then %_lexport(append=&file, close=&close, 
        var=adj %length(&maxarea). weights %length(&weight).);
    %else %_lexport(append=&file, close=&close, var=adj %length(&maxarea).);

    %let syslast=&out;
%end;
%else %do;
    %put ERROR: TIGERC does not exist in DIR=&DIR;
    %put        you can create it with TIGERIMPORT.;
    %_abend;
%end;

%mend tigeradjacent;

/*
options ls=120;

libname census00 '/survey/lib';

title 'CA';
%tigeradjacent(data=census00.wave1, where=zipstate(zip)='CA', 
    dir=/census/lib/ca,  
    out=ca, type=zip3, var=zip, close=0, file=tigeradjacent.txt);

proc print;
run;
  
title 'FL';
%tigeradjacent(data=census00.smallarea, where=zipstate(zip)='FL', 
    dir=/don/data/unchanged/census00/tiger/fl,  
    out=fl, type=zip3, var=zip, close=0, append=tigeradjacent.txt);

proc print;
run;
    
title 'IL';
%tigeradjacent(data=census00.smallarea, where=zipstate(zip)='IL', 
    dir=/don/data/unchanged/census00/tiger/il,  
    out=il, type=zip3, var=zip, close=0, append=tigeradjacent.txt);

proc print;
run;
    
title 'NY';
%tigeradjacent(data=census00.smallarea, where=zipstate(zip)='NY', 
    dir=/don/data/unchanged/census00/tiger/ny,  
    out=ny, type=zip3, var=zip, append=tigeradjacent.txt);

proc print;
run;  

*/
