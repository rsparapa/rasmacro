%put NOTE: You have called the macro _RIMPORT, 2013-10-02.;
%put NOTE: Copyright (c) 2013 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2013-10-01

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

/*  _RIMPORT Documentation
    Import an R data frame, either .rds or .csv, to a SAS DATASET
     
    REQUIRED Parameters
    
    INFILE=     the file to create the SAS DATASET from
                either an .rds file or a .csv file created by write.foreign
    
    OUT=        the SAS DATASET to be created
                   
    NAMED Parameters
    
    CODEFILE=   the code file previously (or to be) created by write.foreign            
    
    DATAFILE=   the data file previously (or to be) created by write.foreign                 
                
    DEBUG=      default is to remove the generated hidden files
                to keep them for debugging purposes, set to * 
                see also:  LOG=
                
    Common OPTIONAL Parameters
    
    LOG=        file or device to re-direct the .log to,
                quotes allowed but unnecessary
                
    RENAME=     SAS RENAME Statement
*/

%macro _rimport(infile=REQUIRED, out=REQUIRED, 
    datafile=, codefile=, rename=, debug=, log=%_null);
    
    %_require(&infile &out);
            
    %if %_exist(&infile) %then %do;
        %if "%_tail(&infile, split=.)"="rds" %then %do;
            %if %length(&datafile)=0 %then %let datafile=%_data(&out).txt;
            %if %length(&codefile)=0 %then %let codefile=%_data(&out).sas;
            
            %if %length(&log) %then %_printto(log=&log);
            
            data _null_;
                file ".&sysjobid..R";
                put 'require(foreign)';
                put "write.foreign(as.data.frame(readRDS(""&infile"")),";
                put '              package="SAS",';
                put "              datafile=""&datafile"",";
                put "              codefile=""&codefile"")";
            run;
    
            x "R --no-save < .&sysjobid..R >& .&sysjobid..Rt";

            &debug.x "rm -f .&sysjobid..R .&sysjobid..Rt";
            
            %if %length(&log) %then %_printto;
        %end;
        
        %if %_exist(&codefile) %then %do;
            %if %length(&log) %then %_printto(log=&log);
                
            x "csplit -s -f .&sysjobid &codefile %nrbquote(%)INFILE%nrbquote(%)";
            x "echo data %_data(&out) ';' > .&sysjobid..sas";

            %if %length(&rename) %then x "echo rename &rename ';' >> .&sysjobid..sas";;

            x "cat .&sysjobid.00 >> .&sysjobid..sas";
            
            %if %length(&log) %then %_printto;
            
            %include ".&sysjobid..sas";               
            
            &debug.x "rm -f .&sysjobid..sas .&sysjobid.00";
        %end;
        %else %put ERROR: &codefile does not exist.;
    %end;
    %else %put ERROR: &infile does not exist.;
    
%mend _rimport;
        
/*
title '.csv previously created by write.foreign from .rds';
%_rimport(out=test, debug=*,
infile=/bnp/nonpar/binTbinO/.Rdata/N250p5q2g.2d2e.2m-1r.6/b.2/normal/pa0.41.txt,
codefile=/bnp/nonpar/binTbinO/.Rdata/N250p5q2g.2d2e.2m-1r.6/b.2/normal/pa0.41.sas
);

proc contents;
run;

proc univariate plot;
    var beta;
run;

title '.rds from which .csv created by write.foreign';
%_rimport(out=test, debug=*,
    rename=v1-v5=gamma1-gamma5 v6-v7=delta1-delta2 v8-v12=eta1-eta5
        v13=beta v14-v15=mu1-mu2 v16=rho,
infile=/bnp/nonpar/binTbinO/.Rdata/N250p5q2g.2d2e.2m-1r.6/b.2/normal/par.41.rds);

proc contents;
run;

proc univariate plot;
    var beta;
run;

*/
