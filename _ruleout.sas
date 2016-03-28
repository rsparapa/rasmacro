/* 

Example of how we will handle comorbidity which require confirmation.

Most insurance works on a calendar year basis: coverage starts in
Jan. and ends in Dec.  We usually will be considering cohorts of
patients who are covered for the whole year (including those who are
covered from the beginning of the year until death).

Klabunde, Cooper and others define a rule-out diagnosis as a
physician's diagnosis that is used for a brief time for testing for a
particular diagnosis which, if unconfirmed by diagnostic testing,
never appears again.  For example, when giving bone mineral density
tests, the most common physician's diagnosis is osteoporosis even
though the result of most of the tests reveal that the patient does
not have osteoporosis.  

Rule-out diagnoses, needless to say, don't count.  But, how do we
define a real diagnosis then?  Klabunde requires a second diagnosis
by the end of the year and at least 30 days after the first diagnosis,
i.e. between 31 and 365 days.  And that will be our definition.

For comorbidity purposes, we will want to keep track of the first date
a particular diagnosis occurs over all of the years that the patient
is followed.  Depending on the timing, these diagnoses are
comorbidities (occurring before the fact) or they are new conditions
(occurring after the fact).  Here is a slightly simplified example
illustrating these definitions.  The purpose of this example is to
show some code that can easily be extended for a whole bunch of
diagnoses, years, etc.
 
N.B. This discussion is about physician's diagnosis which are 
notorious.  By contrast, hospital discharge diagnosis is generally
considered to be very accurate since Medicare considers the
diagnoses for reimbursement.  So, rule-out diagnoses are considered
to be only a problem with physician's diagnosis and not hospital
discharge diagnosis (hospital admission diagnosis are generally
not considered at all).
*/


%macro _ruleout(data=, out=, var=, date=, ignore=30, confirm=365);

%do year=2009 %to 2010;
proc univariate noprint data=&data;
    by id;
    var &date;
    where &var & "01JAN&year"d<=&date<="31DEC&year"d;
    *one diagnosis and one-year at a time;
    output out=_&var.&year min=&var.min&year;
run;
    
data _&var.conf&year;
    merge _&var.&year &data;
    by id;
    format &var.min&year mmddyy8.;
run;

proc univariate noprint data=_&var.conf&year;
    by id &var.min&year;
    var &date;
    where &var & "01JAN&year"d<=&var.min&year<="01DEC&year"d
        & (&var.min&year+&ignore)<=&date<=(&var.min&year+&confirm);
    output out=_&var.conf&year min=&var.conf&year;
run;

data _&var.&year;
    merge _&var.&year _&var.conf&year;
    by id;
    format &var.conf&year mmddyy8.;
    
    &var=n(&var.conf&year);
run;
   
%end;

data &out;
    merge %_list(_&var.2009-_&var.2010);
    by id;
run;

%mend _ruleout;

/* uncomment to test

data diag;
    length comment $ 40;
    input id date mmddyy8. dm chf copd comment;
    infile cards missover;
lines;
01 07012009 1 0 1 
01 11012010 1 1 0 
01 01302011 1 0 1 dm-confirmed
02 07012009 1 1 1 
02 04012010 1 0 1 
02 08302010 1 1 1 
03 07012009 0 1 0 
03 04012010 0 0 1 
03 08302010 0 0 0 
;
run;

%_sort(data=diag, out=diag, by=id date);

data cohort;
    set diag;
    by id;
    keep id;
    
    if first.id;
run;

%_ruleout(data=diag, out=dm, var=DM, date=date);
%_ruleout(data=diag, out=chf, var=chf, date=date);
%_ruleout(data=diag, out=copd, var=copd, date=date);

data all;
    merge dm chf copd;
    by id;
run;

proc print;
run;
    
*/
