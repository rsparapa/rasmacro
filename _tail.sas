%put NOTE: You have called the macro _TAIL, 2004-03-30.;
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

/*  _TAIL Documentation
    Return the last item from a list.
    
    POSITIONAL Parameters
    
    ARG1        list to be operated on
                
    NAMED Parameters
    
    SPLIT=      the split character separating the items,
                defaults to blank
*/

%macro _tail(arg1, split=%str( ));
    %scan(&arg1, %_count(&arg1, split=&split), &split)
%mend _tail;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

%let list=a,b,c,d,e,6;
%put LIST=&list TAIL=%_tail(%bquote(&list), split=%str(,));

%let list=a b c d e\6;
%put LIST=&list TAIL=%_tail(&list);
%put LIST=&list TAIL=%_tail(&list, split=\);

%put TAIL=%_tail(/bnp/nonpar/binTbinO/.Rdata/N250p5q2g.2d2e.2m-1r.6/b.2/normal/par.41.rds, split=.);

*/
