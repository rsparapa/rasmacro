/*****************************************************************
                                                                  
_ADJSURV calculates the direct adjusted survival probabilities   
for K treatment groups at predetermined time points, based on     
a regular Cox model (Model=2) or a stratified Cox regression model
(Model=1).                                                        
                                                                  
Macro parameters:                                                 
   inputdata - the input sas data name;                           
   time      - the survival time variable;                        
   event     - the event indicator;                               
   group     - the treatment group variable,                      
                    which must take values 1,...,K for K<10 groups  
   covlist   - a list of covariate names;                         
   model     - 1 if a stratified Cox model is selected,           
               2 if a regular Cox model is selected;              
   outdata   - the output sas data name.                          
                                                                  
The output dataset contains:                                      
   time - the event times                                         
   survi, i=1,...,K                                               
   sei,   i=1,...,K                                               
   seij, 1<=i<j<=K                                               

Authored by Xu Zhang 2007
Re-formatted by Rodney Sparapani 02/17/2014                                                                    
*****************************************************************/

%*macro ADJSURV(inputdata, time, event, group, covlist, model, outdata); 
    
%macro _ADJSURV(data=REQUIRED, out=REQUIRED, time=REQUIRED, 
    event=REQUIRED, group=REQUIRED, x=REQUIRED, model=1, 
    inputdata=&data, outdata=&out, covlist=&x);

%_require(&data &time &event &group &out &x)

%local numgroup numcov i j adj1 adj2 group iter strata1 strata2;

%let covlist=%_list(&covlist); %* 08/18/15;

proc means data=&inputdata noprint;
    var &group;
    output out=maxout max(&group)=numgroup;
run;

data _null_;
    set maxout;
    call symput('numgroup', numgroup);	
run;

proc iml;
    use &inputdata;
    read all var {&covlist} into x;
    close &inputdata;

    numcov=ncol(x);

    create ncovout from numcov[colname='numcov'];
    append from numcov;
    close ncovout;
run;
quit;

data _null_;
    set ncovout;
    call symput('numcov', numcov);
run;

%if &model=2 %then %do;    

/************************************/
/*                                  */
/*  Model 2 : A regular Cox model   */
/*                                  */
/************************************/

/*************************************************/
/*                                               */
/*  Assign names to variables in the input data. */
/*                                               */
/*************************************************/

proc iml;
    use &inputdata;
    read all var {&time} into time;
    read all var {&event} into event;
    read all var {&group} into group;
    read all var {&covlist} into x;
    close &inputdata;

    numobs=nrow(time);

    gmat=j(&numgroup, &numgroup-1, 0);
    do i=2 to &numgroup;
 	gmat[i, i-1]=1;
    end;

    zmat=j(numobs, &numgroup-1+&numcov, 0);
    do i=1 to numobs;
	zmat[i,]=gmat[group[i],]||x[i,];
    end;

    out=time||event||zmat;

    names={'time' 'event' %do i=1 %to &numgroup-1+&numcov; "z&i" %end;};
    create indata from out[colname=names];
    append from out;
    close indata;
quit;

/**********************************************/
/*                                            */
/*  Get regression coefficient estimates from */
/*  proc phreg, read in these estimates and   */
/*  calculate s0(b,t), s1(b,t).               */
/*                                            */
/**********************************************/

ODS LISTING CLOSE;    
proc freq data=indata; 
    where event=1; 
    table time/out=dcount; 
run;    
ODS LISTING;    
    
proc sort data=indata; 
    by descending time event; 
run;            
            
proc phreg data=indata covout outest=best noprint;
    model time*event(0)=
        %do i=1 %to &numgroup-1+&numcov; z&i %end;;
    output out=coxout xbeta=zb;	
run;

proc sort data=coxout; 
    by descending time; 
run;

data best sigma;
    set best;
    if _type_='PARMS' then output best;
    if _type_='COV' then output sigma; 
run;

