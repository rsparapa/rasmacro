%put NOTE: You have called the macro _DEBUGS, 2013-10-15;
%put NOTE: Copyright (c) 2007-2013 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2007-10-10

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

/* _DEBUGS Documentation
    Reads a SAS dataset and provides summaries as requested.            

    REQUIRED Parameters  

    DATA=REQUIRED              SAS input dataset
                            
    VAR=REQUIRED               list of variables to summarize/graph
                               use _all_ for all
                
    Specific OPTIONAL Parameters
                            
    ALPHA=0.025                default significance level for
                               the Brooks-Gelman-Rubin test (one-tailed)
                                
    AUTOCORR=1                 autocorrelation statistics are not 
                               calculated unless AUTOCORR NE 0 
                               if SAS/ETS is installed, then it may 
			       be set to a list of chains, but
                               the output will be lengthy
                               AUTOCORR=1 for the first chain should
                               be sufficient in most instances
			       if GRAPHICS=1, then autocorrelations
			       are presented as graphs and the 
			       output is suppressed

    BGR=1                      defaults to performing the Brooks-Gelman-Rubin test                            
    
    BURNIN=                    defaults to no burn-in discarded, to discard set
                               BURNIN to an iteration number
                                
    BY=OBS                     defaults to OBS, but you can over-ride
                               it with a SINGLE variable like BY=CHAIN
                                
    CHAIN=CHAIN                default name of chain variable,

    CHAINS=1                   default number of chains sampled
                               if CHAINS>1, calculate Brooks-Gelman-Rubin statistic    
                                
    CROSSCORR=1                crosscorrelation statistics are not 
                               calculated unless CROSSCORR NE 0 
                               (SAS/ETS does NOT need to be installed) 
                               it may be set to a list of chains, but
                               the output will be lengthy
                               CROSSCORR=1 for the first chain should
                               be sufficient in most instances
                                
    DISCRETE=                  list of variables that are discrete
                               for summarization of the mode by the
                               PROC UNIVARIATE option MODES

    FORMAT=BEST6.              default format for statistics provided on
                               the histogram: Mean(SD), CI
                               where CI is specified by PCTLPTS
                               either a single format for all the same
                               or a list of 3, in that order, for different
                               a format of . means omit the statistic                                
                                
    GRAPHICS=1                 if statistics are requested, then produce
                               graphics as well (v. 8 or higher only)
                            
    GSFMODE=REPLACE            default GSFMODE for first graph
                
    HISTOGRAM=KERNEL           default options to pass to the 
                               HISTOGRAM statement
                               (Note that the graphs are stored in the 
                                WORK.GSEG catalog as UNIVAR, UNIVAR1, etc.)
                            
    HPD=1                      default to highest posterior density intervals
                                
    ITER=ITER                  default name of iteration variable,
    
    KDE=1                      if a WEIGHT variable is present, then
                               PROC KDE is used to generate the histogram
                               however, badly behaved chains can cause
                               KDE to generate a termination due to a
                               division by zero floating point exception
                               to prevent this, set KDE=0
                                  
    LSD=                       if you set this option to something, then
                               you will only get a plot for the log SD of 
                               the monitored variables:  useful for 
                               detecting badly behaved chains
                               
    MARKER=                    iteration number corresponding to the
                               position that divides the sample
                               into two parts:  the first part for burn-in,
                               the second for convergence testing and parameter
                               estimation (assuming convergence holds)

    MU0=0                      default location for tests/tables

    NLAG=50                    default of up to 50 lag auto-correlation
                               if AUTOCORR NE 0
                            
    OBS=OBS		       default name of obs variable, 

    OPTIONS=                   options to PROC UNIVARIATE
                
    OUT=                       dataset created by THIN>1 and/or WHERE= clause

    PCTLDEF=5                  default percentile definition
                
    PCTLPTS=2.5 97.5           default percentiles to calcuate and present
         
    SYMBOL=i=join v=none r=1   default SYMBOL statement for trace plots

    THIN=1                     default thinning parameter, set to an integer
                               >1 for only keeping iterations where
                               MOD(ITER, THIN)=0                   
             
    TRACE=0                    default to produce NO trace plots

    TYPE=                      if you set this parameter, then TYPE will be
                               used to name the graphics file (VAR.TYPE) for 
                               each summarized variable/vector
    
    WIDTH=4                    default width for graphics
         
    WEIGHT=                    either a weight variable or a list of weights 
                               to ascribe to each chain
                               weights taken into account for summaries,
                               but not auto/cross-correlation nor BGR
                               see also KDE above
               
    WHERE=                     restrict the data with a WHERE clause,
                               useful for removing burn-in,
                               i.e. WHERE=iter>4000
*/
                            
