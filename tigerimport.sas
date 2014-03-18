%put NOTE: You have called the macro TIGERIMPORT, 2008-07-29;
%put NOTE: Copyright (c) 2006-2008 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2006-00-00

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
    
/*  TIGERIMPORT Documentation
    Import TIGER/Line files geocoding information; must be run
    interactively.  For
    more documentation see
    http://www.mcw.edu/FileLibrary/Groups/EpidemiologyDataServiceCenter/Newsletters/vo13no01.pdf
    
    REQUIRED Parameters
    
    DIR=            the directory containing the TIGER/Line files
                    and where to import geocoding SAS CATALOG and 
                    SAS DATASETS
                    
    NAMED Parameters
     
    MAP=            Optional state postal code of state to import
*/                    

%macro tigerimport(dir=REQUIRED, map=);  

%_require(&dir);

%local co count counties dirchar fips i j;
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

%* create a list of counties for this state;
data county;
    infile "&dir.&dirchar.COUNTS_&fips..TXT";
    input fips co;
run;
    
%let counties=%_level(var=co, split=%str( ), format=z3.);
%let count=%_count(&counties);
    
%* batch parameters: MISNOMER, import must be run interactively;
%let imp_type=tiger; /* Import source file type          */
%let maplib=street;  /* Libref for imported map          */
%let mapcat=&map;    /* Catalog for imported entries     */
%let mapname=map;    /* Name of imported map entry       */
%let spalib=&maplib; /* Libref to write spatial datasets */
%let spname=&map;    /* Base name for spatial datasets   */

/* Location of map spatial datasets and catalog */
libname &maplib "&dir";    
    
%* remove previously imported catalog/datasets for this state, if any;
%_delete(data=&maplib..mapbg);    %* Block Group chains dataset;
%_delete(data=&maplib..maptract); %* Tract chains dataset;
%_delete(data=&maplib..&map);     %* Catalog for imported entries;
%_delete(data=&maplib..tigerc);   %* Street chains dataset;
%_delete(data=&maplib..tigerd);   %* Also created by tigerimport;
%_delete(data=&maplib..tigern);   %* Also created by tigerimport;
%_delete(data=&maplib..tigerm);   %* Created by tigergeocode;
%_delete(data=&maplib..tigerp);   %* Also created by tigergeocode;
%_delete(data=&maplib..tigers);   %* Also created by tigergeocode;

%* import each county;
%do i=1 %to &count;
    %if &i=1 %then %do;
        %let cathow=create; /* Catalog creation */
        %let spahow=create; /* Create datasets */
    %end;
    %else %if &i=2 %then %do;
        %let cathow=update; /* Catalog update */
        %let spahow=append; /* Append to datasets */
        %* limit log window output to first/last counties;
        %* otherwise log window will overflow and import will hang;
        %_printto(log=%_null);
    %end;
    %else %if &i=&count %then %_printto;
    
    %let co=%scan(&counties, &i, %str( ));
    
    %do j=1 %to 6;
        %if &j^=3 %then %do;
            %* delete previously created Record Type files for this county, if any;
            %if %_exist(&dir.&dirchar.TGR&fips.&co..RT&j) %then
                x "%_unwind(rm -f, del) &dir.&dirchar.TGR&fips.&co..RT&j";;
            %* create Record Type files for this county;
            x "cd &dir; unzip tgr&fips.&co..zip TGR&fips.&co..RT&j";
            %* create Filerefs for importing Record Type files for this county;
            filename tiger&j "&dir.&dirchar.TGR&fips.&co..RT&j";
        %end;
    %end;
        
    dm 'af c=sashelp.gisimp.batch.scl'; /*invoke import for this county*/
    
    %do j=1 %to 6;
        %if &j^=3 %then %do;
            %* close Filerefs for importing Record Type files for this county;
            filename tiger&j;
            %* delete Record Type files for this county;
            x "%_unwind(rm -f, del) &dir.&dirchar.TGR&fips.&co..RT&j";;
        %end;
    %end;
%end;

/* Street chains dataset for this state */
data &maplib..tigerc;
    set &maplib..tigerc;
    drop chars;
    retain chars 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; /* Unwanted characters */
    
    if _n_>1 then do;                          /* Skip header record */ 
        FrAddL=compress(upcase(FrAddL), chars);
        FrAddR=compress(upcase(FrAddR), chars);
        ToAddL=compress(upcase(ToAddL), chars);
        ToAddR=compress(upcase(ToAddR), chars);
    end;
run;  
    
%mend tigerimport;

/* Examples */
                
%*tigerimport(dir=/don/data/unchanged/census00/tiger/ca);
%*tigerimport(dir=/don/data/unchanged/census00/tiger/fl);
%*tigerimport(dir=/don/data/unchanged/census00/tiger/ny);

