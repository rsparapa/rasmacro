/******************************************************************                                                      
                                                                   
This macro computes the direct adjusted cumulative incidence curves
for K treatment groups, based on a proportional subdistribution    
hazards model with treatment groups as strata.                     
                                                                   
Macro parameters:                                                  
   inputdata - the input sas data name;                            
   time      - the survival time variable;                         
   event     - 0 (censor) 1 (cause of interest) 2 (other causes);  
   group     - the treatment group variable,                       
                    which must take values 1,...,K for K<10 groups   
   covlist   - a list of covariate names;                          
   outdata   - the output sas data name.                           
                                                                   
The output dataset contains:                                       
   Time - the event times                                          
   CIFi, i=1,...,K                                                 
   SEi, i=1,...,K                                                  
   SEij, 1<=i<j<=K                                                
                                                                   
***************************************************************/
%*imported/re-formatted/hardened 02/18/2014;
%*macro DACIF(inputdata, time, cause, group, covlist, outdata);

%macro _cifstrata(data=REQUIRED, out=REQUIRED, time=REQUIRED, 
    cause=REQUIRED, group=REQUIRED, x=REQUIRED,
    inputdata=&data, outdata=&out, covlist=&x);

%_require(&data &time &cause &group &out &x)

%local i j gp gp1 gp2 numcov numgroup;

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

proc iml;
    use &inputdata;
    read all var{&time &cause &group &covlist} into x;
    close &inputdata;    
    
    names={'time' 'cause' 'group' %do i=1 %to &numcov; "z&i" %end;};
    create indata from x[colname=names];
    append from x;
    close indata;
run;
quit;

proc sort data=indata; 
    by descending time descending cause; 
run;

data indata;
    set indata;
    atrisk+1;
run;

proc sort data=indata; 
    by time; 
run;

data cdata;
    set indata; 
    where cause=0;
    keep time atrisk;
run;

proc sort data=cdata; 
    by time descending atrisk; 
run;

proc freq data=cdata noprint;
    tables time /out=ccount;
run;

proc sort data=ccount; 
    by time; 
run;

data cdata;
    merge cdata ccount; 
    by time;
    drop percent ctemp;
    retain ctemp 1;
    
    ctemp=ctemp*(1-count/atrisk);
    csurv=ctemp;
    dcna=count/atrisk;
    ctime=time;
    time=time+0.00001;
run;

data indata;
    merge indata (in=in1) cdata (keep=time csurv); 
    by time;
    retain ctemp 1;
    
    if csurv^=. then ctemp=csurv;
    else csurv=ctemp;
    
    if in1;
run;


data e1time;
    set indata; 
    keep time csurv;
    where cause=1;
run;

proc sort; 
    by time; 
run;

data e1time;
    set e1time; 
    by time;
    
    if first.time;
run;

%do gp=1 %to &numgroup;
data indata&gp;
    set indata; 
    where group=&gp;
run;

data in&gp._10 in&gp._2;
    set indata&gp;
    if cause in (0,1) then output in&gp._10;
    else output in&gp._2;
run;
%end;

proc phreg data=indata out=best noprint;
    model time*cause(0,2)=%do i=1 %to &numcov; z&i %end; ;
    strata group;
run;

%let tnum=%eval(&numcov*(&numcov+1)/2);
    
proc iml;

%do gp=1 %to &numgroup;
    use in&gp._10;
    read all var{time} into time&gp._10;
    read all var{cause} into cause&gp._10;
    read all var{%do i=1 %to &numcov; z&i %end;} into z&gp._10;
    close in&gp._10;

    use in&gp._2;
    read all var{time} into time&gp._2;
    read all var{cause} into cause&gp._2;
    read all var{csurv} into ckm&gp._2;
    read all var{%do i=1 %to &numcov; z&i %end;} into z&gp._2;
    close in&gp._2;

    numobs&gp._10=nrow(time&gp._10);
    numobs&gp._2=nrow(time&gp._2);
    numobs&gp=numobs&gp._10+numobs&gp._2;
    numtime&gp=nrow(etime&gp);   

    time=time//time&gp._10//time&gp._2;
    cause=cause//cause&gp._10//cause&gp._2;

    zz=zz//z&gp._10//z&gp._2;

    gtemp=j(numobs&gp,1,&gp);
    group=group//gtemp;
