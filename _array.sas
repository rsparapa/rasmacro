%put NOTE: You have called the macro _ARRAY, 2006-04-20.;
%put NOTE: Copyright (c) 2001-2006 Rodney Sparapani;
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

/*  _ARRAY Documentation
    Generates ARRAY statements; useful for very long or complex 
    ARRAY statements of up to 3 dimensions.

    REQUIRED Parameters
    
    ARRAY=          name of the ARRAY to create
                    
    DIM1=           first dimension which may be stated as # or #:#
                    
    Specific OPTIONAL Parameters
    
    DEFAULT=        default to set each ARRAY element to; 
                    WARNING:  Specifying initial values on an ARRAY 
                    statement causes the variables to be RETAINed;
                    leaving this option blank is usually what you want
                    
    DIM2=           second dimension which may be stated as # or #:#
    
    DIM3=           third dimension which may be stated as # or #:#
    
    LENGTH=         length of variables in the ARRAY, can also be
                    used to specify a character ARRAY, i.e. LENGTH=$ 2,
                    defaults to 8
                    
    PREFIX=         prefix to name each ARRAY variable, i.e. PREFIX###, 
                    defaults to name of the ARRAY specified by ARRAY=
                    
    SEP=            separator text prepended to numbers,
                    i.e. SEP#SEP#SEP#, defaults to blank
                    (for CODA files imported by _DECODA use SEP=_)
                    
    SEP1=SEP        default separator for dimension 1
    SEP2=SEP        default separator for dimension 2
    SEP3=SEP        default separator for dimension 3
                    
    SUFFIX=         suffix appended to name of each ARRAY variable,
                    i.e. PREFIX###SUFFIX, defaults to blank
                    
    W1-W3=          defaults to blank, if present then the least 
                    possible number of significant digits are used
                    for the #th dimension
                    
    Common OPTIONAL Paramters
    
    ATTRIB=
*/
    
%macro _array(array=REQUIRED, dim1=REQUIRED, dim2=, dim3=, w1=, w2=, w3=, 
    attrib=, default=, var=&array, length=, sep=, sep1=&sep, sep2=&sep, 
    sep3=&sep, suffix=, prefix=&var);
    
    %_require(&array &dim1);
    
    %local i j k limits list max mult;

    %let max=%_count(&dim1 &dim2 &dim3);

    %do i=1 %to &max;
        %local lo&i hi&i len&i mod&i;
        %let lo&i=%scan(&&dim&i, 1, :);
        %let hi&i=%scan(&&dim&i, 2, :);

        %if %length(&&hi&i)=0 %then %do;
            %let hi&i=&&lo&i;
            %let lo&i=1;
        %end;
    %end;

    %do i=1 %to &max; 
        %let limits=&limits &&lo&i:&&hi&i;
        %if &i<&max %then %let limits=&limits,; 
    %end;
    
    %let list=;

    %do i=1 %to &max;
        %if %length(&&w&i) | 
            (&i=1 & %index(0123456789, %substr(&prefix, %length(&prefix), 1))) %then %do;
            /*
            the mod method was a popular choice working with data in 
            v. 6 and/or w/ data prior to Y2K and the w method was not
            used often:  to use the mod method, specify it with w;
            now using all of the digits is the default;
            unfortunately, there is alot of code out there declaring
            the prefix= argument in this legacy mod fashion that we want
            to keep working, so the first dimension is handled as a
            special case
            */
            %let mod&i=%eval(&&hi&i-&&lo&i);
        
            %if &&mod&i>0 %then %do;
                %let mod&i=%sysfunc(log10(&&mod&i));
                %let mod&i=%sysfunc(ceil(&&mod&i));
                %let mod&i=%_max(%eval(10**&&mod&i), 10);

                %if %sysfunc(mod(&&lo&i, &&mod&i))<%sysfunc(mod(&&hi&i, &&mod&i))
                %then %do;
                    %let w&i=%sysfunc(mod(&&lo&i, &&mod&i));
                    %let j=&prefix.&&w&i;
                    %let j=%_substr(&j, %length(&j)-%length(&&lo&i)+1);

                    %if &i=1 & &&lo&i^=&j %then %do;
                        %let lo&i=&&w&i;
                        %let hi&i=%sysfunc(mod(&&hi&i, &&mod&i));
                    %end;
                    %else %do;
                        %let lo&i=&&w&i;
                        %let hi&i=%sysfunc(mod(&&hi&i, &&mod&i));
                    %end;
                %end;
            %end;
        %end;
        
        %if &max=1 & %index(0123456789, %substr(&prefix, %length(&prefix), 1))=0 %then 
            %let len&i=%length(&&lo&i);
        %else %let len&i=%length(&&hi&i);
    %end;

    %do i=&lo1 %to &hi1;
        %let dim1=&prefix.&sep1%_repeat(0, &len1-%length(&i))&i;

        %if &max>1 %then %do j=&lo2 %to &hi2;
            %let dim2=&sep2%_repeat(0, &len2-%length(&j))&j;

            %if &max=3 %then %do k=&lo3 %to &hi3;
                %let dim3=&sep3%_repeat(0, &len3-%length(&k))&k;
                %let list=&list &dim1.&dim2.&dim3.&suffix;
            %end;
            %else %let list=&list &dim1.&dim2.&suffix;
        %end;
        %else %let list=&list &dim1.&suffix;
    %end;

    %if %length(&default) %then %do;
        %put WARNING: Specifying initial values on an ARRAY statement;
        %put WARNING: causes the array variables to be RETAINed!;
        %put;
        
        %if %index(&default, %str(%())=0 %then %do;
            %let mult=%eval(&hi1-&lo1+1);
            
            %if &max>1 %then %let mult=%eval(&mult*(&hi2-&lo2+1));
            %if &max=3 %then %let mult=%eval(&mult*(&hi3-&lo3+1));
    
            %let default=(&mult*&default);
        %end;
    %end;
    
    array &array(&limits) &length &list &default;
    
    %if %length(&attrib) %then attrib %scan(&list, 1, %str( ))--%_tail(&list) &attrib;;
%mend _array;
            
%*VALIDATION TEST STREAM;
/* un-comment to re-validate

data;

%_array(array=mln, dim1=1986:1998, dim2=12, default=0, attrib=format=yesno.);

run;
        
*/
    
