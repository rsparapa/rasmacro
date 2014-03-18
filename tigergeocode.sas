%put NOTE: You have called the macro TIGERGEOCODE, 2008-07-29;
%put NOTE: Copyright (c) 2007-2008 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2007-07-24

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
    
/*  TIGERGEOCODE Documentation
    Takes a SAS DATASET with mailing addresses in one state
    and creates a SAS DATASET with geocodes for those addresses.  For
    more documentation see
    http://www.mcw.edu/FileLibrary/Groups/EpidemiologyDataServiceCenter/Newsletters/vo13no01.pdf

    REQUIRED Parameters
    
    DIR=            the directory containing the TIGER/Line files
                    and imported geocoding SAS CATALOG and 
                    SAS DATASETS
                    
    OUT=            the SAS DATASET to be created
                
    NAMED Parameters
    
    DATA=_LAST_     default SAS DATASET to be used
    
    DEBUG=          set to * for .log creation and debugging
                    
    ADDRESS=ADDRESS Default address variable (number/street)
    
    CITY=CITY       Default city variable
                    
    NAME=NAME       Default identifier for address record
     
    MAP=            Optional state postal code of state to geocode
                    
    PLUS4=          Optional 4-digit ZIP+4 variable
                    
    STATE=STATE     Default state postal code variable
                    
    ZIP=ZIP         Default 5-digit ZIP code variable

    Common OPTIONAL Parameters
                    
    See _SORT documentation
*/

%macro tigergeocode(data=&syslast, debug=, dir=REQUIRED, map=, out=REQUIRED, 
    plus4=, name=name, address=address, city=city, state=state, zip=zip, 
    attrib=, by=, firstobs=, drop=, if=, keep=, obs=, rename=, sort=, 
    sortseq=, where=); 

%_require(&dir &out);

%_sort(data=&data, out=&out, attrib=&attrib, by=&by, firstobs=&firstobs, 
    drop=&drop, if=&if, keep=&keep, obs=&obs, rename=&rename, sort=&sort, 
    sortseq=&sortseq, where=&where);

data &out;
    set &out;
    &address=compress(&address, "'");
    &city=compress(&city, ",");
run;

libname street "&dir";    

%local dirchar fips newdata options i;

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

%if %_dsexist(street.tigerm) & %_dsexist(street.tigerp) & 
    %_dsexist(street.tigers) %then %let newdata=no;
%else %let newdata=yes;               
                            
%gcbatch(
    glib=street,              /* Street datasets libref             */
    newdata=&newdata,         /* Create lookup data?                */
    mname=street.&map..map,   /* Base map of streets                */ 
    geod=&out,                /* Address dataset to geocode         */
    nv=&name,                 /* Name at address variable           */
    av=&address,              /* Address variable (number/street)   */
    cv=&city,                 /* City variable                      */
    sv=&state,                /* State variable                     */
    zv=&zip,                  /* 5-digit ZIP Code variable          */
    p4v=&plus4,               /* Optional ZIP+4 variable            */
    pv=county tract bg block);/* Location variables wanted from map */

%* so that log window will not overflow and hang geocoding;
&debug%_printto(log=%_null);
%let options=%sysfunc(getoption(mlogic)) %sysfunc(getoption(mprint)) %sysfunc(getoption(symbolgen));
&debug.options nomlogic nomprint nosymbolgen;

dm 'AF C=SASHELP.GIS.GEOCODEB.SCL';

%_printto;

options &options;

data &out;
    length fips $ 5;
    set &out;
    
    if _status_='found' then fips="&fips"||put(county, z3.);
run;

proc print n uniform data=&out;
    where _status_^='found';
    id _status_;
    var &name &address &city &state &zip;
run;

%mend tigergeocode;

/*
options ls=120;

%*tigergeocode(data=survey.hospital, where=state='CA', 
    dir=/don/data/unchanged/census00/tiger/ca,  
    out=survey.flhospital, name=provider);
%*tigergeocode(data=survey.hospital, where=state='FL', 
    dir=/don/data/unchanged/census00/tiger/fl,  
    out=survey.flhospital, name=provider);
*/
