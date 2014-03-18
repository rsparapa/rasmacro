%put NOTE: You have called the macro _HEAD, 2004-03-30.;
%put NOTE: Copyright (c) 2001-2004 Rodney Sparapani;
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

/*  _HEAD Documentation
    Return everything from a list except the last item.
    
    POSITIONAL Parameters
    
    ARG1        list to be operated on
                
    NAMED Parameters
    
    SPLIT=      the split character separating the items,
                defaults to blank
*/

%macro _head(arg1, split=%str( ));
    %local i j k;
    %let j=%_count(&arg1, split=&split);

    %do i=1 %to &j-2; 
	%let k=&k%scan(&arg1, &i, &split)&split;
    %end; 

    &k%scan(&arg1, &j-1, &split)
%mend _head;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

%let list=a b c\d e\6;
%put LIST=&list HEAD=%_head(&list);
%put LIST=&list HEAD=%_head(&list, split=\);

*/

