/******************************************************************
                                                                   
This macro computes the direct adjusted cumulative incidence curves
for K treatment groups, based on a proportional subdistribution    
hazards model. Please note that the hazards ratio between any two  
treatments is assumed to be a constant.                            
                                                                   
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
                                                                   
******************************************************************/
%*imported/re-formatted/hardened 02/18/2014;
%*macro (inputdata, time, event, group, covlist, outdata);

%macro _cifcox(data=REQUIRED, out=REQUIRED, time=REQUIRED, 
    cause=REQUIRED, group=REQUIRED, x=REQUIRED,
    inputdata=&data, outdata=&out, covlist=&x, event=&cause);

%_require(&data &time &event &group &out &x)

%local i j gp gp1 gp2 numcov numgroup tcov tnum;

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

%let tcov=%eval(&numgroup-1+&numcov);

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

    names={'time' 'cause' %do i=1 %to &numgroup-1+&numcov; "z&i" %end;};
    create indata from out[colname=names];
    append from out;
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
    keep time atrisk;
    where cause=0;
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
    
    if first.time;
    
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

proc phreg data=indata out=best noprint;
    model time*cause(0,2)=%do i=1 %to &numgroup-1+&numcov; z&i %end;;
run;	

%let tnum=%eval(&tcov*(&tcov+1)/2);

data obs10 obs2;
    set indata;
    
    if cause in (0,1) then output obs10;
    else output obs2;
run;

proc iml;
    use obs10;
    read all var{time} into time10;
    read all var{cause} into cause10;
    read all var{%do i=1 %to &numgroup-1+&numcov; z&i %end;} into z10;
    read all var{%do i=&numgroup %to &numgroup-1+&numcov; z&i %end;} into zzmat01;
    close obs10;

    use obs2;
    read all var{time} into time2;
    read all var{csurv} into ckm2;
    read all var{cause} into cause2;
    read all var{%do i=1 %to &numgroup-1+&numcov; z&i %end;} into z2;
    read all var{%do i=&numgroup %to &numgroup-1+&numcov; z&i %end;} into zzmat2;
    close obs2;

    use best;
    read all var{%do i=1 %to &numgroup-1+&numcov; z&i %end;} into best;
    close best;

    use e1time;
    read all var{time} into etime;
    read all var{csurv} into eckm;
    close e1time;    

    use cdata;
    read all var{ctime} into ctime;
    read all var{dcna} into dcna;
    read all var{atrisk} into pi;
    close cdata;

    numctime=nrow(ctime);    
            
    numtime=nrow(etime);

    numobs10=nrow(time10);
    numobs2=nrow(time2);
 
    cidx=j(numctime,1,0);
    
    do i=1 to numctime;
	if ctime[i]>etime[numtime] then cidx[i]=-1;
    	else do;
	    do j=1 to numtime until(etime[j]>=ctime[i]);
	    end;
    
	    cidx[i]=j;
	end;
    end;

    eidx=j(numtime,1,0);
    
    do i=1 to numtime;    	
	do j=1 to numobs10 until(time10[j]=etime[i]);
	end;
    
	eidx[i]=j;
    end;
     
    b=best; 

    numdeath=j(numtime,1,0);
    covsum=j(numtime,&tcov,0);    
    
    do i=1 to numtime;            
        do j=1 to numobs10;
	    if time10[j]=etime[i] & cause10[j]=1 then do;
                numdeath[i] = numdeath[i] + 1;
                covsum[i,] = covsum[i,] + z10[j,];            
	    end;
	end;
    end;

    incre=1;