data riskset;
    set coxout; 
    by descending time;
    keep time s0 s1:;
    
    s0+exp(zb);
    
    %do i=1 %to &numcov+&numgroup-1;
	s1_&i+z&i * exp(zb);
    %end;
    
    if event;
run;

data riskset;
    set riskset; 
    by descending time;
    
    if last.time;
run;
    
proc sort data=riskset; 
    by time; 
run;
    
data riskset;
    merge riskset dcount (keep=time count); 
    by time;
run;

/****************************************/
/*                                      */
/*  Get weighted survival function      */
/*  estimate and its variance estimate  */
/*                                      */
/****************************************/
                   
proc iml;
    use riskset;
    read all var{time} into time;
    read all var{s0} into s0;
    read all var{%do i=1 %to &numgroup-1+&numcov; s1_&i %end;} into s1;
    read all var{count} into count;
    close riskset;
              
    use best;
    read all var{%do i=1 %to &numgroup-1+&numcov; z&i %end;} into b;
    close best;

    use sigma;
    read all var{%do i=1 %to &numgroup-1+&numcov; z&i %end;} into sigma;
    close sigma;

    use indata;
    read all var{%do i=&numgroup %to &numgroup-1+&numcov; z&i %end;} into zmat;
    close indata;

    numtime=nrow(time);
    numobs=nrow(zmat);
    numcov=ncol(s1);    

    ctemp=0;
    wtemp=0;
    cumuhaz=j(numtime,1,0);
    w1=j(numtime,1,0);

    do i=1 to numtime;
   	ctemp=ctemp+count[i]/s0[i];
	wtemp=wtemp+count[i]/s0[i]/s0[i];
	cumuhaz[i]=ctemp;
	w1[i]=wtemp;
    end;
    
