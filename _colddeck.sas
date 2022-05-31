%put NOTE: You have called the macro _COLDDECK, 2022-05-18.;
%put NOTE: Copyright (c) 2022 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2022-05-18

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

%macro _colddeck(var=_numeric_, data=&syslast, out=REQUIRED, seed=REQUIRED,
    attrib=, by=, firstobs=, drop=, keep=, obs=, rename=, sortedby=, where=,
    log=);

%_require(&out &seed);

%if %length(&log) %then %_printto(log=&log);

%_sort(data=&data, out=&out, attrib=&attrib, by=&by, firstobs=&firstobs,
    drop=&drop, keep=&keep, obs=&obs, rename=&rename, sortedby=&sortedby,
    where=&where);
    
%if %length(&log) %then %_printto;

%local i k n rename temp vars;
%let n=%_nobs(data=&out);
%let vars=%_blist(data=&out, var=&var);
%let k=%_count(&vars);

%do i=1 %to &k;
    %local var&i;
    %let var&i=%scan(&vars, &i, %str( ));
    %let temp=&temp _&&var&i;
    %let rename=&rename &&var&i=_&&var&i;
%end;

data &out;
    array _var(&k) &vars;
    array _temp(&k) &temp; 
    array _miss(&k) _temporary_;
    drop j _seed_ &temp;
    _seed_=&seed;

    do i=1 to &n;
        set &out point=i;
        do while(nmiss(of &var1--&&var&k));
            do j=1 to &k;
                _miss(j)=nmiss(_var(j));  
            end;
    
            %_ranuni(var=h, seed=_seed_, upper=&n);
            h=ceil(h);
            
            set &out(keep=&vars rename=(&rename)) point=h;

            do j=1 to &k;
                if _miss(j) then _var(j)=_temp(j);  
            end;            
        end;
    
        output;
    end;
    stop;
run;
    
%mend _colddeck;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/