do iter=1 to 20 until(incre<.0005);    
    s0_1=j(numtime,1,0);
    s1_1=j(numtime,&tcov,0);
    s2_1=j(numtime,&tnum,0);

    score=j(1,&tcov,0);
    fisher=j(&tcov,&tcov,0);
    loglike=0;        

    expbz10=j(numobs10,1,0);
    
    do i=1 to numobs10;
	expbz10[i]=b*t(z10[i,]);
    end;
    
    expbz10=exp(expbz10);
    expbz2=j(numobs2,1,0);
    
    do i=1 to numobs2;
	expbz2[i]=b*t(z2[i,]);
    end;
    
    expbz2=exp(expbz2);    

    pres0=0;
    pres1=j(1,&tcov,0);
    pres2=j(1,&tnum,0);
    obsidx=numobs10;
    
    do i=numtime to 1 by -1;
	s0_1[i]=pres0;
	s1_1[i,]=pres1;
	s2_1[i,]=pres2;
    
	do j=eidx[i] to obsidx;
            s0_1[i] = s0_1[i] + expbz10[j];
            s1_1[i,] = s1_1[i,] + z10[j,]#expbz10[j];
            tonext=1;
    
            do m=1 to &tcov;
                do n=m to &tcov;
                    s2_1[i,tonext] = s2_1[i,tonext] + z10[j,m]#z10[j,n]#expbz10[j];
                    tonext = tonext + 1;
                end;
            end;
	end;
    
	pres0=s0_1[i];
    	pres1=s1_1[i,];
	pres2=s2_1[i,];
	obsidx=eidx[i]-1;
    end;

    s0_2=j(numtime,1,0);
    s1_2=j(numtime,&tcov,0);
    s2_2=j(numtime,&tnum,0);
    
    do i=1 to numtime;
	do j=1 to numobs2;
	    cweight=eckm[i]/ckm2[j];
	    weight=min(1,cweight);
            s0_2[i] = s0_2[i] + expbz2[j]#weight;
            s1_2[i,] = s1_2[i,] + z2[j,]#expbz2[j]#weight;
            tonext=1;
    
            do m=1 to &tcov;
                do n=m to &tcov;
                    s2_2[i,tonext] = s2_2[i,tonext] + z2[j,m]#z2[j,n]#expbz2[j]#weight;
                    tonext = tonext + 1;
                end;
            end;
	end;
    end;

    s0=s0_1+s0_2;
    s1=s1_1+s1_2;
    s2=s2_1+s2_2;

    do i=1 to numtime;
        score = score + covsum[i,] - s1[i,]#(numdeath[i]/s0[i]);

        tonext=1;
    
        do m=1 to &tcov;
            do n=m to &tcov;
                fisher[m,n] = fisher[m,n] + s2[i,tonext]#(numdeath[i]/s0[i])
                    - s1[i,m]#s1[i,n]#(numdeath[i]/s0[i]##2);
                tonext = tonext + 1;
            end;
        end;
	
        loglike = loglike + b*t(covsum[i,])-numdeath[i]*log(s0[i]); 
    end;       

	do m=2 to &tcov;
	    do n=1 to m-1;
		fisher[m,n]=fisher[n,m];
	    end;
	end;  

	oldb=b;
        b = b + score*inv(fisher);
    
	bchange=b-oldb;
        incre=max(abs(bchange));
