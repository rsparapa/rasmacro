%put NOTE: You have called the macro ADJACENT, 2014-03-18;
%put NOTE: Copyright (c) 2010-2014 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2010-09-30

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
    
/*  ADJACENT Documentation
    Takes a SAS DATASET with regions and creates an adjacency file 
    for GeoBUGS based on a SAS MAP DATASET.  Can NOT handle areas
    that have no neighbors, yet.  Creates the AREA. informat which
    can be used to create an AREA from VAR=.
    
    REQUIRED Parameters
    
    FILE=           file to export adjacency information 
    
    OUT=            the SAS DATASET to be created with the AREA variable
                
    VAR=            the name of the variable in the input SAS DATASET
                    that represents region
                       
    NAMED Parameters
    
    DATA=_LAST_     default SAS DATASET to be used
     
    APPEND=         if specified, append to a file, rather than create
                    see FILE= below

    AREA=AREA       numeric variable to create indexing the areas
                    
    CLOSE=1         defaults to close, set to 0 to leave FILE= open 

    LENGTH=         storage length of VAR, mainly important for
                    character variables in which case a $ is needed
                    if VAR=FIPS, then LENGTH=$ 5 is assumed
                    
    MAP=MAPS.USCOUNTY   the default MAP DATASET
    
    WEIGHT=1        default weights for the adjacency matrix

    Common OPTIONAL Parameters
                    
    See _SORT documentation
*/

%macro _adjacent(data=&syslast, out=REQUIRED, var=REQUIRED, append=REQUIRED, 
    area=area, close=1, file=&append, weight=1, map=MAPS.USCOUNTY, length=,
    attrib=, by=, drop=, firstobs=, if=, keep=, obs=, rename=, sort=, sortseq=, 
    where=); 

%_require(&file &out &var);

%global sumNumNeigh numArea;
%local fips scratch0 scratch1 scratch2 N nobs maxarea maxnum miss;

%let var=%upcase(&var);

%if %_dsexist(&map) %then %do;
    %_sort(data=&data, out=&out, attrib=&attrib, by=&by, drop=&drop, 
        firstobs=&firstobs, if=&if, keep=&keep, obs=&obs, rename=&rename, 
        sort=&sort, sortseq=&sortseq, where=&where);

    %_sort(data=&out, out=&out, by=&var);
    
    %let scratch0=%_scratch;
    
    %_sort(data=&out, out=&scratch0, by=&var, keep=&var, sort=nodupkey, index=&var/unique);

    %let scratch1=%_scratch;
            
    %_sort(data=&map, out=&scratch1, by=x y, where=n(x, y)=2);

    %let scratch2=%_scratch;
    
    data &scratch1 &scratch2;
        set &scratch1;
        by x y;
    
        %if "&var"="FIPS" %then %do;
            %let length=$ 5;
            
            keep x y fips1;
            
            fips1=put(state, z2.)||put(county, z3.);
        %end;
        %else %do;
            keep x y &var;
            rename &var=&var.1;
        %end;
    
        %if %index(&length,$) %then %let miss='';
        %else %let miss=.;
        
        if first.y & last.y then output &scratch2;
        else output &scratch1;
    run;

    data &scratch1;
        set &scratch1;
        by x y;
/*
        N=the max number of neighbors sharing a single point
        
        with currently available maps tested, 5 is the max observed
        to be safe here we use 10, but this should not be considered 
        the hypothetical upper bound
*/
        %let N=10;
        
        drop x y i j n n1-n&N;
    
        array _n(&N) &length n1-n&N;
    
        %_retain(var=n=0 n1-n&N=&miss, array=0, by=y);

        n+1;
    
        _n(n)=&var.1;
    
        if last.y;
        
        do i=1 to n-1;
            do j=i+1 to n;
                &var.1=_n(i);
                &var.2=_n(j);
            
                output;
            
                &var.1=_n(j);
                &var.2=_n(i);
            
                output;             
            end;
        end;
    run;

    %_sort(data=&scratch1, out=&scratch1, by=&var.1 &var.2, sort=nodupkey);
    
    data &scratch2;
        set &scratch1;
        keep &var &var.adj;
        
        &var=&var.1;
        set &scratch0 key=&var/unique;
        
        if _error_ then _error_=0;
        else do;
            &var=&var.2;
            set &scratch0 key=&var/unique;
            
            if _error_ then _error_=0;
            else do;
                &var.adj=&var.1;
                output;
                
                &var=&var.1;
                &var.adj=&var.2;
                output;
            end;
        end;
    run;
    
    %_sort(data=&scratch2, out=&scratch2, by=&var &var.adj, sort=nodupkey);
     
    data &scratch0;
        merge &scratch0 &scratch2;
        by &var;
    run;
       
    data &scratch2;
        set &scratch0;
        by &var; 
        where &var.adj^=&miss & &var.adj^=&var;
        
        %_retain(var=num=0, by=&var);
        
        num+1;
        
        if last.&var;
    run;
 
    data &scratch2(index=(&var/unique));
        set &scratch2 end=last;
        drop maxnum;
        retain maxnum 0 fmtname 'area' type 'I';
        
        &area=_n_;
        maxnum=max(num, maxnum);
        
        if last then do;
            call symput('maxarea', left(trim(&area)));
            call symput('maxnum', left(trim(maxnum)));
        end;
    run;
    
    proc format cntlin=&scratch2(keep=fmtname type &var area rename=(&var=start area=label));
    run;
    
    %_lexport(append=&append, close=0, file=&file, n=,
	/*insert=sumNumNeigh=&nobs,*/ var=num %length(&maxnum).);

    data &scratch0(index=(&var));
        merge &scratch2(drop=fmtname type) &scratch0;
        by &var;
        drop &var.save;
 
        if num then do;
            %if %length(&weight) %then weights=&weight;;
            &var.save=&var;
            &var=&var.adj;
            
            set &scratch2(keep=&var &area rename=(&area=adj)) key=&var/unique;
        
            &var=&var.save;
        end;
        else adj=.;
    run;
    
    data &scratch2;
        set &scratch0;
        where num & &var.adj^=&var;
    run;

    %let nobs=%_nobs(data=&scratch2);

    /*
    %let hues=r br o g b p gr pk ol v y lg yg;
    %let pres=pa bi li mo me st da de vi vpa vli vda vde;
    
    %let j=1;
            
    %do i=1 %to &maxnum;
        %if &i<=%_count(&hues) %then %let colors=&colors %scan(&hues, &i, %str( ));
        %else %do;
            %if &j>%_count(&pres) %then %let j=1;
            
            %let k=%eval(&i-(&i/%_count(&hues))*%_count(&hues)+1);
            
            %let colors=&colors %scan(&pres, &j, %str( ))%scan(&hues, &k, %str( ));
            
            %let j=%eval(&j+1);
        %end;
    %end;
    */
    
    %if %length(&weight) %then %_lexport(append=&file, close=&close, 
        var=adj %length(&maxarea). weights %length(&weight).);
    %else %_lexport(append=&file, close=&close, var=adj %length(&maxarea).);

    data &scratch0;
        set &scratch0;
        by &var;
        keep &var &area;
        if first.&var;
    run;
    
    data &out;
        merge &scratch0 &out;
        by &var;
    run;
        
    %let numArea=&maxarea;
    %put numArea=&numArea;
    %let sumNumNeigh=&nobs;
    %put sumNumNeigh=&sumNumNeigh;
%end;
%else %do;
    %put ERROR: &map does not exist.;
    %_abend;
%end;

%mend _adjacent;
