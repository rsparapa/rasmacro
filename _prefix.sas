%put NOTE: You have called the macro _PREFIX, 2010-06-09.;
%put NOTE: Copyright (c) 2004-2010 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2004-03-12

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

/*  _PREFIX Documentation
    Creates long IN:() operators.
    
    POSITIONAL Parameters
    
    ARG1-ARG99  up to 99 positional parameters are supported,
                however, if some of the positional parameters
                are lists (like 5-10 or A1-A20) more than 99
                items are allowed
                
    NAMED Parameters
    
    BY=1        expand list counting BY=

    MAX=99      defaults to the number of positional parameters
                supported, if more are added, then update MAX=
                accordingly

    SPLIT=,     default split character
                
*/

%macro _prefix(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, 
    arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, 
    arg20, arg21, arg22, arg23, arg24, arg25, arg26, arg27, arg28, arg29, 
    arg30, arg31, arg32, arg33, arg34, arg35, arg36, arg37, arg38, arg39,
    arg40, arg41, arg42, arg43, arg44, arg45, arg46, arg47, arg48, arg49,
    arg50, arg51, arg52, arg53, arg54, arg55, arg56, arg57, arg58, arg59,
    arg60, arg61, arg62, arg63, arg64, arg65, arg66, arg67, arg68, arg69,
    arg70, arg71, arg72, arg73, arg74, arg75, arg76, arg77, arg78, arg79,
    arg80, arg81, arg82, arg83, arg84, arg85, arg86, arg87, arg88, arg89,
    arg90, arg91, arg92, arg93, arg94, arg95, arg96, arg97, arg98, arg99,
    by=1, max=99, split=%str(,));

    %local i;

    in:(%_list(&arg1, by=&by, split=&split) %do i=2 %to &max;
        %if %length(&&arg&i) %then &split%_list(&&arg&i, by=&by, split=&split); 
    %end;)
%mend _prefix;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

%put OUTPUT=%_prefix('77401'-'77403', '77406'-'77408', by=2);
%put OUTPUT=%_prefix('77401'-'77403', '77406'-'77408', split=%str(,));
%put OUTPUT=%_prefix('77401'-'77403', '77406'-'77408', split=%str( ));

*/