end;

    do i=1 to numobs10;
	expbz10[i]=b*t(z10[i,]);
    end;
        
    expbz10=exp(expbz10);
        
    do i=1 to numobs2;
	expbz2[i]=b*t(z2[i,]);
    end;
        
    expbz2=exp(expbz2);

    lambda1=j(numtime,1,0);    
    dlambda1=j(numtime,1,0);
    ltemp=0;
        
    do i=1 to numtime;
        dlambda1[i]=numdeath[i]/s0[i];
        ltemp=ltemp+dlambda1[i];
        lambda1[i]=ltemp;
    end;
    
    eta_1=j(numobs10,&tcov,0);
    dmart1_1=j(numobs10,numtime,0);
        
    do i=1 to numobs10;
        do j=1 to numtime;
            if time10[i]>=etime[j] then dmart1_1[i,j]=-dlambda1[j]#expbz10[i];
            if cause10[i]=1 & time10[i]=etime[j] then dmart1_1[i,j]=dmart1_1[i,j]+1;
        
            eta_1[i,] = eta_1[i,] + (z10[i,]-s1[j,]/s0[j])*dmart1_1[i,j];
 	end;
    end;

    eta_2=j(numobs2,&tcov,0);
    dmart1_2=j(numobs2,numtime,0);
        
    do i=1 to numobs2;
        do j=1 to numtime;
	    cweight=eckm[j]/ckm2[i];
	    weight=min(1,cweight);
            dmart1_2[i,j]=-dlambda1[j]#expbz2[i]#weight;
            eta_2[i,] = eta_2[i,] + (z2[i,]-s1[j,]/s0[j])*dmart1_2[i,j];
        end;
    end;
    
    numobs=numobs10+numobs2;
    dmart1=dmart1_1//dmart1_2;
    time=time10//time2;
    cause=cause10//cause2;
    zmat=z10//z2;
    eta=eta_1//eta_2;

    psi=j(numobs,&tcov,0);

    q=j(numctime,&tcov,0);
        
    do i=1 to numctime while (cidx[i]>0);
	do j=1 to numobs2 while (ctime[i]>time2[j]);
	    do k=cidx[i] to numtime;
                q[i,]=q[i,]+(z2[j,]-s1[k,]/s0[k])#dmart1_2[j,k];
	    end;
	end;
        
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

    sigma=j(&tcov,&tcov,0);
        
    do i=1 to numobs;
        sigma = sigma + t(eta[i,]+psi[i,])*(eta[i,]+psi[i,]);
    end;
            
    naivev = inv(fisher);
            
    robustv = inv(fisher)*sigma*inv(fisher);

	se=j(&tcov,1,0);
        
	do i=1 to &tcov;
		se[i]=sqrt(robustv[i,i]);
	end;
    
	bout=t(b)||se;
	hazout=etime||lambda1;

	create best from bout[colname={'Estimate' 'SE'}];
	append from bout;
	close best; 

	names={%do i=2 %to &numgroup; "G&i" %end; %do i=1 %to &numcov; "Z&i" %end;};
	create covest from robustv[colname=names];
	append from robustv;
	close covest;

	create basehaz from hazout[colname={'Time' 'Base_haz'}];
	append from hazout;
	close basehaz; 

	vut=j(numctime, numtime,0);
        
	do i=1 to numctime while (cidx[i]>0);
	    vtemp=0;
        
	    do j=cidx[i] to numtime;
		do k=1 to numobs2;
		    if time2[k]<ctime[i] then vtemp=vtemp+1/s0[j]#dmart1_2[k,j];
		end;
        
		vut[i,j]=-vtemp;
	    end;
	    vut[i,]=vut[i,]/pi[i];
	end;

/*	variance of direct adjusted CIF  */

    g=j(&numgroup, &numgroup-1,0);
    do i=2 to &numgroup;
        g[i,i-1]=1;
    end;

    outmat=etime;

    zzmat=zzmat01//zzmat2;

    zbar=j(numtime,&tcov,0);
        
    do i=1 to numtime;
	zbar[i,]=s1[i,]/s0[i];
    end;
       