/********************************************************/
/*                                                      */
/*  Do loop calculate the direct adjusted probabilities */
/*  and their variance estimates at time 'tau'.         */
/*                                                      */
/********************************************************/
   
    g=j(&numgroup, &numgroup-1,0);

    do i=2 to &numgroup;
        g[i,i-1]=1;
    end;

    survmat=time;
        
    %do iter=1 %to &numgroup;    
    zz=j(numobs, &numgroup-1+&numcov, 0);

    do 	i=1 to numobs;
	zz[i,]=g[&iter,]||zmat[i,];
    end;
  	
    adjsurv=j(numtime,1,0);      
    fexpbz=j(numtime,1,0);
    fh=j(numtime,numcov,0);

    do i=1 to numobs;
        expbz=exp(zz[i,]*t(b));
        surv=exp(-cumuhaz)##expbz;
        adjsurv=adjsurv+surv;
	fexpbz=fexpbz+surv#expbz;

	h=j(numtime,numcov,0);
	htemp=j(1,numcov,0);
    
	do j=1 to numtime;
	    htemp=htemp+count[j]/s0[j]*(zz[i,]-s1[j,]/s0[j]);
	    h[j,]=htemp;
	end;

	fh=fh+surv#h#expbz;
    end;
    
    term1=(fexpbz##2)#w1;
    term2=j(numtime,1,0);
    
    do i=1 to numtime;
	term2[i]=fh[i,]*sigma*t(fh[i,]);
    end;
    
    varsurv=term1+term2;
    adjsurv=adjsurv/numobs;
    varsurv=varsurv/numobs/numobs;

    sesurv=varsurv##0.5;                 

    survmat=survmat||adjsurv||sesurv;                                
    %end;

/*********************************************************/
/*                                                       */
/*  Calculate covariance estimates between two direct    */
/*  adjusted survival probabilities.                     */
/*                                                       */
/*********************************************************/

    %do adj1=1 %to &numgroup;

    z1=j(numobs, &numgroup-1+&numcov, 0);
    
    do i=1 to numobs;
	z1[i,]=g[&adj1,]||zmat[i,];
    end;

        %do adj2=&adj1+1 %to &numgroup;

        z2=j(numobs, &numgroup-1+&numcov, 0);    	

        do i=1 to numobs;
            z2[i,]=g[&adj2,]||zmat[i,];
        end;
 
        fe2_fe1=j(numtime,1,0);
        fh2_fh1=j(numtime,numcov,0);

        do i=1 to numobs;
            h1=j(numtime,numcov,0);
            htemp1=j(1,numcov,0);
            
            do j=1 to numtime;
                htemp1=htemp1+count[j]/s0[j]*(z1[i,]-s1[j,]/s0[j]);
                h1[j,]=htemp1;
            end;

            h2=j(numtime,numcov,0);
            htemp2=j(1,numcov,0);
            
            do j=1 to numtime;
                htemp2=htemp2+count[j]/s0[j]*(z2[i,]-s1[j,]/s0[j]);
        	h2[j,]=htemp2;
            end;

            expbz1=exp(z1[i,]*t(b));
            expbz2=exp(z2[i,]*t(b));
            surv1=exp(-cumuhaz)##expbz1;
            surv2=exp(-cumuhaz)##expbz2;

            fe2_fe1=fe2_fe1+surv2#expbz2-surv1#expbz1;
            fh2_fh1=fh2_fh1+surv2#h2#expbz2-surv1#h1#expbz1;
        end;

        term1=(fe2_fe1##2)#w1;
        term2=j(numtime,1,0);
        
        do i=1 to numtime;
            term2[i]=fh2_fh1[i,]*sigma*t(fh2_fh1[i,]);
        end;

        covar=term1+term2;            
        covar=covar/numobs/numobs;                
        sqcov=covar##0.5;                

        survmat=survmat||sqcov;
        
        %end;
    %end;    
                 
    names={'time' %do i=1 %to &numgroup; "surv&i" "se&i" %end; 
        %do i=1 %to &numgroup; 
            %do j=&i+1 %to &numgroup; "se&i.&j" %end; 
        %end; };
    create mout from survmat[colname=names]; 
    append from survmat; 
    close mout;
run;
quit;

%end;
%else %do;

/***************************************/
/*                                     */
/*  Model 1 : a stratified Cox model   */
/*                                     */
/***************************************/    

proc iml;
    use &inputdata;
    read all var {&time} into time;
    read all var {&event} into event;
    read all var {&group} into group;
    read all var {&covlist} into x;
    close &inputdata;
    
    out=time||event||group||x;

    names={'time' 'event' 'strata' %do i=1 %to &numcov; "z&i" %end;};
    create indata from out[colname=names];
    append from out;
    close indata;
run;
quit;

/**********************************************/
/*                                            */
/*  Get regression coefficient estimates from */
/*  proc phreg, read in these estimates and   */
/*  calculate s0(b,t), s1(b,t).               */
/*                                            */
/**********************************************/
    
proc sort data=indata; 
    by descending time descending event; 
run;                        

data alltime;
    set indata (keep=time event); 
    by descending time;
    drop event;
    
    if first.time;
    
    if event;
run;

proc sort data=alltime; 
    by time; 
run;

proc phreg data=indata covout outest=best noprint;
    model time*event(0)=%do i=1 %to &numcov; z&i %end;;
    strata strata;
    output out=coxout xbeta=zb;
run;

proc sort data=coxout; 
    by strata descending time; 
run;

data best sigma;
    set best;
    
    if _type_='PARMS' then output best;
    else if _type_='COV' then output sigma; 
run;
   
    %do group=1 %to &numgroup;       

data riskset&group;
    set coxout (keep=time strata %do i=1 %to &numcov; z&i %end; zb); 
    where strata=&group;
    by descending time;
    keep time s0 %do i=1 %to &numcov; s1_&i %end;;
    
    s0+exp(zb);
    
    %do i=1 %to &numcov;
	s1_&i+z&i * exp(zb);
    %end;
    
    if last.time;
run;

proc sort data=riskset&group; 
    by time; 
run;

ODS LISTING CLOSE;    
proc freq data=indata; 
    where strata=&group & event=1; 
    table time/out=dcount&group; 
run;    
ODS LISTING;    

data riskset&group;
    merge alltime (in=inall) riskset&group dcount&group (keep=time count); 
    by time;
    drop ts:;
    retain ts0 %do i=1 %to &numcov; ts1_&i %end; 999;
    
    if inall;
    
    if count=. then count=0;
    
    if s0^=. then ts0=s0;
    else s0=ts0;
    
    %do i=1 %to &numcov;
	if s1_&i^=. then ts1_&i=s1_&i;
	else s1_&i=ts1_&i;
    %end;
run;              
                  
/*****************************************************/
/*                                                   */
/*  Calculate direct adjusted survival probabilites  */
/*  and their variance estimates at time 'tau'.      */
/*                                                   */
/*****************************************************/
       
proc iml;
    use riskset&group;
    read all var{time} into time;
    read all var{s0} into s0;
    read all var{%do i=1 %to &numcov; s1_&i %end;} into s1;
    read all var{count} into count;
    close riskset&group;
        
    use best;
    read all var{%do i=1 %to &numcov; z&i %end;} into b;
    close best;

    use sigma;
    read all var{%do i=1 %to &numcov; z&i %end;} into sigma;
    close sigma;
                
    use indata;
    read all var{%do i=1 %to &numcov; z&i %end;} into zmat;
    close indata;
    
    numtime=nrow(s0);
    numcov=ncol(s1);            
                                  
    cumuhaz=j(numtime,1,0);
    w1=j(numtime,1,0);
       
    ctemp=0;
    wtemp=0;       
    
    do i=1 to numtime;
        ctemp=ctemp+count[i]/s0[i];
        wtemp=wtemp+count[i]/s0[i]/s0[i];       
 	cumuhaz[i]=ctemp;
	w1[i]=wtemp;
    end; 
                         
    numobs=nrow(zmat);
        
    adjsurv=j(numtime,1,0);
    varsurv=j(numtime,1,0);    
    fexpbz=j(numtime,1,0);
    fh=j(numtime,numcov,0);
    
    do i=1 to numobs;
        expbz=exp(zmat[i,]*t(b));
        surv=exp(-cumuhaz)##expbz;
        adjsurv=adjsurv+surv;
	fexpbz=fexpbz+surv#expbz;	

    	h=j(numtime,numcov,0);
 	htemp=j(1, numcov, 0);
    
	do j=1 to numtime;
	    htemp=htemp + count[j]/s0[j]*(zmat[i,]-s1[j,]/s0[j]); 
	    h[j,]=htemp;
    	end;
    
	fh=fh+surv#h#expbz;
    end;
    
    adjsurv=adjsurv/numobs;
    term1=(fexpbz##2)#w1;
    term2=j(numtime,1,0);
    
    do i=1 to numtime;
	term2[i]=fh[i,]*sigma*t(fh[i,]);
    end;

    varsurv=term1+term2;
    varsurv=varsurv/numobs/numobs;
    sesurv=varsurv##0.5;
   
    outmat=time||adjsurv||sesurv;
    names={'time' 'surv' 'se'};
    create surv&group from outmat[colname=names];
    append from outmat;
    close surv&group;
run;
quit;            

%end;                                  
                    
/*******************************************************/
/*                                                     */
/*  Calculate covariance estimates between two direct  */
/*  adjusted survival probabilities.                   */
/*                                                     */
/*******************************************************/                

%do strata1=1 %to &numgroup;
    %do strata2=&strata1+1 %to &numgroup;
    
proc iml;
    use riskset&strata1;
    read all var{time} into time;
    read all var{s0} into s01;
    read all var{%do i=1 %to &numcov; s1_&i %end;} into s11;
    read all var{count} into count1; 
    close riskset&strata1;        

    use riskset&strata2;
    read all var{s0} into s02;
    read all var{%do i=1 %to &numcov; s1_&i %end;} into s12;
    read all var{count} into count2; 
    close riskset&strata2;                
        
    use best;
    read all var{%do i=1 %to &numcov; z&i %end;} into b;
    close best;
        
    use sigma;
    read all var{%do i=1 %to &numcov; z&i %end;} into sigma;
    close sigma;
                            
                    
    use indata;
    read all var{%do i=1 %to &numcov; z&i %end;} into zmat;
    close indata;
    
    numtime=nrow(time);               
    numobs=nrow(zmat);
    numcov=ncol(s11);
    
    cumuhaz1=j(numtime,1,0);
    cumuhaz2=j(numtime,1,0);
    w1=j(numtime,1,0);
    w2=j(numtime,1,0);
    ctemp1=0;
    ctemp2=0;  
    wtemp1=0;
    wtemp2=0;  
 
    do i=1 to numtime;
        ctemp1=ctemp1+count1[i]/s01[i];
        ctemp2=ctemp2+count2[i]/s02[i];
	wtemp1=wtemp1+count1[i]/s01[i]/s01[i];
	wtemp2=wtemp2+count2[i]/s02[i]/s02[i];
    	cumuhaz1[i]=ctemp1;
    	cumuhaz2[i]=ctemp2;
    	w1[i]=wtemp1;
    	w2[i]=wtemp2;
    end;

    fexpbz1=j(numtime,1,0);
    fexpbz2=j(numtime,1,0);
    fh2_fh1=j(numtime,numcov,0);

    do i=1 to numobs;
        expbz=exp(zmat[i,]*t(b));
        surv1=exp(-cumuhaz1)##expbz;
        surv2=exp(-cumuhaz2)##expbz; 
	fexpbz1=fexpbz1+surv1#expbz;
	fexpbz2=fexpbz2+surv2#expbz;

    	h1=j(numtime,numcov,0);
	h2=j(numtime,numcov,0);
 	htemp1=j(1, numcov, 0);
	htemp2=j(1, numcov, 0);

	do j=1 to numtime;
	    htemp1=htemp1 + count1[j]/s01[j]*(zmat[i,]-s11[j,]/s01[j]); 
	    htemp2=htemp2 + count2[j]/s02[j]*(zmat[i,]-s12[j,]/s02[j]); 
	    h1[j,]=htemp1;
	    h2[j,]=htemp2;
    	end;

	fh2_fh1=fh2_fh1+surv2#h2#expbz-surv1#h1#expbz;
    end;

    term1=(fexpbz1##2)#w1;
    term2=(fexpbz2##2)#w2;
    term3=j(numtime,1,0);

    do i=1 to numtime;
	term3[i]=fh2_fh1[i,]*sigma*t(fh2_fh1[i,]);
    end;

    covar=term1+term2+term3;
    covar=covar/numobs/numobs;

    cov=covar##0.5;
    names={'se'};
    create cov&strata1&strata2 from cov[colname=names];
    append from cov;
    close cov&strata1&strata2;
run;
quit;    
     
    %end;
%end;

data mout;
    merge  
        %do group=1 %to &numgroup; 
            surv&group (rename=(surv=surv&group se=se&group)) 
        %end;
        
        %do i=1 %to &numgroup; 
            %do j=&i+1 %to &numgroup; cov&i&j (rename=(se=se&i.&j)) %end; 
        %end;;
run;        

%end;

/**************************************/
/*                                    */
/*  Make final output data            */
/*                                    */
/**************************************/     

data &outdata;
    time=0;
    
    %do i=1 %to &numgroup; 
        surv&i=1; 
        se&i=0;
        
        %do j=&i+1 %to &numgroup; se&i.&j=0; %end; 
    %end;        
        
    output;
run;

data &outdata;
    set &outdata mout;
    by time;
run;     
        
%mend;