%end;

    use e1time;
    read all var{time} into etime;
    read all var{csurv} into eckm;
    close e1time;   

    use cdata;
    read all var{ctime} into ctime;
    read all var{dcna} into dcna;
    read all var{atrisk} into pi;
    close cdata;

    use best;
    read all var{%do i=1 %to &numcov; z&i %end;} into best;
    close best;

    numctime=nrow(ctime);    
        
    numobs=nrow(zz);
    
    numtime=nrow(etime);

    cidx=j(numctime,1,0);

    do i=1 to numctime;
	if ctime[i]>etime[numtime] then cidx[i]=-1;
    	else do;
	    do j=1 to numtime until(etime[j]>=ctime[i]);
	    end;
	    cidx[i]=j;
	end;
    end;

    %do gp=1 %to &numgroup;

    numdeath&gp=j(numtime,1,0);
    covsum&gp=j(numtime,&numcov,0);
    
    do i=1 to numtime;
	do j=1 to numobs&gp._10;
	    if time&gp._10[j]=etime[i] & cause&gp._10[j]=1  then do;
                numdeath&gp[i] = numdeath&gp[i] + 1;
                covsum&gp[i,] = covsum&gp[i,] + z&gp._10[j,];            
	    end;
	end;
    end;

    eidx&gp=j(numtime,1,0);
    
    do i=1 to numtime;    	
	do j=1 to numobs&gp._10 until(time&gp._10[j]>=etime[i]);
	end;
	eidx&gp[i]=j;
    end;

    %end;

    b=j(1,&numcov,0);
    b=best;
  
    incre=1;

    do iter=1 to 20 until(incre<.0005);        

    score=j(1,&numcov,0);
    fisher=j(&numcov,&numcov,0);
    loglike=0;        

    %do gp=1 %to &numgroup;

    s0&gp._1=j(numtime,1,0);
    s1&gp._1=j(numtime,&numcov,0);
    s2&gp._1=j(numtime,&tnum,0);

    expbz10=j(numobs&gp._10,1,0);
    
    do i=1 to numobs&gp._10;
	expbz10[i]=b*t(z&gp._10[i,]);
    end;
    
    expbz10=exp(expbz10);

    expbz2=j(numobs&gp._2,1,0);
    
    do i=1 to numobs&gp._2;
	expbz2[i]=b*t(z&gp._2[i,]);
    end;
    
    expbz2=exp(expbz2);

    pres0=0;
    pres1=j(1,&numcov,0);
    pres2=j(1,&tnum,0);
    obsidx=numobs&gp._10;
    
    do i=numtime to 1 by -1;
	s0&gp._1[i]=pres0;
	s1&gp._1[i,]=pres1;
	s2&gp._1[i,]=pres2;
    
	do j=eidx&gp[i] to obsidx;
            s0&gp._1[i] = s0&gp._1[i] + expbz10[j];
            s1&gp._1[i,] = s1&gp._1[i,] + z&gp._10[j,]#expbz10[j];
            tonext=1;
            do m=1 to &numcov;
                do n=m to &numcov;
                    s2&gp._1[i,tonext] = s2&gp._1[i,tonext] + z&gp._10[j,m]#z&gp._10[j,n]#expbz10[j];
                    tonext = tonext + 1;
                end;
            end;
	end;
    
	pres0=s0&gp._1[i];
    	pres1=s1&gp._1[i,];
	pres2=s2&gp._1[i,];
	obsidx=eidx&gp[i]-1;
    end;

    s0&gp._2=j(numtime,1,0);
    s1&gp._2=j(numtime,&numcov,0);
    s2&gp._2=j(numtime,&tnum,0);
    
    do i=1 to numtime;
	do j=1 to numobs&gp._2;
	    cweight=eckm[i]/ckm&gp._2[j];
	    weight=min(1,cweight);
            s0&gp._2[i] = s0&gp._2[i] + expbz2[j]#weight;
            s1&gp._2[i,] = s1&gp._2[i,] + z&gp._2[j,]#expbz2[j]#weight;
            tonext=1;
    
            do m=1 to &numcov;
                do n=m to &numcov;
                    s2&gp._2[i,tonext] = s2&gp._2[i,tonext] + z&gp._2[j,m]#z&gp._2[j,n]#expbz2[j]#weight;
                    tonext = tonext + 1;
                end;
            end;
	end;
    end;

    s0&gp=s0&gp._1+s0&gp._2;
    s1&gp=s1&gp._1+s1&gp._2;
    s2&gp=s2&gp._1+s2&gp._2;

    do i=1 to numtime;
        score = score + covsum&gp[i,] - s1&gp[i,]#(numdeath&gp[i]/s0&gp[i]);

        tonext=1;
        do m=1 to &numcov;
            do n=m to &numcov;
                fisher[m,n] = fisher[m,n] + s2&gp[i,tonext]#(numdeath&gp[i]/s0&gp[i])
                    - s1&gp[i,m]#s1&gp[i,n]#(numdeath&gp[i]/s0&gp[i]##2);
                tonext = tonext + 1;
            end;
        end;
	
        loglike = loglike + b*t(covsum&gp[i,])-numdeath&gp[i]*log(s0&gp[i]); 
    end;

    %end;  
           	
    do m=2 to &numcov;
	do n=1 to m-1;
	    fisher[m,n]=fisher[n,m];
	end;
    end; 
 
    oldb=b;
    b = b + score*inv(fisher);
    
    bchange=b-oldb;
    incre=max(abs(bchange));           
    
    end;

    hazout=etime;

    %do gp=1 %to &numgroup;
    
    expbz10=j(numobs&gp._10,1,0);
    
    do i=1 to numobs&gp._10;
	expbz10[i]=b*t(z&gp._10[i,]);
    end;
    
    expbz10=exp(expbz10);

    expbz2=j(numobs&gp._2,1,0);
    
    do i=1 to numobs&gp._2;
	expbz2[i]=b*t(z&gp._2[i,]);
    end;
    
    expbz2=exp(expbz2);

    lambda1&gp=j(numtime,1,0);    
    dlambda1&gp=j(numtime,1,0);
    ltemp=0;
    
    do i=1 to numtime;
        if s0&gp[i]^=0 then do;
	    dlambda1&gp[i]=numdeath&gp[i]/s0&gp[i];
            ltemp=ltemp+dlambda1&gp[i];
	end;
    
        lambda1&gp[i]=ltemp;
    end;

    eta_1=j(numobs&gp._10,&numcov,0);
    dmart1&gp._1=j(numobs&gp._10,numtime,0);
    
    do i=1 to numobs&gp._10;
        do j=1 to numtime;
            if time&gp._10[i]>=etime[j] then dmart1&gp._1[i,j]=-dlambda1&gp[j]#expbz10[i];
            if cause&gp._10[i]=1 & time&gp._10[i]=etime[j] then dmart1&gp._1[i,j]=dmart1&gp._1[i,j]+1;
    
            eta_1[i,] = eta_1[i,] + (z&gp._10[i,]-s1&gp[j,]/s0&gp[j])*dmart1&gp._1[i,j];
 	end;
    end;

    eta_2=j(numobs&gp._2,&numcov,0);
    dmart1&gp._2=j(numobs&gp._2,numtime,0);
    
    do i=1 to numobs&gp._2;
        do j=1 to numtime;
	    cweight=eckm[j]/ckm&gp._2[i];
	    weight=min(1,cweight);
            dmart1&gp._2[i,j]=-dlambda1&gp[j]#expbz2[i]#weight;
            eta_2[i,] = eta_2[i,] + (z&gp._2[i,]-s1&gp[j,]/s0&gp[j])*dmart1&gp._2[i,j];
        end;
    end;

    eta=eta//eta_1//eta_2;
    
    dmart1=dmart1//dmart1&gp._1//dmart1&gp._2;
   
    hazout=hazout||lambda1&gp;

    %end;

    psi=j(numobs,&numcov,0);

    q=j(numctime,&numcov,0);

    do i=1 to numctime while (cidx[i]>0);
        %do gp=1 %to &numgroup;
	    do j=1 to numobs&gp._2 while (ctime[i]>time&gp._2[j]);
	    	do k=cidx[i] to numtime;
                    q[i,]=q[i,]+(z&gp._2[j,]-s1&gp[k,]/s0&gp[k])#dmart1&gp._2[j,k];
	    	end;
	    end;
	%end;
	q[i,]=q[i,]/pi[i];
    end;

    dcmart=j(numobs,numctime,0);
    
    do i=1 to numobs;
	do j=1 to numctime;
	    if time[i]>=ctime[j] then dcmart[i,j]=-dcna[j];
	    if time[i]=ctime[j] & cause[i]=0 then dcmart[i,j]=dcmart[i,j]+1;
	end;
    
	psi[i,]=-dcmart[i,]*q;
    end; 

    sigma=j(&numcov,&numcov,0); 
    
    do i=1 to numobs;
        sigma = sigma + t(eta[i,]+psi[i,])*(eta[i,]+psi[i,]);
    end;
            
    naivev = inv(fisher);
            
    robustv = inv(fisher)*sigma*inv(fisher);

    se=j(&numcov,1,0);
    
    do i=1 to &numcov;
	se[i]=sqrt(robustv[i,i]);
    end;

    bout=t(b)||se;

    create best from bout[colname={'Estimate' 'SE'}];
    append from bout;
    close best; 

    names={%do i=1 %to &numcov; "Z&i" %end;};
    create covest from robustv[colname=names];
    append from robustv;
    close covest;

    create basehaz from hazout[colname={'Time' %do i=1 %to &numgroup; "Base_haz&i" %end;}];
    append from hazout;
    close basehaz; 

