%put NOTE: You have called the macro _RETAIN, 2017-02-28.;
%put NOTE: Copyright (c) 2001-2017 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2001-00-00

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

/*  _RETAIN Documentation
    The RETAIN statement holds a variables value from one
    observation to the next.  However, this is not exactly
    what you want when you are dealing with BY-group
    processing; rather the RETAINed variables should be
    set to the default at the beginning of each BY-group.
    This SAS Macro is a replacement for the RETAIN statement 
    in these circumstances.
    
    REQUIRED Parameters
    
    VAR=        the list of variables to RETAIN
                
    NAMED Parameters
    
    ARRAY=1     for lists like VAR1-VAR10 the default
                is to create an ARRAY named VAR(), 
                however this may generate an error since
                VAR() may already be defined, so you
                can specify an arbitrarily named array
                by ARRAY=0 or passing a PDV list like
                VAR1--VAR10 (PDV lists use ARRAY to
                come up with a unique name so change
                it accordingly)
                
    BY=         the variables that the SAS DATASET is 
                sorted by, if any
                
    DEFAULT=.   the default to set all RETAINed variables
                to . at the beginning of each BY-group; this
                is only used if a default is not explicitly
                set, i.e. VAR=LVALUE=0 or VAR=VAR1-VAR10=''
                note that blank character defaults must be
                specified as '' or ""
                
    SPLIT=      the split character separating the variables
                in the VAR= list, defaults to blank

*/
                
%macro _retain(var=REQUIRED, by=, default=., split=%str( ), array=1);

    %_require(&var);
    
    %local i j k index lo hi suffix var0;

    %let var=%qlowcase(&var);
    %*let var=%upcase(&var);
    %let var0=%_count(text=%bquote(&var), split=&split);
    
    %do i=1 %to &var0;
        %local var&i def&i list&i;
        %let var&i=%scan(&var, &i, &split);
	%let j=%index(%bquote(&&var&i), =);
	
	%if &j>0 %then %do;
	    %let def&i=%substr(%bquote(&&var&i), &j+1);
	    %let var&i=%substr(%bquote(&&var&i), 1, &j-1);
	%end;
        %else %let def&i=&default;
        
        %let var&i=%_list(&&var&i);

        retain &&var&i 

        %if %datatyp(&&def&i)=NUMERIC %then &&def&i;
        %else %if %_indexc(&&def&i, ''"")=1 %then &&def&i;
        ;
    %end;

    %let var=;
        
    if %_first(&by) then do;
        %do i=1 %to &var0;
            %let k=%_count(&&var&i);
            
            %if &array & &k>1 %then %do;
                %let index=%_indexc(&&var&i, 0123456789);
                %let var=%substr(&&var&i, 1, &index-1);
                %let lo=%substr(%scan(&&var&i, 1, %str( )), &index);
                %let hi=%substr(%_tail(&&var&i), &index);
                %let suffix=%scan(&lo, 1, 0123456789);
                %let lo=%scan(&lo, 1, _abcdefghijklmnopqrstuvwxyz);
                %let hi=%scan(&hi, 1, _abcdefghijklmnopqrstuvwxyz);
                %*let lo=%scan(&lo, 1, _ABCDEFGHIJKLMNOPQRSTUVWXYZ);
                %*let hi=%scan(&hi, 1, _ABCDEFGHIJKLMNOPQRSTUVWXYZ);
                %_array(array=&var, dim1=&lo:&hi, suffix=&suffix);
                
                do _i_=lbound(&var) to hbound(&var);
                    &var(_i_)=&&def&i;
                end;
    
                drop _i_;
            %end;
            %else %if &k=1 & %index(&&var&i, --) %then %do;
                array _&i.&array(*) &&var&i;
            
                do _i_=1 to hbound(_&i.&array);
                    _&i.&array(_i_)=&&def&i;
                end;
                
                drop _i_;
            %end;
            %else %do j=1 %to &k;
                %scan(&&var&i, &j, %str( ))=&&def&i;
            %end;
        %end;
    end

%mend _retain;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

data;
%_retain(var=straw='s' berry="b");
%_retain(var=water=6 melon=8 apple=melon);
run;

data;
first.y=1;
%_retain(var=straw1d-straw5d berry, by=y);
%_retain(var=water1t-water5t=3 melon=2, by=y);
run;

data;
%_retain(var=water=( 6<=7)\ melon=8, split=\);
run;

*/