%do gp=1 %to &numgroup;    
    zz=j(numobs, &numgroup-1+&numcov, 0);
        
    do 	i=1 to numobs;
	zz[i,]=g[&gp,]||zzmat[i,];
    end;

    dacif=j(numtime,1,0);
    zfn1=j(numtime,1,0);
    zfn2=j(numtime,&numgroup-1+&numcov,0);
        
    do i=1 to numtime;
	do j=1 to numobs;
	    dacif[i]=dacif[i]+1-exp(-lambda1[i]#exp(b*t(zz[j,])));
	    zfn1[i]=zfn1[i]+exp(-lambda1[i]#exp(b*t(zz[j,]))+b*t(zz[j,]));
	    zfn2[i,]=zfn2[i,]+zz[j,]#exp(-lambda1[i]#exp(b*t(zz[j,]))+b*t(zz[j,]));
	end;
    end;
        
    dacif=dacif/numobs;
    zfn1=zfn1/numobs;
    zfn2=zfn2/numobs;

    htz=j(numtime,&tcov,0);
        
    do i=1 to numtime;
	htemp=j(1,&tcov,0);
        
	do j=1 to i;
	    htemp=htemp+(zfn2[i,]-zfn1[i]#zbar[j,])#dlambda1[j];
 	end;
        
	htz[i,]=htemp;
    end;

    cifv=j(numtime,1,0);
    cifse=j(numtime,1,0);
    w1temp=j(numobs,1,0);

    do i=1 to numtime;
	w1=j(numobs,1,0);
	w2=j(numobs,1,0);
	w3=j(numobs,1,0);
        
	do j=1 to numobs;
	    w1temp[j]=w1temp[j]+1/s0[i]#dmart1[j,i];
	    w1[j]=w1temp[j]#zfn1[i];
	    w2[j]=htz[i,]*naivev*t(eta[j,]+psi[j,]);
	    w3[j]=w3[j]+dcmart[j,]*vut[,i]#zfn1[i];

	    tempw=w1[j]+w2[j]+w3[j];
	    cifv[i]=cifv[i]+tempw#tempw;
	end;
    end;

    cifse=cifv##0.5;

    outmat=outmat||dacif||cifse;
%end;

/* 	variance of the difference between direct adjusted CIF's  */

%do gp1=1 %to &numgroup-1;
    %do gp2=&gp1+1 %to &numgroup;

    zz1=j(numobs, &numgroup-1+&numcov, 0);
    zz2=j(numobs, &numgroup-1+&numcov, 0);
        
    do i=1 to numobs;
	zz1[i,]=g[&gp1,]||zzmat[i,];
	zz2[i,]=g[&gp2,]||zzmat[i,];
    end;

    zfn1=j(numtime,1,0);
    zfn2=j(numtime,&numgroup-1+&numcov,0);
        
    do i=1 to numtime;
	do j=1 to numobs;
	    zfn1[i]=zfn1[i]+exp(-lambda1[i]#exp(b*t(zz1[j,]))+b*t(zz1[j,]))
		-exp(-lambda1[i]#exp(b*t(zz2[j,]))+b*t(zz2[j,]));
	    zfn2[i,]=zfn2[i,]+zz1[j,]#exp(-lambda1[i]#exp(b*t(zz1[j,]))+b*t(zz1[j,]))
		-zz2[j,]#exp(-lambda1[i]#exp(b*t(zz2[j,]))+b*t(zz2[j,]));
	end;
    end;
        
    zfn1=zfn1/numobs;
    zfn2=zfn2/numobs;

    htz=j(numtime,&tcov,0);
        
    do i=1 to numtime;
	htemp=j(1,&tcov,0);
        
	do j=1 to i;
	    htemp=htemp+(zfn2[i,]-zfn1[i]#zbar[j,])#dlambda1[j];
	end;
        
	htz[i,]=htemp;
    end;	
   
    cif_diff_v=j(numtime,1,0);
    cif_diff_se=j(numtime,1,0);
    w1temp=j(numobs,1,0);
        
    do i=1 to numtime;
	w1=j(numobs,1,0);
	w2=j(numobs,1,0);
	w3=j(numobs,1,0);
        
	do j=1 to numobs;
	    w1temp[j]=w1temp[j]+1/s0[i]#dmart1[j,i];
	    w1[j]=w1temp[j]#zfn1[i];
	    w2[j]=htz[i,]*naivev*t(eta[j,]+psi[j,]);
	    w3[j]=w3[j]+dcmart[j,]*vut[,i]#zfn1[i];
	    tempw=w1[j]+w2[j]+w3[j];
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
    %do i=2 %to &numgroup;
    Variable="G&i"; 
    output;
    %end;
    
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

title 'Cox model for a subdistribution function';
title2 'WORK.BEST: Estimates of the regression parameters';
proc print data=best; 
run;

title2 'WORK.COVEST: Estimated variance-covariance matrix';
proc print data=covest; 
run;

title2 'WORK.BASEHAZ: Estimated baseline cumulative hazard function';
proc print data=basehaz; 
run;

title2 "&outdata: Direct adjusted cumulative incidence functions";
proc print data=&outdata; 
run;

%mend;