/*	variance of direct adjusted CIF  */

    outmat=etime;

%do gp=1 %to &numgroup;    

    dacif=j(numtime,1,0);
    zfn1=j(numtime,1,0);
    zfn2=j(numtime,&numcov,0);
    
    do i=1 to numtime;
	do j=1 to numobs;
	    dacif[i]=dacif[i]+1-exp(-lambda1&gp[i]#exp(b*t(zz[j,])));
	    zfn1[i]=zfn1[i]+exp(-lambda1&gp[i]#exp(b*t(zz[j,]))+b*t(zz[j,]));
	    zfn2[i,]=zfn2[i,]+zz[j,]#exp(-lambda1&gp[i]#exp(b*t(zz[j,]))+b*t(zz[j,]));
	end;
    end;
    
    dacif=dacif/numobs;
    zfn1=zfn1/numobs;
    zfn2=zfn2/numobs;

    vut&gp=j(numctime, numtime,0);
    
    do i=1 to numctime while (cidx[i]>0);
	vtemp=0;
    
	do j=cidx[i] to numtime;
	    do k=1 to numobs&gp._2;
		if time&gp._2[k]<ctime[i] then vtemp=vtemp+1/s0&gp[j]#dmart1&gp._2[k,j];
	    end;
    
	    vut&gp[i,j]=-vtemp;
	end;
    
	vut&gp[i,]=vut&gp[i,]/pi[i];
    end;

    zbar&gp=j(numtime,&numcov,0);
    
    do i=1 to numtime;
	if s0&gp[i]^=0 then zbar&gp[i,]=s1&gp[i,]/s0&gp[i];
    end;

    htz&gp=j(numtime,&numcov,0);
    
    do i=1 to numtime;
	htemp=j(1,&numcov,0);
    
	do j=1 to i;
	    htemp=htemp+(zfn2[i,]-zfn1[i]#zbar&gp[j,])#dlambda1&gp[j];
	end;
    
	htz&gp[i,]=htemp;
    end;

    cifv=j(numtime,1,0);
    cifse=j(numtime,1,0);
    w1temp=j(numobs,1,0);

    do i=1 to numtime;
	w1=j(numobs,1,0);
	w2=j(numobs,1,0);
	w3=j(numobs,1,0);
    
	do j=1 to numobs;
	    if s0&gp[i]^=0 & group[j]=&gp then w1temp[j]=w1temp[j]+1/s0&gp[i]#dmart1[j,i];
    
	    w1[j]=w1temp[j]#zfn1[i];
	    w2[j]=htz&gp[i,]*naivev*t(eta[j,]+psi[j,]);
	    w3[j]=w3[j]+dcmart[j,]*vut&gp[,i]#zfn1[i];

	    tempw=w1[j]+w2[j]+w3[j];
	    cifv[i]=cifv[i]+tempw#tempw;
	end;
    end;

    cifse=cifv##0.5;

    outmat=outmat||dacif||cifse;
%end;

%do gp1=1 %to &numgroup-1;
    %do gp2=&gp1+1 %to &numgroup;

	zfn1=j(numtime,1,0);
	zfn2=j(numtime,&numcov,0);
    
	do i=1 to numtime;
	    do j=1 to numobs;
		zfn1[i]=zfn1[i]+exp(-lambda1&gp1[i]#exp(b*t(zz[j,]))+b*t(zz[j,]));
		zfn2[i,]=zfn2[i,]+zz[j,]#exp(-lambda1&gp1[i]#exp(b*t(zz[j,]))+b*t(zz[j,]));
	    end;
	end;
    
	zfn1=zfn1/numobs;
	zfn2=zfn2/numobs;

	zfn3=j(numtime,1,0);
	zfn4=j(numtime,&numcov,0);
    
	do i=1 to numtime;
	    do j=1 to numobs;
		zfn3[i]=zfn3[i]+exp(-lambda1&gp2[i]#exp(b*t(zz[j,]))+b*t(zz[j,]));
		zfn4[i,]=zfn4[i,]+zz[j,]#exp(-lambda1&gp2[i]#exp(b*t(zz[j,]))+b*t(zz[j,]));
	    end;
	end;
    
	zfn3=zfn3/numobs;
	zfn4=zfn4/numobs;

	htz=j(numtime,&numcov,0);
    
	do i=1 to numtime;
	    htemp=j(1,&numcov,0);
    
	    do j=1 to i;
		htemp=htemp+(zfn2[i,]-zfn1[i]#zbar&gp1[j,])#dlambda1&gp1[j]
			-(zfn4[i,]-zfn3[i]#zbar&gp2[j,])#dlambda1&gp2[j];
	    end;
    
	    htz[i,]=htemp;
	end;	
   
	cif_diff_v=j(numtime,1,0);
	cif_diff_se=j(numtime,1,0);
	w1temp=j(numobs,1,0);
	w2temp=j(numobs,1,0);
    
	do i=1 to numtime;
	    w1=j(numobs,1,0);
	    w2=j(numobs,1,0);
	    w3=j(numobs,1,0);
	    w4=j(numobs,1,0);
    
	    do j=1 to numobs;			
		if s0&gp1[i]^=0 & group[j]=&gp1 then w1temp[j]=w1temp[j]+1/s0&gp1[i]#dmart1[j,i];
		if s0&gp2[i]^=0 & group[j]=&gp2 then w2temp[j]=w2temp[j]+1/s0&gp2[i]#dmart1[j,i];
    
		w1[j]=w1temp[j]#zfn1[i];
		w2[j]=w2temp[j]#zfn3[i];
		w3[j]=htz[i,]*naivev*t(eta[j,]+psi[j,]);			
		w4[j]=w4[j]+dcmart[j,]*(vut&gp1[,i]#zfn1[i]-vut&gp2[,i]#zfn3[i]);			

		tempw=w1[j]-w2[j]+w3[j]+w4[j];
		cif_diff_v[i]=cif_diff_v[i]+tempw#tempw;
	    end;
	end;

	cif_diff_se=cif_diff_v##0.5;

	outmat=outmat||cif_diff_se;
    %end;
%end;

    names={'Time' %do i=1 %to &numgroup; "CIF&i" "SE&i" %end;
		%do i=1 %to &numgroup; %do j=&i+1 %to &numgroup; "SE&i.&j" %end; %end;};

    create &outdata from outmat[colname=names];
    append from outmat;
    close &outdata;
run;
quit;

data name;
    time=0;
    
    %do i=1 %to &numgroup; 
        CIF&i=0; 
        SE&i=0;
        
        %do j=&i+1 %to &numgroup; SE&i.&j=0; %end; 
    %end;        
        
    output;
run;

data &outdata;
    set name &outdata;
    by time;
run;     
    
data name;
    %do i=1 %to &numcov;
    Variable="Z&i"; 
    output;
    %end;
run;

data best;
    merge name best;

    drop zstat;
    
    zstat=abs(Estimate/SE);
    Prob=2*probnorm(-zstat);
run;

data covest;
    merge name covest;
run;

title 'A stratified Cox model for a subdistribution function';
title2 'WORK.BEST: Estimates of the regression parameters';
proc print data=best; 
run;

title2 'WORK.COVEST: Estimated variance-covariance matrix';
proc print data=covest; 
run;

title2 'WORK.BASEHAZ: Estimated baseline cumulative hazard functions';
proc print data=basehaz; 
run;

title2 "&outdata: Direct adjusted cumulative incidence functions";
proc print data=&outdata; 
run;

%mend;