%macro _debugs(data=REQUIRED, var=REQUIRED, alpha=0.05, autocorr=1, 
    bgr=&chains>1, burnin=, by=&obs, chain=chain, chains=1, colors=black blue red
    green cyan magenta, crosscorr=1, debug=, discrete=, format=best6., 
    graphics=%_version(8), gsfmode=replace, histogram=kernel, hpd=1,
    iter=iter, kde=1, labelcase=lower, lsd=, marker=, mu0=0, nlag=50, 
    obs=obs, options=, out=, 
    pctldef=5, pctlpts=2.5 97.5, symbol=i=join v=none r=1, thin=1, trace=0, type=, 
    weight=, where=, width=4);
    
    %_require(&data &var);

    %local i j k l m scratch scratch00 scratch0 lag nobs cl95 list 
        bgr byval oci mean std median qrange start stop left right
        midpoints color0;

    %let var=%_blist(var=&var, data=&data, nofmt=1);
    %let oci=%_blist(var=&obs &chain &iter, data=&data, nofmt=1);
    %let color0=%_count(&colors);
                
    %if %_count(&pctlpts)=1 %then 
        %let pctlpts=&pctlpts %sysevalf(100-&pctlpts);

    %if &thin>1 | %length(&burnin) | %length(&where) | %_count(&oci)<3 | %length(&weight) | %length(&lsd) %then %do;
        %if %length(&out)=0 %then %let out=%_scratch;
        
        data &out(index=(ci=(&chain &iter)));
            set &data;	
            %*by &obs &chain &iter;
            where &where;

            %*if nmiss(&iter) then &iter=_n_;

            if nmiss(&iter) then do;
                if nmiss(&chain) then &iter=_n_;
                else do;

                    *if ITER is missing and CHAIN is non-missing,
                     then we assume that the data is sorted by CHAIN:
                     this may not be true in the presense of a
                     non-zero, non-missing OBS;

                    retain _&chain _&iter;
                    drop _&chain _&iter;
                    
                    if _n_=1 | &chain^=_&chain then do;
                        _&iter=0;
                        _&chain=&chain;
                    end;
                    
                    _&iter+1;
                    &iter=_&iter;
                end;
            end;
            
            if nmiss(&chain) then &chain=1;
            if nmiss(&obs) then &obs=0;
                                
    	%if %length(&burnin) %then if &iter>&burnin;;
    	%if &thin>1 %then if mod(&iter, &thin)=0;;
                
        %if %_count(&weight)=1 %then weight=&weight;
        %else %if %length(&weight) %then %do;
            array _weight(&chains) _temporary_ (&weight);
            weight=_weight(&chain);
        %end;;
        
        %if &chains=1 %then %do;
            %*multiple chain detection;
            retain __&chain 1;
            drop __&chain;
        
            if &chain>__&chain then do;
                __&chain=&chain;
                call symput('chains', trim(left(&chain)));
            end;
        %end;

        %if %length(&lsd) %then %do;
            %let j=0;
            %let graphics=1;
            %let trace=1;
            %let autocorr=0;
            %let crosscorr=0;
            %let bgr=0;
            %let histogram=;
            
            &lsd=0.5*log(var(
            %do i=1 %to %_count(&var);
                %local var&i;
                %let var&i=%scan(&var, &i, %str( ));
            
                %if "%upcase(&&var&i)"^="%upcase(&obs)" & "%upcase(&&var&i)"^="%upcase(&chain)" & 
                    "%upcase(&&var&i)"^="%upcase(&iter)" %then %do;
        
                    %if &j=0 %then %do;
                        %let j=1;
                        &&var&i 
                    %end;
                    %else , &&var&i;
                %end;
            %end;));
    
            %let var=&lsd;
        %end;
        
        run;
    %end;
    %else %let out=&data;
    
    %if (&bgr & %length(&marker)=0) | (%length(&marker) & %sysevalf(&marker<=1)) %then %do;
        %let nobs=%_nobs(data=&out);
        
        %if %length(&marker)=0 %then %let marker=0.5;
        
        data _null_;
            obs=1;
            set &out(keep=&iter) point=obs;
            call symput('start', trim(left(&iter)));
        
            obs=&nobs;
            set &out(keep=&iter) point=obs;
            call symput('stop', trim(left(&iter)));
            stop;
        run;
        
        data _null_;
            set &out(keep=&chain &iter);
            where &chain=1;
       
            if &iter<=(&start+(&stop-&start)*&marker) then call symput('marker', trim(left(&iter)));
        run;
    %end;
    
    %let scratch=%_scratch;

    %let j=0;
    
    %do i=1 %to %_count(&var);
        %local var&i histogram&i;
        
        %let var&i=%scan(&var, &i, %str( ));
        %let histogram&i=&histogram;
                        
        %if "%upcase(&&var&i)"^="%upcase(&obs)" & "%upcase(&&var&i)"^="%upcase(&chain)" & 
            "%upcase(&&var&i)"^="%upcase(&iter)" %then %do;
            
            %let j=%eval(&j+1);
            %let list=&list &&var&i;
            
        proc univariate loccount mu0=&mu0 normal pctldef=&pctldef plot &options 
    	%if %sysfunc(indexw(%upcase(&discrete), %upcase(&&var&i))) %then modes; 
            data=&out(keep=&obs &chain &iter &&var&i 
                %if %length(&weight) %then weight;
                where=(n(&&var&i) %if %length(&marker) %then & &iter>&marker; ));
            by &by;
            %*by &obs;
            id &chain &iter;
            var &&var&i;
            %if %length(&weight) %then weight weight;;
            output out=&scratch pctlpre=&&var&i.._ pctlpts=&pctlpts 
                mean=mean std=std median=median qrange=qrange;
        run;
            
        proc print noobs data=&scratch;
            var &by &&var&i.._:;
        run;

    	%if %sysfunc(indexw(%upcase(&discrete), %upcase(&&var&i))) %then %do;
            %let midpoints=%_scratch;
            
            proc freq data=&out(keep=&obs &chain &iter &&var&i 
                    %if %length(&weight) %then weight;
                    where=(n(&&var&i) %if %length(&marker) %then & &iter>&marker; ));
                by &by;
                %*by &obs;
                %if %length(&weight) %then weight weight;;
                tables &&var&i %if %upcase("&&histogram&i")="KERNEL" %then / out=&midpoints;;
            run;
                
            %if %upcase("&&histogram&i")="KERNEL" %then %do; 
                %_sort(data=&midpoints, out=&midpoints, sort=nodupkey, by=&&var&i);
                %let histogram&i=midpoints=%_level(data=&midpoints, var=&&var&i, split=%str( ));
            %end;
        %end;
           
        %*work around a bug in the HISTOGRAM statement;
        %*only the graph for the first BYVAL is generated without this fix;
        %*while at it, lets make the graphic a little more user-friendly;
        %if &graphics %then %do;
    	    symbol1 &symbol width=&width;

            %if %length(&type) %then filename gsasfile "%lowcase(&&var&i).&type";;
                 
            %if &j=1 %then %do;
                goptions gsfmode=&gsfmode;
            
                %do k=1 %to 3;
                    %local format&k;
                    %let format&k=%scan(&format, &k, %str( ));
            
                    %if &k>1 & %length(&&format&k)=0 %then %do;
                        %if &k=4 & %length(&format2) %then %let format4=&format2;
                        %else %let format&k=&format1;
                    %end;
                %end;
            %end;
            %else goptions gsfmode=append;;
            
            %let scratch0=%_scratch;
            
            %_sort(data=&out, out=&scratch0, by=&by, sort=nodupkey, 
                keep=&obs &chain &iter &&var&i,  
                where=n(&&var&i) %if %length(&marker) %then & &iter>&marker; );
        
            %let byval=%_level(data=&scratch0, var=&by, split=%str( ));
            
            %do k=1 %to %_count(&byval);
                %local byval&k;
                %let byval&k=%scan(&byval, &k, %str( ));
            
                %if &j=1 & &k>1 %then goptions gsfmode=append;;
            
            data _null_;
                set &scratch;
                where &by=&&byval&k;
                
                %if &hpd %then %do;
                    %if "&format1"^="." %then call symput('median', trim(put(median, &format1.-l)));;
                    %if "&format2"^="." %then call symput('qrange', trim(put(qrange, &format2.-l)));;
                %end;
                %else %do;
                    %if "&format1"^="." %then call symput('mean', trim(put(mean, &format1.-l)));;
                    %if "&format2"^="." %then call symput('std',  trim(put(std, &format2.-l)));;
                    %if "&format3"^="." %then %do;
                        call symput('left', trim(put(&&var&i.._%_tr(%scan(&pctlpts, 1, %str( )), from=., to=_), &format3.-l)));;
                        call symput('right', trim(put(&&var&i.._%_tr(%scan(&pctlpts, 2, %str( )), from=., to=_), &format3.-l)));;
                    %end;
                %end;
            run;
            
            %if &hpd & "&format3"^="." %then %do;
                %* weights ignored!;
                %local hpd_nobs hpd_tot;
            
                %_sort(data=&out, out=&scratch, by=&&var&i,
                    keep=&obs &chain &iter &&var&i,
                        where=(n(&&var&i) & &by=&&byval&k
                            %if %length(&marker) %then & &iter>&marker; ));
            
                %let hpd_nobs=%_nobs(data=&scratch);
            
                %let hpd_tot=%sysevalf((1-&alpha)*&hpd_nobs);
                %let hpd_tot=%sysfunc(round(&hpd_tot));
            
                %put HPD_TOT=&hpd_tot;
            
                data _null_;
                    hpd_diff=.;
                
                    do i=1 to %eval(&hpd_nobs-&hpd_tot+1);
                        set &scratch(keep=&&var&i rename=(&&var&i=low)) point=i;
            
                        j=&hpd_tot+i-1;
                
                        set &scratch(keep=&&var&i rename=(&&var&i=high)) point=j;
                
                        if i=1 | (high-low)<hpd_diff then do;
                            hpd_diff=high-low;
                            hpd_low=low;
                            hpd_high=high;
                            hpd_ptr=i;
                        end;
                    end;
                
                    put hpd_ptr= hpd_low= hpd_high=;
            
                    call symput('left', trim(put(hpd_low, &format3.-l)));
                    call symput('right', trim(put(hpd_high, &format3.-l)));
            
                    stop;
                run;
            %end;
            
                %if &kde & %length(&weight) %then %do;
            proc kde data=&out(keep=&obs &chain &iter weight &&var&i 
                where=(n(&&var&i) & &by=&&byval&k
                    %if %length(&marker) %then & &iter>&marker; ));
                weight weight;
                
                univar &&var&i / noprint plots=none out=&scratch;
                
                %if &&byval&k>0 %then %do; 
                    by &by;
                    %*by &obs;
                    %let label=&&var&i[&&byval&k]:;
                %end;
                %else %let label=&&var&i:;
    
                %if "%lowcase(&labelcase)"^="lower" %then 
                    %let label=%upcase(&label);
            run;

            symbol1 i=needle v=none c=gray;
            %*symbol2 i=join v=none;
            
            proc gplot;
                %if &&byval&k>0 %then by &by;;
                plot (count /*density*/)*value; %* / overlay;            
                %if "&format1"^="." %then %do;
                    %if "&format2"^="." %then %let label=&label Mean(SD)=&mean(&std);
                    %else %let label=&label Mean=&mean;
    
                    %if "&format3"^="." %then %let label=&label,;
                %end;

                %if "&format3"^="." %then 
                    %let label=&label %sysevalf(%scan(&pctlpts, 2, %str( ))-%scan(&pctlpts, 1, %str( )))%=(&left, &right);
                
                label value="&label" count='%';
            run;
                %end;
                %else %if %length(&&histogram&i) %then %do;
                    %if %length(&left) %then %do;
                        %if &hpd %then %let histogram&i=&&histogram&i href=&left &median &right lhref=2;
                        %else %let histogram&i=&&histogram&i href=&left &mean &right lhref=2;
                    %end;
                    
            proc univariate noprint data=&out(keep=&obs &chain &iter &&var&i 
                where=(n(&&var&i) & &by=&&byval&k
                    %if %length(&marker) %then & &iter>&marker; ));
                
                histogram &&var&i / &&histogram&i;
                    
                %if &&byval&k>0 %then %do; 
                    by &by;
                    %*by &obs;
                    %let label=&&var&i[&&byval&k]:;
                %end;
                %else %let label=&&var&i:;
             
                %if "%lowcase(&labelcase)"^="lower" %then 
                    %let label=%upcase(&label);
                    
                %if &hpd %then %do;
                    %if "&format1"^="." %then %do;
                        %if "&format2"^="." %then %let label=&label Q2(IQR)=&median(&qrange);
                        %else %let label=&label Median=&median;
                    %end;               
                %end;               
                %else %do;
                    %if "&format1"^="." %then %do;
                        %if "&format2"^="." %then %let label=&label Mean(SD)=&mean(&std);
                        %else %let label=&label Mean=&mean;
                    %end;
                %end;
                
                %if "&format3"^="." %then %do;
                    %if "&format1"^="." %then %let label=&label,;
                    
                    %let label=&label %sysevalf(%scan(&pctlpts, 2, %str( ))-%scan(&pctlpts, 1, %str( )));
                    
                    %if &hpd %then %let label=&label.%nrbquote(%)HPD=(&left, &right);
                    %else %let label=&label.%nrbquote(%)CI=(&left, &right);
                %end;
                
                label &&var&i="&label";
            run;                
                %end;
            %end;
        %end;
        
        %if &bgr & %sysfunc(indexw(%upcase(&discrete), %upcase(&&var&i)))=0 %then %do;
            proc univariate noprint data=&out(keep=&obs &chain &iter &&var&i
                where=(n(&&var&i) & &chain=1) );
                by &obs;
                var &iter;
                output out=&scratch pctlpre=_ pctlpts=0 to 100 by 2.5;
        	run;    
                    
            %do k=1 %to 40;
                %local start&k stop&k; 
            %end;
            
            data _null_;
                set &scratch;
                array _pctlpts(41) _0 _2_5 _5 _7_5 _10 _12_5 _15 _17_5 _20 _22_5 _25 _27_5 _30
                    _32_5 _35 _37_5 _40 _42_5 _45 _47_5 _50 _52_5 _55 _57_5 _60 _62_5 _65
                    _67_5 _70 _72_5 _75 _77_5 _80 _82_5 _85 _87_5 _90 _92_5 _95 _97_5 _100;
                do k=1 to 20;
                    call symput('start'||left(k), trim(left(_pctlpts(k+1))));
                    call symput('stop' ||left(k), trim(left(_pctlpts(2*k+1))));
                end;
                stop;
            run;

    	%let scratch00=%_scratch;

    	data &scratch00;
    	    set &scratch(keep=&obs);
    	    retain k v 0 Rc 0.99 RcUpper 1.2; 
    	run;

            %do k=1 %to 20;
            proc univariate noprint data=&out(keep=&obs &chain &iter &&var&i
    	    where=(n(&&var&i) & &&start&k<&iter<=&&stop&k ));
                by &obs &chain;
                var &&var&i;
                output out=&scratch mean=mean_&&var&i var=var_&&var&i;
        	run;    

            data &scratch;
                set &scratch;
                meansq_&&var&i=mean_&&var&i**2;
            run;
        
            %let scratch0=%_scratch;
        
            proc corr cov noprint data=&scratch outp=&scratch0;
                by &obs;
                var mean_&&var&i meansq_&&var&i var_&&var&i;
            run;
            
            proc glm noprint data=&out(keep=&obs &chain &iter &&var&i
        	where=(n(&&var&i) & &&start&k<&iter<=&&stop&k )) outstat=&scratch;
                by &obs;
                class &chain;
                model &&var&i=&chain;
            run;
            
            data &scratch;
                merge 
    		&scratch0(keep=&obs _type_ _name_ var_&&var&i
    	            where=(_type_='COV' & upcase(_name_)=upcase("MEAN_&&var&i"))
    		    rename=(var_&&var&i=cov_mean_var_&&var&i))
    		&scratch0(keep=&obs _type_ _name_ meansq_&&var&i var_&&var&i
    	            where=(_type_='COV' & upcase(_name_)=upcase("VAR_&&var&i"))
    		    rename=(var_&&var&i=var_var_&&var&i
    			    meansq_&&var&i=cov_meansq_var_&&var&i))
    		&scratch0(keep=&obs _type_ mean_&&var&i
    	            where=(_type_='MEAN') 
                        rename=(mean_&&var&i=mean_mean_&&var&i))
    		&scratch(where=(_type_ in('ERROR', 'SS1')))
                ;
    	    by &obs;
    	    drop _type_ _name_ _source_ ss df f prob mp1 mm1 nm1 ntm dp1 dp3;

                label
                     Rc     ="BGR for &&var&i"
                     RcUpper="%sysevalf(&alpha/2) cutoff under the null"
                     RcTest ="Test of the null (convergence)"
                     v      ='sqrt(V)'
                     w      ='sqrt(W)'
                ;
                
                retain n b w;
            
                if first.&obs then n=df+1;
                else n=n+df;
            
                if _type_='ERROR' then w=ss/df;
                else b=ss/df;
            
                if last.&obs & w>0 then do;
                    m=&chains;
                    mp1=%eval(&chains+1);
                    mm1=%eval(&chains-1);
                    ntm=n;
                    n=n/m;
                    nm1=n-1;
                    v=(nm1*w/n)+(mp1*b/ntm);

                    var_v=(((nm1/n)**2)*var_var_&&var&i/m)+
                        2*(((((mp1*b)/ntm)**2)/mm1)
                          +(mp1*nm1/(ntm*m))*(cov_meansq_var_&&var&i
                          -2*mean_mean_&&var&i*cov_mean_var_&&var&i));  

                    d=2*(v**2)/var_v;
                    dp1=d+1;
                    dp3=d+3;
                    Rc=sqrt((dp3*v)/(dp1*w));
                    Rcupper=sqrt(((nm1/n)+(mp1/ntm)*
                        finv(%sysevalf(1-&alpha/2), mm1, 2*(w**2)*m/var_var_&&var&i))*
                        (dp3/dp1));
                    if Rc<Rcupper then Rctest='Accept';
                    else Rctest='Reject';
                    
                    v=sqrt(v);
                    w=sqrt(w);

                    output;
                end;
            run;
        
    	data &scratch00;
    	    set &scratch00 &scratch(in=_in_) end=last;
    	    by &obs;

    	    if _in_ then do;
                &iter=&&stop&k;
                k=&k;
            end;
    	run;
            %end;

            %if &graphics=1 %then %do;
                %if &j=1 %then %do;
                    goptions gsfmode=append;
                    %ANNOMAC(NOMSG);
                %end;
                
            data &scratch0;
                length text $ 1;
                set &scratch00;
                where RcTest>' ';
                retain xsys ysys '2' hsys '4';
                
                %move(&iter, 0.99);
                %draw(&iter, max(Rc, RcUpper), black, 1, 1);
                %label(&iter, max(Rc, RcUpper), RcTest, black, 0, 0, 1.25, swiss, 2);
            run;
            
            symbol1 &symbol width=&width;

    	    proc gplot data=&scratch00;
    		plot (Rc RcUpper)*&iter / overlay anno=&scratch0; %* vaxis=0.99 to 1.20 by 0.01;
    		plot2 (v w)*&iter / overlay;
    		by &obs;
                
                label v="sqrt(V), sqrt(W)";
                footnote 'BGR Test of the Null (convergence): A=Accept, R=Reject';
    	    run; 
            quit;  
                
            symbol1;
            footnote;
            %end;
            %else %do;        
            proc print noobs label data=&scratch00;
                where k>10;
                by &obs;
                id &iter k;
                var  Rc: v w;
            run;
            %end;
        %end;
            
            %if &graphics=1 & &trace=1 %then %do;
                %if %length(&lsd) %then goptions gsfmode=&gsfmode;
                %else %if &j=1 %then goptions gsfmode=append;;

                %let m=1;
                
                %if &chains>1 %then %do l=1 %to &chains;
                    %let k=%_substr(&l, %length(&l));
    
                    symbol&l v="&k" i=join c=%scan(&colors, &m, %str( )) r=1; 
    
                    %let m=%eval(&m+1);
    
                    %if &m>&color0 %then %let m=1;
                %end;
                %else symbol1 &symbol width=&width;;

    	    proc gplot data=&out(keep=&obs &chain &iter &&var&i where=(n(&&var&i))); 
            	by &obs;
            	plot &&var&i*&iter=&chain;
    	    run;
    	    quit;
            
                %if &chains>1 %then %do l=1 %to &chains; symbol&l; %end;
            %end;

            %if "&autocorr"^="0" %then %do;
                %let autocorr=%_list(&autocorr);
            
                %do k=1 %to %_count(&autocorr);
                    %local autocorr&k;
                    %let autocorr&k=%scan(&autocorr, &k, %str( ));
                
        	    %if &graphics=1 %then %_printto(file=.autocorr_debugs_&sysjobid..txt);
                    proc arima data=&out(keep=&obs &chain &iter &&var&i 
                        where=(n(&&var&i) & &chain=&&autocorr&k));
                        by &obs &chain;
                        identify var=&&var&i nlag=&nlag;
                        %if &graphics=1 %then label &obs="&obs";;
                    run;
                    quit;

                    %if &graphics=1 %then %do;
                        %_printto;
                        %let scratch=%_scratch;

                        proc sort data=&out(keep=&obs &chain &&var&i
                            where=(n(&&var&i) & &chain=&&autocorr&k))
                                nodupkey out=&scratch;
                            by &obs;
                        run;

                        %let nobs=%_nobs(data=&scratch);
                        %let scratch0=%_scratch;

                        %do l=1 %to &nobs;
                        data _null_;
                            l=&l;  
                            set &scratch point=l;
                            call symput('m', trim(left(&obs)));
                            stop;
                        run;

                        data &scratch0;
                            drop cov n;
                            retain &obs &m &chain &&autocorr&k;
                            label lag='Lag' corr="&&var&i";
                            infile ".autocorr_debugs_&sysjobid..txt";

                            input @"&obs=&m ";
                            input @'Number of Observations' n;
                            input @'Lag';
                            call symput('cl95', trim(left(2/sqrt(n))));

                            %do lag=1 %to &nlag;
                                input @"%_repeat(%str( ), %length(&nlag)-%length(&lag))&lag " cov corr;
                                lag=&lag;
                                output;
                            %end; 

                            stop;
                        run;

                        %if &j=1 %then goptions gsfmode=append;;

                        symbol1;
                        symbol1 i=needle width=&width;

                        proc gplot data=&scratch0;
                            by &obs &chain;
                            plot corr*lag / overlay vaxis=-1 to 1 by 0.1 vref=-&cl95 0 &cl95;
                        run;
                        quit;
                        %end;

                        &debug.x "%_unwind(rm, del) .autocorr_debugs_&sysjobid..txt";
                    %end;
                %end;
            %end;
        %end;
    %end;
    
    %let scratch0=%_scratch;
    %let var=;
    
    %if /*%_count(&list)>1 &*/ &crosscorr^=0 %then %do k=1 %to %_count(&crosscorr);
        %local crosscorr&k;
        %let crosscorr&k=%scan(&crosscorr, &k, %str( ));
       
        proc sort data=&out out=&scratch0;
            by &iter;
            where &chain=&&crosscorr&k;
        run;
       
        %do i=1 %to &j;
            %let var&i=%scan(&list, &i, %str( ));
            %local scratch&i;
            %let scratch&i=%_scratch;
            
            proc transpose data=&scratch0 out=&&scratch&i prefix=&&var&i;
                by &iter;
                id &obs;
                where n(&&var&i) & &obs>0;
                var &&var&i;
            run;
    
            %if %_nobs(data=&&scratch&i)=0 %then %let scratch&i=;
                
            %if %_nobs(data=&scratch0, where=n(&&var&i) & &obs=0)>0 %then %let var=&var &&var&i;
        %end;
        
        data &scratch0;
            merge &scratch0(keep=&obs &iter &var 
                where=(&obs=0))
                %do i=1 %to &j; &&scratch&i %end;;
            by &iter;
            drop &obs &iter;
        run;
       
        proc corr nosimple;
        run;
    %end;
%mend _debugs;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate

*/
