%put NOTE: You have called the macro _SUMMARY, 2025/12/30;
%put NOTE: Copyright (c) 2001-2025 Rodney Sparapani;
%put;

/*
Author:  Rodney Sparapani <rsparapa@mcw.edu>
Created: 2001/00/00

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

/*  _SUMMARY Documentation
    
    The goal of the _SUMMARY macro is a straightforward, concise and
    flexible framework for the production of tables with descriptive
    statistics that are presentable to statisticians and
    non-statisticians alike.  The _SUMMARY macro took a long time to
    perfect, off and on development for many years.  It is now
    over 2000 lines, which is a big macro, but considering everything
    that it does, is surprisingly short.  That is due to the
    under-pinnings of the SAS macro environment, RASMACRO, which was
    developed to make _SUMMARY possible and is a nice side effect.
    RASMACRO has many useful purposes besides table generation, for
    example, exporting to and importing from other packages like
    BUGS/R/S/S+, Stata and Excel.
    
    The documentation of the _SUMMARY macro is a challenge;
    for example, none of the parameters are required and there
    are a daunting number of options.  It is assumed that the
    programmer who uses _SUMMARY knows what they are doing.  
    But, this contributes to its flexibility.  Furthermore,
    the "SAS way" of doing things is assumed; this should make
    many of the options self-explanatory and the resulting
    programs easier to read.  Note that variable names that
    conflict with the names of statistics produced by SAS
    will cause problems.  Other variable names to avoid:  COL#,
    COUNT, _NONMISS, _MISSING and _WEIGHT_.  Unfortunately, this 
    is not a trivial problem to prevent.  So, if you experience
    weirdness, immediately check your variable names which may
    save you alot of time and frustration.
            
    Specific OPTIONAL Parameters
        
    ALPHA=0.05      the default alpha for confidence intervals
       
    APPEND=         file to append the table to, defaults to no appending
                    TO-DO: smart handling of APPEND/FILE needs work
                    
    CLASS=_COLUMN   CLASS variable to be passed to PROC GLM for an ANOVA
                    or PROC NPAR1WAY for non-parametric ANOVA, a format can 
                    be specified as the optional second argument
                    defaults to _COLUMN (the automatically generated variable
                    representing the column based on COL#=; see below)
                    can be over-ridden by CLASS#=
                    
    COL#=           WHERE clauses specifying the corresponding columns,
                    for example:  COL1=TX=1
                    Note that COL2 is implicitly defined in this example
                    as NOT(TX=1).  Also a Total column is automatically
                    created by ORing all of the clauses together, i.e.
                    COL3=TX=1 | NOT(TX=1).  Up to 10 columns are supported
                    and column 0 is for the variable names.
                    
    COLORDER=       the order to display the columns, defaults to 
                    numeric order, for example:  COLORDER=2 1 3-5
                    
    COUNTFMT=       the default format for integer counts, calculated from
                    W= and D= so you should not have to specify it
                    
    D=1             the default decimal places for each numeric field
                    most of the code assumes that D GE 1
    
    DATA=_LAST_     the SAS DATASET to be used for input, defaults to _LAST_
                    
    DEBUG=          set to asterisk to have descriptive statistics results
                    captured in listing (see FILE= below)
      
    FILE=           the file to create for the table; all of the output 
                    necessary to produce the inferential statistics will be 
                    found in the listing (see DEBUG= above); defaults to the 
                    root of the program name followed by .txt if OUT= unset

    FILEHTML=       the HTML file to create for the table; similar to FILE=
                    
    FILETEX=        the LaTeX file to create for the table; similar to FILE=

    FILEPDF=        the PDF file to create from the LaTeX table; similar to FILE=
                    
    FORMAT=BEST7.   the default format to be used for the qualitative summary
                    of each variable, can be over-ridden by FORMAT#=
    
    FREQ=           the default option to pass the PROC FREQ TABLES statement
                    most commonly used to make missing into a category with 
                    FREQ=MISSING or to set the SCORES option, i.e.
                    FREQ=SCORES=TABLE
    
    HEAD#=          the headings for the columns; HEAD0 refers to
                    the column of variable names; by default the 
                    Total column is set to Total (see COL# above)
                    
    ID=             when STAT=MIN_MAX is specified, an identifier variable and 
                    the format to display it that corresponds to the min and max,
                    can be over-ridden by ID#=
                    for example, VAR1=dbp, STAT1=MIN_MAX, ID1=nid z11.
                    
    INDENT=0        the number of characters to offset the labels in
                    the first column heading, defaults to 0
    
    LABEL=MIXEDCASE for variables that do not have a SAS DATASET label,
                    construct a label by upper casing the first letter
                    of the variable name and lower casing the rest;
                    other possible values are MIXED, 
                    LOWER|LOWCASE|LOWERCASE for all lower case or
                    UPPER|UPCASE|UPPERCASE for all upper case
                    NAMEONLY for all upper case and over-ride the
                        SAS DATASET variable label with the 
                        SAS DATASET variable name
                    NAMEPLUS for all upper case and prepend the
                        SAS DATASET variable label with the 
                        SAS DATASET variable name
                        
    LABEL#=         labels for each variable, over-rides the SAS DATASET
                    variable label
                    
    LABELLEN=MAX    default length for creation of SAS DATASET variable labels
                    over-ridden by the length of LABEL#=

    LATEX=0         over-ride with 1 to create a table encoded in LaTeX
                    
    LENGTH=W+2      the default length of character variables to contain
                    numeric fields
                    
    MAX=99          the number of variables that are explicitly supported
                    in a table, more are implicitly supported in a VAR= list,
                    however, you will not be able to over-ride defaults,
                    e.g. you can only specify the default STAT=, but not
                    STAT#=, etc.
                    
    MEANS=          the default option to pass the PROC MEANS statement
                    most commonly used to make missing
                    into a category with MEANS=MISSING, but cannot be
                    used with the ORDER= option; can be over-ridden
                    with MEANS#=
                    
    MODEL=          the default model variables to be added to the
                    PROC GLM MODEL statement for ANCOVA or multi-way
                    ANOVA, can be over-ridden with MODEL#=
                    
    MISSING=Missing the default label for the missing category, can be
                    over-ridden with MISS#=
    
    MU0=0           default for PROC UNIVARIATE tests of location,
                    can be over-ridden by MU0#=
                    
    OFFSET=2        the number of characters to offset the values under 
                    the column heading, defaults to 2
                    
    ORDER=          the default order to present the variables 
                    can be over-ridden with ORDER#=
                    can also be used to make missing into a category 
                    for example:  ORDER=.\1\2\3
                    more convenient than the alternative which would
                    require setting both FREQ=MISSING and MEANS=MISSING                    
                    beware that ORDER# occurs after WHERE#, but before
                    COL# which can produce surprising results if VAR#
                    is also part of the COL# clause
                    no re-orderings are allowed for the supported AGREE 
                    statistics (KAPPA and MCNEM) since the actual 
                    ordering is important
                    otherwise, when FORMAT#=yesno., then ORDER# 
                    defaults to Yes\No automatically
                    
    OUT=            the output SAS DATASET to created, defaults to a temporary
                    SAS DATASET
                    
    OUTPCT=         specify counts with row percents only by ROW or NOCOL, or 
                    with column percents only by COL or NOROW
                    
    PFMT=           the format for p-values when it cannot be calculated from
                    W= and D=
                    
    ROUND=0         the default rounding option as passed to 
                    PROC UNIVARIATE 
                    
    SORT=
    
    SORTSEQ=
    
    SPLIT=\         the split character as used by LABEL#=, HEAD#= and ORDER#=
                    options, defaults to \
                    
    STAT=COUNTPCT   the default statistics to calculate for each variable,
                    you can over-ride it with STAT#=, a format can be 
                    specified following a statistic to over-ride the default 
                    format; by default, counts, row and column percents 
                    are produced (for counts with row percents only or with
                    column percents only, see OUTPCT); other specifications 
                    follow:
                    
                    EXACT2 for the two-sided Fisher's Exact Test only
                    SS1-SS4 for ANOVA F statistics from PROC GLM representing
                    the type of sums of squares, see the MODEL= option
                    MW for the Mann-Whitney statistic from PROC NPAR1WAY
                    KW for the Kruskal-Wallis statistic with PROC NPAR1WAY 

                    some statistics can be combined on one line as follows
                    (of course, if you only want one of them per line, you can
                    specify them alone, i.e. without the underscore):
                    MEAN_SD|MEAN_STD for the mean and standard deviation
                    MIN_MAX for the min and max
                    Q1_Q3 for Q1 and Q3
                    and the following %-iles (and their complements, i.e. 
                    subtracted from 100) can be specified by P followed
                    by the number with the decimal place replaced by an
                    underscore: 0.1, 0.5, 1, 2, 2.5, 3, 4, 5, 10, 15, 20, 
                    25, 30, 33.3, 35, 40, 45, 50
                    for example: P33_3_P66_7 for the 33.3th and 66.7th %-ile

                    almost any PROC FREQ or PROC UNIVARIATE statistic can be
                    produced (see the documentation for those PROCs for
                    the names of the statistics, but be warned that
                    occasionally the docs may be out-of-sync with the
                    actual names produced; inspecting the code that
                    follows might be of some help in this regard)
     
    STDFMT=         the format for standard deviations when it cannot be 
                    calculated from W= and D=
     
    TABLE=_COLUMN   the default stratification variable for the PROC FREQ
                    defaults to _COLUMN (the automatically generated variable
                    representing the column based on COL#=; see above)
                    over-ridden by TABLE#=, but then you must specify
                    STRATA*VAR rather than STRATA alone
     
    TOTAL=          the column to place overall statistics, defaults to
                    the overall column, see COL#= below
       
    TRIM#=          one-tailed or two-tailed trimming by specifying
                    one or two numeric values regarded as percentiles
                    cutoffs are based on the TOTAL column
                    
    VAR=            can be used for a list of variables, for example:
                    VAR=dbp1-dbp5; most likely you will use VAR#= instead
       
    VARDEF=DF       the default variance definition options as passed to 
                    PROC UNIVARIATE 
                    
    VARORDER=       the order to produce the VAR#=, leaving out variables skips
                    them, by default numeric order is followed, for example:
                    VARORDER=2 1 4-7
    
    W=8             the default width to make numeric fields
                                                
    WEIGHT=1        the weight of each observation, can be a variable or an 
                    expression, defaults to 1, can be over-ridden by WEIGHT#=

    WHERE#=         WHERE clauses that are only operating on an individual
                    VAR#=, for a global WHERE clause, see WHERE= below
                    
    WINSOR#=        one-tailed or two-tailed winsorizing by specifying
                    one or two numeric values regarded as percentiles
                    cutoffs are based on the TOTAL column
                    
    Common OPTIONAL Parameters
    
    ATTRIB=
    
    BY=             #BYVALn processing of BY variables embedded within 
                    title statements is simulated; avoid macro punctuation
                    such as ampersand, comma, equals, etc.; supply an optional
                    format via the ATTRIB= parameter; a bug in SAS v. 8
                    will force out blank pages so SAS v. 9 is required for this
                    feature to work correctly; remember that SAS v. 8 and v. 9
                    format libraries are not cross-compatible
    
    DROP=
    
    FIRSTOBS=
    
    IF=
    
    KEEP=
    
    LOG=
    
    OBS=
    
    RENAME=
    
    WHERE=                    
                    
    RASMACRO Dependencies
    _ABEND
    _BLIST, _BY
    _CJ, _COUNT
    _FIRST, _FN, _FOOT
    _INDEXC, _INDEXW
    _LEVEL, _LIST, _LJ, _LS
    _MAX, _MIN
    _NULL
    _PRINTTO, _PS
    _REORDER, _REPEAT, _RETAIN
    _SCRATCH, _SCRUB, _SORT, _SUBSTR
    _TAIL, _TITLE, _TR, _TRANSPO
    _VERSION 
*/

%macro _summary(data=&syslast, debug=, out=, split=\, offset=2, format=best7.,
    missing=Missing, varorder=, order=, max=99, w=8, d=1, length=%eval(&w+3),
    countfmt=%eval(&w-&d-1).0, pctfmt=pctfmt&w.., pfmt=&length..4,
    stat=countpct, stdfmt=&w..&d, table=_column, total=0, alpha=0.05,
    freq=, means=, outpct=, indent=0, label=mixedcase, labellen=max,
    pctldef=5, round=0, vardef=df, id=, var=, class=_column, weight=1,
    mu0=0, model=, append=, colorder=, 
    file=, filehtml=, filetex=, filepdf=, latex=0,
    col0=, col1=1, col2=((&col1)=0), col3=, col4=, 
    col5=, col6=, col7=, col8=, col9=, col10=, 
    head0=, head1=, head2=, head3=, head4=, 
    head5=, head6=, head7=, head8=, head9=, head10=, 

    var1=, order1=&order, stat1=&stat, label1=&label, format1=&format, where1=,
        table1=&table*&var1,  indent1=&indent,  miss1=&missing,class1=&class, 
        means1=&means,  trim1=,  winsor1=,  id1=&id,  weight1=&weight, mu01=&mu0,
        model1=&model,  freq1=&freq,
    var2=, order2=&order, stat2=&stat, label2=&label, format2=&format, where2=,
        table2=&table*&var2,  indent2=&indent,  miss2=&missing,class2=&class, 
        means2=&means,  trim2=,  winsor2=,  id2=&id,  weight2=&weight, mu02=&mu0,
        model2=&model,  freq2=&freq,
    var3=, order3=&order, stat3=&stat, label3=&label, format3=&format, where3=,
        table3=&table*&var3,  indent3=&indent,  miss3=&missing,class3=&class, 
        means3=&means,  trim3=,  winsor3=,  id3=&id,  weight3=&weight, mu03=&mu0,
        model3=&model,  freq3=&freq,
    var4=, order4=&order, stat4=&stat, label4=&label, format4=&format, where4=,
        table4=&table*&var4,  indent4=&indent,  miss4=&missing,class4=&class, 
        means4=&means,  trim4=,  winsor4=,  id4=&id,  weight4=&weight, mu04=&mu0,
        model4=&model,  freq4=&freq,
    var5=, order5=&order, stat5=&stat, label5=&label, format5=&format, where5=,
        table5=&table*&var5,  indent5=&indent,  miss5=&missing,class5=&class, 
        means5=&means,  trim5=,  winsor5=,  id5=&id,  weight5=&weight, mu05=&mu0,
        model5=&model,  freq5=&freq,
    var6=, order6=&order, stat6=&stat, label6=&label, format6=&format, where6=,
        table6=&table*&var6,  indent6=&indent,  miss6=&missing,class6=&class, 
        means6=&means,  trim6=,  winsor6=,  id6=&id,  weight6=&weight, mu06=&mu0,
        model6=&model,  freq6=&freq,
    var7=, order7=&order, stat7=&stat, label7=&label, format7=&format, where7=,
        table7=&table*&var7,  indent7=&indent,  miss7=&missing,class7=&class, 
        means7=&means,  trim7=,  winsor7=,  id7=&id,  weight7=&weight, mu07=&mu0,
        model7=&model,  freq7=&freq,
    var8=, order8=&order, stat8=&stat, label8=&label, format8=&format, where8=,
        table8=&table*&var8,  indent8=&indent,  miss8=&missing,class8=&class, 
        means8=&means,  trim8=,  winsor8=,  id8=&id,  weight8=&weight, mu08=&mu0,
        model8=&model,  freq8=&freq,
    var9=, order9=&order, stat9=&stat, label9=&label, format9=&format, where9=,
        table9=&table*&var9,  indent9=&indent,  miss9=&missing,class9=&class, 
        means9=&means,  trim9=,  winsor9=,  id9=&id,  weight9=&weight, mu09=&mu0,
        model9=&model,  freq9=&freq,
    var10=,order10=&order,stat10=&stat,label10=&label,format10=&format,where10=,
        table10=&table*&var10,indent10=&indent,miss10=&missing,class10=&class, 
        means10=&means, trim10=, winsor10=, id10=&id, weight10=&weight,mu010=&mu0,
        model10=&model, freq10=&freq,
    var11=,order11=&order,stat11=&stat,label11=&label,format11=&format,where11=,
        table11=&table*&var11,indent11=&indent,miss11=&missing,class11=&class, 
        means11=&means, trim11=, winsor11=, id11=&id, weight11=&weight,mu011=&mu0,
        model11=&model, freq11=&freq,
    var12=,order12=&order,stat12=&stat,label12=&label,format12=&format,where12=,
        table12=&table*&var12,indent12=&indent,miss12=&missing,class12=&class, 
        means12=&means, trim12=, winsor12=, id12=&id, weight12=&weight,mu012=&mu0,
        model12=&model, freq12=&freq,
    var13=,order13=&order,stat13=&stat,label13=&label,format13=&format,where13=,
        table13=&table*&var13,indent13=&indent,miss13=&missing,class13=&class,  
        means13=&means, trim13=, winsor13=, id13=&id, weight13=&weight,mu013=&mu0,
        model13=&model, freq13=&freq,
    var14=,order14=&order,stat14=&stat,label14=&label,format14=&format,where14=,
        table14=&table*&var14,indent14=&indent,miss14=&missing,class14=&class, 
        means14=&means, trim14=, winsor14=, id14=&id, weight14=&weight,mu014=&mu0,
        model14=&model, freq14=&freq,
    var15=,order15=&order,stat15=&stat,label15=&label,format15=&format,where15=,
        table15=&table*&var15,indent15=&indent,miss15=&missing,class15=&class,
        means15=&means, trim15=, winsor15=, id15=&id, weight15=&weight,mu015=&mu0,
        model15=&model, freq15=&freq,
    var16=,order16=&order,stat16=&stat,label16=&label,format16=&format,where16=,
        table16=&table*&var16,indent16=&indent,miss16=&missing,class16=&class, 
        means16=&means, trim16=, winsor16=, id16=&id, weight16=&weight,mu016=&mu0,
        model16=&model, freq16=&freq,
    var17=,order17=&order,stat17=&stat,label17=&label,format17=&format,where17=,
        table17=&table*&var17,indent17=&indent,miss17=&missing,class17=&class, 
        means17=&means, trim17=, winsor17=, id17=&id, weight17=&weight,mu017=&mu0,
        model17=&model, freq17=&freq,
    var18=,order18=&order,stat18=&stat,label18=&label,format18=&format,where18=,
        table18=&table*&var18,indent18=&indent,miss18=&missing,class18=&class, 
        means18=&means, trim18=, winsor18=, id18=&id, weight18=&weight,mu018=&mu0,
        model18=&model, freq18=&freq,
    var19=,order19=&order,stat19=&stat,label19=&label,format19=&format,where19=,
        table19=&table*&var19,indent19=&indent,miss19=&missing,class19=&class, 
        means19=&means, trim19=, winsor19=, id19=&id, weight19=&weight,mu019=&mu0,
        model19=&model, freq19=&freq,
    var20=,order20=&order,stat20=&stat,label20=&label,format20=&format,where20=,
        table20=&table*&var20,indent20=&indent,miss20=&missing,class20=&class, 
        means20=&means, trim20=, winsor20=, id20=&id, weight20=&weight,mu020=&mu0,
        model20=&model, freq20=&freq,
    var21=,order21=&order,stat21=&stat,label21=&label,format21=&format,where21=,
        table21=&table*&var21,indent21=&indent,miss21=&missing,class21=&class, 
        means21=&means, trim21=, winsor21=, id21=&id, weight21=&weight,mu021=&mu0,
        model21=&model, freq21=&freq,
    var22=,order22=&order,stat22=&stat,label22=&label,format22=&format,where22=,
        table22=&table*&var22,indent22=&indent,miss22=&missing,class22=&class, 
        means22=&means, trim22=, winsor22=, id22=&id, weight22=&weight,mu022=&mu0,
        model22=&model, freq22=&freq,
    var23=,order23=&order,stat23=&stat,label23=&label,format23=&format,where23=,
        table23=&table*&var23,indent23=&indent,miss23=&missing,class23=&class, 
        means23=&means, trim23=, winsor23=, id23=&id, weight23=&weight,mu023=&mu0,
        model23=&model, freq23=&freq,
    var24=,order24=&order,stat24=&stat,label24=&label,format24=&format,where24=,
        table24=&table*&var24,indent24=&indent,miss24=&missing,class24=&class,
        means24=&means, trim24=, winsor24=, id24=&id, weight24=&weight,mu024=&mu0,
        model24=&model, freq24=&freq,
    var25=,order25=&order,stat25=&stat,label25=&label,format25=&format,where25=,
        table25=&table*&var25,indent25=&indent,miss25=&missing,class25=&class,
        means25=&means, trim25=, winsor25=, id25=&id, weight25=&weight,mu025=&mu0,
        model25=&model, freq25=&freq,
    var26=,order26=&order,stat26=&stat,label26=&label,format26=&format,where26=,
        table26=&table*&var26,indent26=&indent,miss26=&missing,class26=&class,
        means26=&means, trim26=, winsor26=, id26=&id, weight26=&weight,mu026=&mu0,
        model26=&model, freq26=&freq,
    var27=,order27=&order,stat27=&stat,label27=&label,format27=&format,where27=,
        table27=&table*&var27,indent27=&indent,miss27=&missing,class27=&class,
        means27=&means, trim27=, winsor27=, id27=&id, weight27=&weight,mu027=&mu0,
        model27=&model, freq27=&freq,
    var28=,order28=&order,stat28=&stat,label28=&label,format28=&format,where28=,
        table28=&table*&var28,indent28=&indent,miss28=&missing,class28=&class,
        means28=&means, trim28=, winsor28=, id28=&id, weight28=&weight,mu028=&mu0,
        model28=&model, freq28=&freq,
    var29=,order29=&order,stat29=&stat,label29=&label,format29=&format,where29=,
        table29=&table*&var29,indent29=&indent,miss29=&missing,class29=&class,
        means29=&means, trim29=, winsor29=, id29=&id, weight29=&weight,mu029=&mu0,
        model29=&model, freq29=&freq,
    var30=,order30=&order,stat30=&stat,label30=&label,format30=&format,where30=,
        table30=&table*&var30,indent30=&indent,miss30=&missing,class30=&class, 
        means30=&means, trim30=, winsor30=, id30=&id, weight30=&weight,mu030=&mu0,
        model30=&model, freq30=&freq,
    var31=,order31=&order,stat31=&stat,label31=&label,format31=&format,where31=,
        table31=&table*&var31,indent31=&indent,miss31=&missing,class31=&class, 
        means31=&means, trim31=, winsor31=, id31=&id, weight31=&weight,mu031=&mu0,
        model31=&model, freq31=&freq,
    var32=,order32=&order,stat32=&stat,label32=&label,format32=&format,where32=,
        table32=&table*&var32,indent32=&indent,miss32=&missing,class32=&class, 
        means32=&means, trim32=, winsor32=, id32=&id, weight32=&weight,mu032=&mu0,
        model32=&model, freq32=&freq,
    var33=,order33=&order,stat33=&stat,label33=&label,format33=&format,where33=,
        table33=&table*&var33,indent33=&indent,miss33=&missing,class33=&class, 
        means33=&means, trim33=, winsor33=, id33=&id, weight33=&weight,mu033=&mu0,
        model33=&model, freq33=&freq,
    var34=,order34=&order,stat34=&stat,label34=&label,format34=&format,where34=,
        table34=&table*&var34,indent34=&indent,miss34=&missing,class34=&class, 
        means34=&means, trim34=, winsor34=, id34=&id, weight34=&weight,mu034=&mu0,
        model34=&model, freq34=&freq,
    var35=,order35=&order,stat35=&stat,label35=&label,format35=&format,where35=,
        table35=&table*&var35,indent35=&indent,miss35=&missing,class35=&class, 
        means35=&means, trim35=, winsor35=, id35=&id, weight35=&weight,mu035=&mu0,
        model35=&model, freq35=&freq,
    var36=,order36=&order,stat36=&stat,label36=&label,format36=&format,where36=,
        table36=&table*&var36,indent36=&indent,miss36=&missing,class36=&class, 
        means36=&means, trim36=, winsor36=, id36=&id, weight36=&weight,mu036=&mu0,
        model36=&model, freq36=&freq,
    var37=,order37=&order,stat37=&stat,label37=&label,format37=&format,where37=,
        table37=&table*&var37,indent37=&indent,miss37=&missing,class37=&class, 
        means37=&means, trim37=, winsor37=, id37=&id, weight37=&weight,mu037=&mu0,
        model37=&model, freq37=&freq,
    var38=,order38=&order,stat38=&stat,label38=&label,format38=&format,where38=,
        table38=&table*&var38,indent38=&indent,miss38=&missing,class38=&class, 
        means38=&means, trim38=, winsor38=, id38=&id, weight38=&weight,mu038=&mu0,
        model38=&model, freq38=&freq,
    var39=,order39=&order,stat39=&stat,label39=&label,format39=&format,where39=,
        table39=&table*&var39,indent39=&indent,miss39=&missing,class39=&class, 
        means39=&means, trim39=, winsor39=, id39=&id, weight39=&weight,mu039=&mu0,
        model39=&model, freq39=&freq,
    var40=,order40=&order,stat40=&stat,label40=&label,format40=&format,where40=,
        table40=&table*&var40,indent40=&indent,miss40=&missing,class40=&class,  
        means40=&means, trim40=, winsor40=, id40=&id, weight40=&weight,mu040=&mu0,
        model40=&model, freq40=&freq,
    var41=,order41=&order,stat41=&stat,label41=&label,format41=&format,where41=,
        table41=&table*&var41,indent41=&indent,miss41=&missing,class41=&class, 
        means41=&means, trim41=, winsor41=, id41=&id, weight41=&weight,mu041=&mu0,
        model41=&model, freq41=&freq,
    var42=,order42=&order,stat42=&stat,label42=&label,format42=&format,where42=,
        table42=&table*&var42,indent42=&indent,miss42=&missing,class42=&class, 
        means42=&means, trim42=, winsor42=, id42=&id, weight42=&weight,mu042=&mu0,
        model42=&model, freq42=&freq,
    var43=,order43=&order,stat43=&stat,label43=&label,format43=&format,where43=,
        table43=&table*&var43,indent43=&indent,miss43=&missing,class43=&class, 
        means43=&means, trim43=, winsor43=, id43=&id, weight43=&weight,mu043=&mu0,
        model43=&model, freq43=&freq,
    var44=,order44=&order,stat44=&stat,label44=&label,format44=&format,where44=,
        table44=&table*&var44,indent44=&indent,miss44=&missing,class44=&class, 
        means44=&means, trim44=, winsor44=, id44=&id, weight44=&weight,mu044=&mu0,
        model44=&model, freq44=&freq,
    var45=,order45=&order,stat45=&stat,label45=&label,format45=&format,where45=,
        table45=&table*&var45,indent45=&indent,miss45=&missing,class45=&class, 
        means45=&means, trim45=, winsor45=, id45=&id, weight45=&weight,mu045=&mu0,
        model45=&model, freq45=&freq,
    var46=,order46=&order,stat46=&stat,label46=&label,format46=&format,where46=,
        table46=&table*&var46,indent46=&indent,miss46=&missing,class46=&class, 
        means46=&means, trim46=, winsor46=, id46=&id, weight46=&weight,mu046=&mu0,
        model46=&model, freq46=&freq,
    var47=,order47=&order,stat47=&stat,label47=&label,format47=&format,where47=,
        table47=&table*&var47,indent47=&indent,miss47=&missing,class47=&class, 
        means47=&means, trim47=, winsor47=, id47=&id, weight47=&weight,mu047=&mu0,
        model47=&model, freq47=&freq,
    var48=,order48=&order,stat48=&stat,label48=&label,format48=&format,where48=,
        table48=&table*&var48,indent48=&indent,miss48=&missing,class48=&class, 
        means48=&means, trim48=, winsor48=, id48=&id, weight48=&weight,mu048=&mu0,
        model48=&model, freq48=&freq,
    var49=,order49=&order,stat49=&stat,label49=&label,format49=&format,where49=,
        table49=&table*&var49,indent49=&indent,miss49=&missing,class49=&class, 
        means49=&means, trim49=, winsor49=, id49=&id, weight49=&weight,mu049=&mu0,
        model49=&model, freq49=&freq,
    var50=,order50=&order,stat50=&stat,label50=&label,format50=&format,where50=,
        table50=&table*&var50,indent50=&indent,miss50=&missing,class50=&class, 
        means50=&means, trim50=, winsor50=, id50=&id, weight50=&weight,mu050=&mu0,
        model50=&model, freq50=&freq,
    var51=,order51=&order,stat51=&stat,label51=&label,format51=&format,where51=,
        table51=&table*&var51,indent51=&indent,miss51=&missing,class51=&class, 
        means51=&means, trim51=, winsor51=, id51=&id, weight51=&weight,mu051=&mu0,
        model51=&model, freq51=&freq,
    var52=,order52=&order,stat52=&stat,label52=&label,format52=&format,where52=,
        table52=&table*&var52,indent52=&indent,miss52=&missing,class52=&class, 
        means52=&means, trim52=, winsor52=, id52=&id, weight52=&weight,mu052=&mu0,
        model52=&model, freq52=&freq,
    var53=,order53=&order,stat53=&stat,label53=&label,format53=&format,where53=,
        table53=&table*&var53,indent53=&indent,miss53=&missing,class53=&class, 
        means53=&means, trim53=, winsor53=, id53=&id, weight53=&weight,mu053=&mu0,
        model53=&model, freq53=&freq,
    var54=,order54=&order,stat54=&stat,label54=&label,format54=&format,where54=,
        table54=&table*&var54,indent54=&indent,miss54=&missing,class54=&class, 
        means54=&means, trim54=, winsor54=, id54=&id, weight54=&weight,mu054=&mu0,
        model54=&model, freq54=&freq,
    var55=,order55=&order,stat55=&stat,label55=&label,format55=&format,where55=,
        table55=&table*&var55,indent55=&indent,miss55=&missing,class55=&class, 
        means55=&means, trim55=, winsor55=, id55=&id, weight55=&weight,mu055=&mu0,
        model55=&model, freq55=&freq,
    var56=,order56=&order,stat56=&stat,label56=&label,format56=&format,where56=,
        table56=&table*&var56,indent56=&indent,miss56=&missing,class56=&class, 
        means56=&means, trim56=, winsor56=, id56=&id, weight56=&weight,mu056=&mu0,
        model56=&model, freq56=&freq,
    var57=,order57=&order,stat57=&stat,label57=&label,format57=&format,where57=,
        table57=&table*&var57,indent57=&indent,miss57=&missing,class57=&class, 
        means57=&means, trim57=, winsor57=, id57=&id, weight57=&weight,mu057=&mu0,
        model57=&model, freq57=&freq,
    var58=,order58=&order,stat58=&stat,label58=&label,format58=&format,where58=,
        table58=&table*&var58,indent58=&indent,miss58=&missing,class58=&class, 
        means58=&means, trim58=, winsor58=, id58=&id, weight58=&weight,mu058=&mu0,
        model58=&model, freq58=&freq,
    var59=,order59=&order,stat59=&stat,label59=&label,format59=&format,where59=,
        table59=&table*&var59,indent59=&indent,miss59=&missing,class59=&class, 
        means59=&means, trim59=, winsor59=, id59=&id, weight59=&weight,mu059=&mu0,
        model59=&model, freq59=&freq,
    var60=,order60=&order,stat60=&stat,label60=&label,format60=&format,where60=,
        table60=&table*&var60,indent60=&indent,miss60=&missing,class60=&class, 
        means60=&means, trim60=, winsor60=, id60=&id, weight60=&weight,mu060=&mu0,
        model60=&model, freq60=&freq,
    var61=,order61=&order,stat61=&stat,label61=&label,format61=&format,where61=,
        table61=&table*&var61,indent61=&indent,miss61=&missing,class61=&class,  
        means61=&means, trim61=, winsor61=, id61=&id, weight61=&weight,mu061=&mu0,
        model61=&model, freq61=&freq,
    var62=,order62=&order,stat62=&stat,label62=&label,format62=&format,where62=,
        table62=&table*&var62,indent62=&indent,miss62=&missing,class62=&class,  
        means62=&means, trim62=, winsor62=, id62=&id, weight62=&weight,mu062=&mu0,
        model62=&model, freq62=&freq,
    var63=,order63=&order,stat63=&stat,label63=&label,format63=&format,where63=,
        table63=&table*&var63,indent63=&indent,miss63=&missing,class63=&class,  
        means63=&means, trim63=, winsor63=, id63=&id, weight63=&weight,mu063=&mu0,
        model63=&model, freq63=&freq,
    var64=,order64=&order,stat64=&stat,label64=&label,format64=&format,where64=,
        table64=&table*&var64,indent64=&indent,miss64=&missing,class64=&class,  
        means64=&means, trim64=, winsor64=, id64=&id, weight64=&weight,mu064=&mu0,
        model64=&model, freq64=&freq,
    var65=,order65=&order,stat65=&stat,label65=&label,format65=&format,where65=,
        table65=&table*&var65,indent65=&indent,miss65=&missing,class65=&class,  
        means65=&means, trim65=, winsor65=, id65=&id, weight65=&weight,mu065=&mu0,
        model65=&model, freq65=&freq,
    var66=,order66=&order,stat66=&stat,label66=&label,format66=&format,where66=,
        table66=&table*&var66,indent66=&indent,miss66=&missing,class66=&class,  
        means66=&means, trim66=, winsor66=, id66=&id, weight66=&weight,mu066=&mu0,
        model66=&model, freq66=&freq,
    var67=,order67=&order,stat67=&stat,label67=&label,format67=&format,where67=,
        table67=&table*&var67,indent67=&indent,miss67=&missing,class67=&class,  
        means67=&means, trim67=, winsor67=, id67=&id, weight67=&weight,mu067=&mu0,
        model67=&model, freq67=&freq,
    var68=,order68=&order,stat68=&stat,label68=&label,format68=&format,where68=,
        table68=&table*&var68,indent68=&indent,miss68=&missing,class68=&class,  
        means68=&means, trim68=, winsor68=, id68=&id, weight68=&weight,mu068=&mu0,
        model68=&model, freq68=&freq,
    var69=,order69=&order,stat69=&stat,label69=&label,format69=&format,where69=,
        table69=&table*&var69,indent69=&indent,miss69=&missing,class69=&class,  
        means69=&means, trim69=, winsor69=, id69=&id, weight69=&weight,mu069=&mu0,
        model69=&model, freq69=&freq,
    var70=,order70=&order,stat70=&stat,label70=&label,format70=&format,where70=,
        table70=&table*&var70,indent70=&indent,miss70=&missing,class70=&class, 
        means70=&means, trim70=, winsor70=, id70=&id, weight70=&weight,mu070=&mu0,
        model70=&model, freq70=&freq,
    var71=,order71=&order,stat71=&stat,label71=&label,format71=&format,where71=,
        table71=&table*&var71,indent71=&indent,miss71=&missing,class71=&class, 
        means71=&means, trim71=, winsor71=, id71=&id, weight71=&weight,mu071=&mu0,
        model71=&model, freq71=&freq,
    var72=,order72=&order,stat72=&stat,label72=&label,format72=&format,where72=,
        table72=&table*&var72,indent72=&indent,miss72=&missing,class72=&class, 
        means72=&means, trim72=, winsor72=, id72=&id, weight72=&weight,mu072=&mu0,
        model72=&model, freq72=&freq,
    var73=,order73=&order,stat73=&stat,label73=&label,format73=&format,where73=,
        table73=&table*&var73,indent73=&indent,miss73=&missing,class73=&class, 
        means73=&means, trim73=, winsor73=, id73=&id, weight73=&weight,mu073=&mu0,
        model73=&model, freq73=&freq,
    var74=,order74=&order,stat74=&stat,label74=&label,format74=&format,where74=,
        table74=&table*&var74,indent74=&indent,miss74=&missing,class74=&class, 
        means74=&means, trim74=, winsor74=, id74=&id, weight74=&weight,mu074=&mu0,
        model74=&model, freq74=&freq,
    var75=,order75=&order,stat75=&stat,label75=&label,format75=&format,where75=,
        table75=&table*&var75,indent75=&indent,miss75=&missing,class75=&class, 
        means75=&means, trim75=, winsor75=, id75=&id, weight75=&weight,mu075=&mu0,
        model75=&model, freq75=&freq,
    var76=,order76=&order,stat76=&stat,label76=&label,format76=&format,where76=,
        table76=&table*&var76,indent76=&indent,miss76=&missing,class76=&class, 
        means76=&means, trim76=, winsor76=, id76=&id, weight76=&weight,mu076=&mu0,
        model76=&model, freq76=&freq,
    var77=,order77=&order,stat77=&stat,label77=&label,format77=&format,where77=,
        table77=&table*&var77,indent77=&indent,miss77=&missing,class77=&class, 
        means77=&means, trim77=, winsor77=, id77=&id, weight77=&weight,mu077=&mu0,
        model77=&model, freq77=&freq,
    var78=,order78=&order,stat78=&stat,label78=&label,format78=&format,where78=,
        table78=&table*&var78,indent78=&indent,miss78=&missing,class78=&class, 
        means78=&means, trim78=, winsor78=, id78=&id, weight78=&weight,mu078=&mu0,
        model78=&model, freq78=&freq,
    var79=,order79=&order,stat79=&stat,label79=&label,format79=&format,where79=,
        table79=&table*&var79,indent79=&indent,miss79=&missing,class79=&class, 
        means79=&means, trim79=, winsor79=, id79=&id, weight79=&weight,mu079=&mu0,
        model79=&model, freq79=&freq,
    var80=,order80=&order,stat80=&stat,label80=&label,format80=&format,where80=,
        table80=&table*&var80,indent80=&indent,miss80=&missing,class80=&class, 
        means80=&means, trim80=, winsor80=, id80=&id, weight80=&weight,mu080=&mu0,
        model80=&model, freq80=&freq,
    var81=,order81=&order,stat81=&stat,label81=&label,format81=&format,where81=,
        table81=&table*&var81,indent81=&indent,miss81=&missing,class81=&class, 
        means81=&means, trim81=, winsor81=, id81=&id, weight81=&weight,mu081=&mu0,
        model81=&model, freq81=&freq,
    var82=,order82=&order,stat82=&stat,label82=&label,format82=&format,where82=,
        table82=&table*&var82,indent82=&indent,miss82=&missing,class82=&class, 
        means82=&means, trim82=, winsor82=, id82=&id, weight82=&weight,mu082=&mu0,
        model82=&model, freq82=&freq,
    var83=,order83=&order,stat83=&stat,label83=&label,format83=&format,where83=,
        table83=&table*&var83,indent83=&indent,miss83=&missing,class83=&class, 
        means83=&means, trim83=, winsor83=, id83=&id, weight83=&weight,mu083=&mu0,
        model83=&model, freq83=&freq,
    var84=,order84=&order,stat84=&stat,label84=&label,format84=&format,where84=,
        table84=&table*&var84,indent84=&indent,miss84=&missing,class84=&class, 
        means84=&means, trim84=, winsor84=, id84=&id, weight84=&weight,mu084=&mu0,
        model84=&model, freq84=&freq,
    var85=,order85=&order,stat85=&stat,label85=&label,format85=&format,where85=,
        table85=&table*&var85,indent85=&indent,miss85=&missing,class85=&class, 
        means85=&means, trim85=, winsor85=, id85=&id, weight85=&weight,mu085=&mu0,
        model85=&model, freq85=&freq,
    var86=,order86=&order,stat86=&stat,label86=&label,format86=&format,where86=,
        table86=&table*&var86,indent86=&indent,miss86=&missing,class86=&class, 
        means86=&means, trim86=, winsor86=, id86=&id, weight86=&weight,mu086=&mu0,
        model86=&model, freq86=&freq,
    var87=,order87=&order,stat87=&stat,label87=&label,format87=&format,where87=,
        table87=&table*&var87,indent87=&indent,miss87=&missing,class87=&class, 
        means87=&means, trim87=, winsor87=, id87=&id, weight87=&weight,mu087=&mu0,
        model87=&model, freq87=&freq,
    var88=,order88=&order,stat88=&stat,label88=&label,format88=&format,where88=,
        table88=&table*&var88,indent88=&indent,miss88=&missing,class88=&class, 
        means88=&means, trim88=, winsor88=, id88=&id, weight88=&weight,mu088=&mu0,
        model88=&model, freq88=&freq,
    var89=,order89=&order,stat89=&stat,label89=&label,format89=&format,where89=,
        table89=&table*&var89,indent89=&indent,miss89=&missing,class89=&class, 
        means89=&means, trim89=, winsor89=, id89=&id, weight89=&weight,mu089=&mu0,
        model89=&model, freq89=&freq,
    var90=,order90=&order,stat90=&stat,label90=&label,format90=&format,where90=,
        table90=&table*&var90,indent90=&indent,miss90=&missing,class90=&class, 
        means90=&means, trim90=, winsor90=, id90=&id, weight90=&weight,mu090=&mu0,
        model90=&model, freq90=&freq,
    var91=,order91=&order,stat91=&stat,label91=&label,format91=&format,where91=,
        table91=&table*&var91,indent91=&indent,miss91=&missing,class91=&class, 
        means91=&means, trim91=, winsor91=, id91=&id, weight91=&weight,mu091=&mu0,
        model91=&model, freq91=&freq,
    var92=,order92=&order,stat92=&stat,label92=&label,format92=&format,where92=,
        table92=&table*&var92,indent92=&indent,miss92=&missing,class92=&class, 
        means92=&means, trim92=, winsor92=, id92=&id, weight92=&weight,mu092=&mu0,
        model92=&model, freq92=&freq,
    var93=,order93=&order,stat93=&stat,label93=&label,format93=&format,where93=,
        table93=&table*&var93,indent93=&indent,miss93=&missing,class93=&class, 
        means93=&means, trim93=, winsor93=, id93=&id, weight93=&weight,mu093=&mu0,
        model93=&model, freq93=&freq,
    var94=,order94=&order,stat94=&stat,label94=&label,format94=&format,where94=,
        table94=&table*&var94,indent94=&indent,miss94=&missing,class94=&class, 
        means94=&means, trim94=, winsor94=, id94=&id, weight94=&weight,mu094=&mu0,
        model94=&model, freq94=&freq,
    var95=,order95=&order,stat95=&stat,label95=&label,format95=&format,where95=,
        table95=&table*&var95,indent95=&indent,miss95=&missing,class95=&class, 
        means95=&means, trim95=, winsor95=, id95=&id, weight95=&weight,mu095=&mu0,
        model95=&model, freq95=&freq,
    var96=,order96=&order,stat96=&stat,label96=&label,format96=&format,where96=,
        table96=&table*&var96,indent96=&indent,miss96=&missing,class96=&class, 
        means96=&means, trim96=, winsor96=, id96=&id, weight96=&weight,mu096=&mu0,
        model96=&model, freq96=&freq,
    var97=,order97=&order,stat97=&stat,label97=&label,format97=&format,where97=,
        table97=&table*&var97,indent97=&indent,miss97=&missing,class97=&class, 
        means97=&means, trim97=, winsor97=, id97=&id, weight97=&weight,mu097=&mu0,
        model97=&model, freq97=&freq,
    var98=,order98=&order,stat98=&stat,label98=&label,format98=&format,where98=,
        table98=&table*&var98,indent98=&indent,miss98=&missing,class98=&class, 
        means98=&means, trim98=, winsor98=, id98=&id, weight98=&weight,mu098=&mu0,
        model98=&model, freq98=&freq,
    var99=,order99=&order,stat99=&stat,label99=&label,format99=&format,where99=,
        table99=&table*&var99,indent99=&indent,miss99=&missing,class99=&class, 
        means99=&means, trim99=, winsor99=, id99=&id, weight99=&weight,mu099=&mu0,
        model99=&model, freq99=&freq,
                
    attrib=, by=, drop=, firstobs=, if=, keep=, obs=, rename=, sort=, sortseq=, 
    where=, log=
);

%if %length(&log) %then %_printto(log=&log);
    
%local h i j k var0 _stat_ univstat univout univfmt freqstat freqout freqfmt
    len count index fmt fmtcount _ col11 comma arg0 arg1 arg2 arg3 temp 
    varnum pctlout scratch glmstat glmout glmfmt glmclass freqdata glmdata 
    kwdata kwout kwfmt options _index_ dsid varlabel;

%_foot;
%_title;

%*convert alpha into a confidence interval;
%let _=%eval(100-%_tr(&alpha, from=., to=0));

%*COL0:  the number of columns to be generated;
%let col0=1;

%if "&col1"^="1" %then %do j=1 %to 10;
    %if %length(&&col&j) %then %let col0=%eval(&col0+1);
%end;

proc format;
    %*produce format to be used with the PCT_COL, PCT_ROW, COUNTCOL and COUNTROW statistics.;
    picture pctfmt (round)
        0-100="0999.9%)" (prefix='(')
    ;

    value $best;
    
    value yesno
        0='No'
        1='Yes'
    ;
        
    %*produce format for the _STAT_ variable;
    value $_stat_
	'COUNT'		='Frequency'
	'PCT_COL'	='Col Pct'
	'PCT_ROW'	='Row Pct'
	'_MISSING'	="&MISSING "
	'MEAN'		='Mean'
	'MEAN_SD'	='Mean(SD)'
	'MEAN_STD'	='Mean(Std Dev)'
	'MEAN_95CI'	='95% CI'
	'MEDIAN'	='Median'
	'MEDIAN_IQR'	='Median(IQR)'
	'MEDIAN_R'	='Median(R)'
	'MIN'		='Minimum'
	'MAX'		='Maximum'
	'MIN_MAX'	='Min, Max'
	'MINID'		='MinID'
	'MAXID'		='MaxID'
	'MINMAXID'	='ID'
	'Q1'		='1st Quartile'
	'Q3'		='3rd Quartile'
	'Q1_Q3'		='Q1, Q3'
	'IQR1_5'	='1.5*IQR'
	'IQR3'  	='3*IQR'
        /*'_NONMISS'      ='N'*/
	'STD'		='Std Dev'
	'STDMEAN'	='Std Dev of Mean'
	'SUM'		='Sum'
	'VAR'		='Variance'
	'SKEWNESS'	='Skewness'
	'KURTOSIS'	='Kurtosis'
	'SUMWGT'	='Sum of Weights'
	'P0_5_P99'	='0.5th, 99.5th'
	'P1_P99'	='1st, 99th'
	'P2_5_P97'	='2.5th, 97.5th'
        'P33_3_P6'      ='33.3th, 66.7th'
	'P5_P95'	='5th, 95th'
	'P10_P90'	='10th, 90th'
	'P15_P85'	='15th, 85th'
	'P25_P75'	='25th, 75th'
	'P0_1'		='0.1st %ile'
	'P0_5'		='0.5th %ile'
	'P1'		='1st %ile'
	'P2'		='2nd %ile'
	'P2_5'		='2.5th %ile'
	'P3'		='3rd %ile'
	'P4'		='4th %ile'
	'P5'		='5th %ile'
	'P10'		='10th %ile'
	'P15'		='15th %ile'
	'P20'		='20th %ile'
	'P25'		='25th %ile'
	'P30'		='30th %ile'
	'P33'		='33th %ile'
	'P33_3'		='33.3th %ile'
	'P35'		='35th %ile'
	'P40'		='40th %ile'
	'P45'		='45th %ile'
	'P50'		='50th %ile'
	'P55'		='55th %ile'
	'P60'		='60th %ile'
	'P65'		='65th %ile'
	'P66_7'		='66.7th %ile'
	'P67'		='67th %ile'
	'P70'		='70th %ile'
	'P75'		='75th %ile'
	'P80'		='80th %ile'
	'P85'		='85th %ile'
	'P90'		='90th %ile'
	'P95'		='95th %ile'
	'P96'		='96th %ile'
	'P97'		='97th %ile'
	'P97_5'		='97.5th %ile'
	'P98'		='98th %ile'
	'P99'		='99th %ile'
	'P99_5'		='99.5th %ile'
	'P99_9'		='99.9th %ile'
	'MODE'		='Mode'
	'T', 'T_PROBT'  ="Student's t"
	'PROBT'		="Student's t pvalue"
	'MSIGN', 'MS_PROBM'='Sign Test'
	'PROBM'		='Sign Test pvalue'
	'SIGNRANK', 'S_PROBS'='Signed Rank'
        '_KW_'          ='Kruskal-Wallis'    
        'KAPPA_SD'      ='Simple Kappa'
        'KAPPA_CI'      ='Simple Kappa CI'
        'MCNEM_P'       ="McNemar's Test"
        '_MW_','P_MW','MW_P_MW'='Mann-Whitney'    
	'PROBS'		='Signed Rank pvalue'
	'SW', 'SW_PROBN'='Shapiro-Wilk'
	'PROBSW'	='Shapiro-Wilk pvalue'
	'NL', 'NL_PROBN'='Lilliefors'
	'PROBNL'        ='Lilliefors pvalue'
	'XPL_FISH'	="Fisher's Exact(L)"
	'XPR_FISH'	="Fisher's Exact(R)"
	'XP2_FISH'	="Fisher's Exact"   
	'P_A'-<'P_MW','P_MW____'-'P_Z_____'='p-value'
	'DF_A'-'DF_Z____'='DF'
        'NDF_DDF'       ='ANOVA DF'
        'NDF'           ='ANOVA Num DF'
        'DDF'           ='ANOVA Den DF'
        'F', 'F_PROBF'  ='ANOVA F'
        'PROBF'         ='ANOVA pvalue'
        '_F_PROBF'      ='ANCOVA F'
        '_NDF_DDF'      ='ANCOVA DF'
	'E_A'-'E_Z_____'='ASE'
	'L_A'-'L_Z_____'="Lower Bound &_.% CI"
	'U_A'-'U_Z_____'="Upper Bound &_.% CI"
	'_AJCHI_'	='Cont-adj Chisq'
	'_BDCHI_'	='Breslow-Day Test'
	'_CMHCOR_'	='CMH Corr'
	'_CMHGA_'	='CMH Assoc'
	'_CMHRMS_'	='CMH RMS'
	'_CONTGY_'	='Contingency Coeff'
	'_CRAMV_'	="Cramer's V"
	'_GAMMA_', 'GAMMASD'	='Gamma'
	'_KENTB_', 'KENTBSD'	="Kendall's Tau-b"
	'_LAMDAS_', 'LAMDASSD'	='Lambda Symm'
	'_LAMRC_', 'LAMRCSD'	='Lambda Asymm R|C'
	'_LAMCR_', 'LAMCRSD'	='Lambda Asymm C|R'
	'_PCORR_', 'PCORRSD'	='Pearson Corr'
	'_SCORR_', 'SCORRSD'	='Spearman Corr'
	'_SMDCR_', 'SMDCRSD'	="Somer's D C|R"
	'_SMDRC_', 'SMDRCSD'	="Somer's D R|C"
	'_STUTC_', 'STUTCSD'	="Stuart's Tau-c"
	'_UCR_', 'UCRSD'	='Uncer Coeff C|R'
	'_URC_', 'URCSD'	='Uncer Coeff R|C'
	'_UNCERS_', 'UNCERSSD', '_U_', 'USD'	='Uncer Coeff Symm'
	'_LGOR_'	='Logit OR'
	'LGORCI'	="Logit OR &_.% CI"
	'_LGRRC1_'	='Logit RR1'
	'LGRRC1CI'	="Logit RR1 &_.% CI"
	'_LGRRC2_'	='Logit RR2'
	'LGRRC2CI'	="Logit RR2 &_.% CI"
	'_LRCHI_'	='LR Chisq'
	'_MHCHI_'	='MH Chisq'
	'_MHOR_'	='MH Adj OR'
	'MHORCI'	="MH Adj OR &_.% CI"
	'_MHRRC1_'	='MH Adj RR1'
	'MHRRC1CI'	="MH Adj RR1 &_.% CI"
	'_MHRRC2_'	='MH Adj RR2'
	'MHRRC2CI'	="MH Adj RR2 &_.% CI"
	'_RRC1_'	='RR'
	'RRC1CI'	="RR &_.% CI"
	'_RRC2_'	='RR'
	'RRC2CI'	="RR &_.% CI"
	'_RROR_'	='OR'
	'RRORCI'	="OR &_.% CI"
	'_PCHI_'	='Pearson Chisq'
	'_PHI_'		='Phi Coeff'
	'_PLCORR_'	='Polychoric Corr'
    ;
    
    value _column
    %do j=1 %to &col0-1;
    &j="&&col&j"
/*
        %let i=%_count(=&&col&j, split=""=);
        &j=%do h=1 %to &i; "%scan(=&&col&j, &h, ""=)" %end;
*/
    %end;
        &col0="Total"
    ;
run;

%*By default, present p-values and totals in the last column;
%if &total=0 | %length(&total)=0 %then %let total=&col0;

/* no longer needed; see creation of _COLUMN below
%*COL&COL0:  OR all the column where clauses together;
%if %length(&&col&col0)=0 %then %do j=1 %to &col0-1;
    %if &j>1 %then %let col&col0=&&col&col0 |;
    %let col&col0=&&col&col0 (&&col&j);
%end;

%if %length(&where) %then %let where=(&where) & (&&col&col0);
%else %let where=&&col&col0;
*/

%if %length(&out)=0 %then %do;
    %if %length(&file)=0 %then %do;
        %_fn;
        
        %let file=&fntext;   
        %if %length(&filehtml)=0 %then %let filehtml=&fnhtml;
        %if %length(&filetex)=0 %then %let filetex=&fntex;
        %if %length(&filepdf)=0 %then %let filepdf=&fnpdf;
        
        %if &foot0=0 | "&&foot&foot0"^="&fnpath" %then %do;
            %let foot0=%eval(&foot0+1);
            %let foot&foot0=&fnpath;

            footnote&foot0 %_lj(&&foot&foot0);
        %end;
    %end;

    %if %length(&filehtml)=0 %then %do;
        %let j=%_indexc(&file,.);
        %if &j>1 %then %let filehtml=%_substr(&file, 1, &j-1).html;
        %else %let filehtml=&file..html;
    %end;

    %let out=%_scratch(data=work);
%end;
%else %if &foot0=0 %then %do;
    %_fn;

    %let foot0=%eval(&foot0+1);
    %let foot&foot0=&fnpath;

    footnote&foot0 %_lj(&&foot&foot0);
%end;

%_sort(data=&data, out=&out, attrib=&attrib, by=&by, firstobs=&firstobs, drop=&drop, 
    if=&if, keep=&keep, obs=&obs, rename=&rename, sort=&sort, sortseq=&sortseq, where=&where);

*create _COLUMN variable;
data &out %if %length(&by) %then (sortedby=&by);;
    set &out;
    by &by;

    format _column _column.;
    
    select;
    %if "&col1"="1" %then %do;
        when(1) _column=1;
    %end;
    %else %do j=1 %to &col0-1;
        when(&&col&j) _column=&j;
    %end;
        otherwise delete;
    end;
run;
  
%if %length(&var) %then %do;
    %let var=%_blist(&var, data=&out, nofmt=1);
    %let max=%_count(&var);

    %do j=1 %to &max;
        %let var&j=%scan(&var, &j, %str( ));
/*
        %if %index(&&var&max,.)=0 %then %let max=%eval(&max+1);
        %else %if &max>99 %then %do;
            %local format&max;
            %let format&max=&&var&max;
        %end;
        %else %let format&max=&&var&max;
*/
        %if &j>99 %then %do;
            %local order&j stat&j label&j format&j where&j table&j indent&j miss&j 
                class&j means&j trim&j winsor&j id&j weight&j mu0&j model&j freq&j;
    
            %let order&j=&order;   %let stat&j=&stat;     %let label&j=&label;
            %let format&j=&format; %let where&j=;         %let table&j=&table*&&var&j;
            %let indent&j=&indent; %let miss&j=&missing;  %let class&j=&class;
            %let means&j=&means;   %let trim&j=;          %let winsor&j=;
            %let id&j=&id;         %let weight&j=&weight; %let mu0&j=&mu0;
            %let model&j=&model;   %let freq&j=&freq;
        %end;
    %end;
%end;
    
%let data=%sysfunc(open(&out));
%let var0=0;
%let labellen=%upcase(&labellen);
        
%*LEN:  get the maximum length of the labels for each variable.;
%if "&labellen"="MAX" %then %let len=40;
%else %let len=&labellen;

%*VAR0:  the number of variables that need to be summarized;
%if %length(&varorder) %then %do;
    %let varorder=%_list(&varorder);
    %let var0=%_count(&varorder);
%end;
%else %let var0=&max;

%*loop through the variables for pre-specified formats/labels/lengths;
%*and type conversion, if necessary;
%do h=1 %to &var0;
    %*if VARORDER is specified, that over-rides the numeric order;
    %if %length(&varorder) %then %let j=%scan(&varorder, &h, %str( ));
    %else %let j=&h;

    %local char&j;
    
    %if %length(&&var&j) %then %do;
        %if %length(&varorder)=0 %then %let max=&j;

        %let temp=%upcase(&&label&j);

        %if "&labellen"="MAX" %then %do;
            %if "&temp"="NAMEPLUS" %then %do;
                %if %length(&&label&j)>&len %then %let len=%length(&&var&j:&&label&j);
            %end;
            %else %if "&temp"^="MIXEDCASE" & "&temp"^="MIXED" &
                "&temp"^="LOWCASE" & "&temp"^="LOWERCASE" & "&temp"^="LOWER" &
                "&temp"^="UPCASE"  & "&temp"^="UPPERCASE" & "&temp"^="UPPER" &
                "&temp"^="NAMEONLY" %then %do;
        
                %if %length(&&label&j)>&len %then %let len=%length(&&label&j);
            %end;
        %end;

        %let varnum=%sysfunc(varnum(&data, &&var&j));

        %if &varnum=0 %then %do;
            %put ERROR: Variable not present, VAR=&&var&j;
            %let var&j=;
        %end;
        %else %if %sysfunc(vartype(&data, &varnum))=C %then %let char&j=$%sysfunc(varlen(&data, &varnum)).;
 	%else %if %length(&&format&j)=0 %then
            %let format&j=%scan(%sysfunc(varfmt(&data, &varnum)) best., 1, %str( ));
    %end;
                                    
    %if %length(&&id&j) & %index(&&id&j, $)=0 %then %do;
        %let varnum=%sysfunc(varnum(&data, &&id&j));
        
        %if %sysfunc(vartype(&data, &varnum))=C %then 
            %let id&j=%scan(&&id&j, 1, %str( )) $%sysfunc(varlen(&data, &varnum)).;
    %end;
%end;

%let var=%sysfunc(close(&data));
%let data=;
%let var0=%_min(&var0, &max);

%if &var0=0 %then %do;
    %put ERROR: You must specify at least one variable.;
    %_abend;
%end;

%*loop through the variables for reporting;
%do h=1 %to &var0;
    %*if VARORDER is specified, that over-rides the numeric order;
    %if %length(&varorder) %then %let i=%scan(&varorder, &h, %str( ));
    %else %let i=&h;

    %if %length(&&var&i) %then %do;
        %if %index(&&id&i, $) %then %do;
            %_reorder(data=&out, out=&out, by=&by, format=%scan(&&id&i, 2, %str( )), 
                var=%scan(&&id&i, 1, %str( )), split=&split);
            %let id&i=%upcase(%scan(&&id&i, 1, %str( )));
            
            %do j=1 %to &var0;
                %if %length(&varorder) %then %let k=%scan(&varorder, &j, %str( ));
                %else %let k=&j;
                
                %if "%scan(&&id&i, 1, %str( ))"="%upcase(%scan(&&id&k, 1, %str( )))" %then
                    %let id&k=%scan(&&id&i, 1, %str( )) %scan(&&id&i, 1, %str( ))_.; 
            %end;
        %end;

	%let var&i=%upcase(&&var&i);
	%let stat&i=%upcase(&&stat&i);
	%let means&i=%upcase(&&means&i);
	%let _stat_=;
	%let count=;
	%let comma=;

	%*univstat:  list of statistics PROC UNIVARIATE will compute; 
	%let univstat=;

	%*univout:  list of statistics PROC UNIVARIATE will compute formatted for OUTPUT statement; 
	%let univout=;

	%*univfmt:  list of formats for statistics computed by PROC UNIVARIATE;
	%let univfmt=;

	%*pctlout:  list of percentiles PROC UNIVARIATE will compute formatted for OUTPUT statement; 
	%let pctlout=;

	%*freqstat:  list of statistics PROC FREQ will compute; 
	%let freqstat=;

	%*freqcmh/freqoth:  split FREQSTAT into two lists due to a PROC FREQ bug;
	%let freqcmh=; %let freqoth=;
            
	%*freqout:  list of statistics PROC FREQ will compute formatted like the OUTPUT dataset; 
	%let freqout=;

	%*freqfmt:  list of formats for statistics computed by PROC FREQ;
	%let freqfmt=;

        %*freqdata:  name of temporary dataset created by PROC FREQ;
        %let freqdata=;
        
        %*glmstat:  type of sum of squares requested from PROC GLM;
        %let glmstat=;
        
        %*glmout:  list of statistics PROC GLM will compute formatted like a KEEP dataset option;
        %let glmout=;
        
	%*glmfmt:  list of formats for statistics computed by PROC GLM;
	%let glmfmt=;
        
        %*glmdata:  name of temporary dataset created by PROC GLM;
        %let glmdata=;
        
	%*glmclass:  PROC GLM CLASS statement;
	%let glmclass=;
                
        %*kwdata:  name of temporary dataset created by PROC NPAR1WAY;
        %let kwdata=;
        
        %*kwout:  Kruskil-Wallis statistics computed by PROC NPAR1WAY;
        %let kwout=;
            
        %*kwfmt:  Kruskal-Wallis statistics formats;
        %let kwfmt=;

        %*trimming;
        %let temp=%_count(&&trim&i);
                    
        %if &temp>0 %then %do;
            %let pctlout=&pctlout &&trim&i;
        
            %if &temp=1 %then %do;
                %let temp=P%_tr(&&trim&i, from=., to=_); 
                        
                %if %sysevalf(&&trim&i>50) %then %let trim&i=MIN-1 &temp;
                %else %let trim&i=&temp MAX+1;
            %end;
            %else %if &temp=2 %then %let trim&i=P%_tr(%scan(&&trim&i, 1, %str( )), from=., to=_) 
                P%_tr(%scan(&&trim&i, 2, %str( )), from=., to=_);
        %end;
                            
        %*Winsorizing;
        %let temp=%_count(&&winsor&i);
                    
        %if &temp>0 %then %do;
            %let pctlout=&pctlout &&winsor&i;
        
            %if &temp=1 %then %do;
                %let temp=P%_tr(&&winsor&i, from=., to=_); 
                            
                %if %sysevalf(&&winsor&i>50) %then %let winsor&i=MIN &temp;
                %else %let winsor&i=&temp MAX;
            %end;
            %else %if &temp=2 %then %let winsor&i=P%_tr(%scan(&&winsor&i, 1, %str( )), from=., to=_) 
                P%_tr(%scan(&&winsor&i, 2, %str( )), from=., to=_);
        %end;
                    
	%*if ALL, AGREE, CHISQ, CMH, CMH1, CMH2 or MEASURES, then expand statistics list;
	%let index=%index(&&stat&i, ALL);

	%if &index %then %do;
	    %let fmt=%scan(%_substr(&&stat&i, &index+3), 1, %str( ));
	    %if %index(&fmt, .)=0 %then %let fmt=;

	    %let stat&i=&&stat&i AGREE &fmt CHISQ &fmt MEASURES &fmt CMH &fmt ;
	%end;

	%let index=%index(&&stat&i, AGREE);

	%if &index %then %do;
	    %let fmt=%scan(%_substr(&&stat&i, &index+5), 1, %str( ));
	    %if %index(&fmt, .)=0 %then %let fmt=;

	    %let stat&i=&&stat&i /*COCHQ &fmt EQKAP &fmt EQWKP &fmt*/ KAPPA &fmt 
                MCNEM &fmt /*TSYMM &fmt WTKAP &fmt*/;
	%end;

	%let index=%index(&&stat&i, CHISQ);

	%if &index %then %do;
	    %let fmt=%scan(%_substr(&&stat&i, &index+5), 1, %str( ));
	    %if %index(&fmt, .)=0 %then %let fmt=;

	    %let stat&i=&&stat&i AJCHI &fmt CONTGY &fmt CRAMV &fmt 
	    	EXACT &fmt LRCHI &fmt MHCHI &fmt PCHI &fmt PHI &fmt;
	%end;

	%let index=%index(&&stat&i, MEASURES);

	%if &index %then %do;
	    %let fmt=%scan(%_substr(&&stat&i, &index+8), 1, %str( ));
	    %if %index(&fmt, .)=0 %then %let fmt=;

	    %let stat&i=&&stat&i GAMMA &fmt KENTB &fmt LAMCR &fmt 
	    	LAMDAS &fmt LAMRC &fmt PCORR &fmt RRC1 &fmt 
	    	RRC2 &fmt RROR &fmt SCORR &fmt SMDCR &fmt 
	    	SMDRC &fmt STUTC &fmt U &fmt UCR &fmt URC &fmt;
	%end;

	%let index=%index(&&stat&i, CMH);

	%if &index %then %do;
	    %let fmt=%scan(%_substr(&&stat&i, &index), 2, %str( ));
	    %if %index(&fmt, .)=0 %then %let fmt=;

	    %let index=%scan(%_substr(&&stat&i, &index), 1, %str( ));

	    %if "&index"="CMH" %then %do;
                %let stat&i=&&stat&i CMHGA &fmt;
                %let index=CMH2;
            %end;
            
	    %if "&index"="CMH2" %then %do;
                %let stat&i=&&stat&i CMHRMS &fmt;
                %let index=CMH1;
            %end;
            
	    %if "&index"="CMH1" %then %let stat&i=&&stat&i
	    	CMHCOR &fmt /*BDCHI &fmt*/ LGOR &fmt LGRRC1 &fmt 
	    	LGRRC2 &fmt MHOR &fmt MHRRC1 &fmt MHRRC2 &fmt;
	%end;

	%let index=%index(&&stat&i, MEAN_95CI);

	%if &index %then %do;
	    %let fmt=%scan(%_substr(&&stat&i, &index+8), 1, %str( ));
	    %if %index(&fmt, .)=0 %then %let fmt=;

	    %let stat&i=MEAN_SD &fmt &&stat&i;
	%end;
                        
	%*loop through the list of statistics that need to be computed and append to
            the appropriate macro variables;
	%do k=1 %to %_count(&&stat&i);
            %let _stat_=%scan(&&stat&i, &k, %str( ));

	    %if %index(&_stat_, .)=0 %then %do;
		%let fmt=%scan(&&stat&i, &k+1, %str( ));
		%if %index(&fmt, .)=0 %then %let fmt=;
		%if %length(&fmt)=0 %then %let fmt=&w..&d;
		
                %if %_indexc(%upcase(&fmt), ABCDEFGHIJKLMNOPQRSTUVWXYZ)=0 %then %do;
                    /*
                    %let temp=0%scan(&fmt, 2, .);

                    %if &temp<4 %then %do;
                        %let temp=%eval(4-&temp);
                        %let temp=&temp..&temp;
                        %let pfmt=%sysevalf(&fmt+&temp);
                    %end;
                    */
                    
                    %let stdfmt=&fmt; 
                %end;
                
                %if &_stat_=ALL | &_stat_=AGREE | &_stat_=CHISQ | &_stat_=CMH | 
                    &_stat_=CMH1 | &_stat_=CMH2 | &_stat_=MEASURES %then %let _stat_=;
                %else %if &_stat_=COUNT %then %let count=COUNT;
		%else %if &_stat_=COUNTCOL %then %let count=COL;
		%else %if &_stat_=COUNTROW %then %let count=ROW;
		%else %if &_stat_=COUNTPCT %then %let count=PCT;
		%else %if &_stat_=NROW %then %let count=NROW;
                %else %if &_stat_=SS1 | &_stat_=SS2 | &_stat_=SS3 | &_stat_=SS4 %then %do;
                    %if %length(&&model&i) %then %let comma=&comma NDF DDF _NDF_DDF F PROBF _F_PROBF;
                    %else %let comma=&comma NDF DDF NDF_DDF F PROBF F_PROBF;

                    %let glmstat=&_stat_;
                    %let glmout=F NDF DDF PROBF;
                    %let glmfmt=&fmt &countfmt &countfmt &pfmt;
                %end;
                %else %if &_stat_=EXACT %then %do;
                    %if %_version(8) %then %do;
                        %let freqout=&freqout XPL_FISH XPR_FISH XP2_FISH;
                        %let freqstat=&freqstat &_stat_;
                        %let freqfmt=&freqfmt &pfmt &pfmt &pfmt;
                    %end;
                    %else %do;
                        %let freqout=&freqout P_EXACTL P_EXACTR P_EXACT2;
                        %let freqstat=&freqstat &_stat_;
                        %let freqfmt=&freqfmt &pfmt &pfmt &pfmt;
                    %end;
                %end;
                %else %if &_stat_=EXACT2 %then %do;
                    %if %_version(8) %then %do;
                        %let freqout=&freqout XP2_FISH;
                        %let freqstat=&freqstat EXACT;
                        %let freqfmt=&freqfmt &pfmt;
                    %end;
                    %else %do;
                        %let freqout=&freqout P_EXACT2;
                        %let freqstat=&freqstat EXACT;
                        %let freqfmt=&freqfmt &pfmt;
                    %end;
                %end;
                %else %if &_stat_=AJCHI | &_stat_=CMHGA | &_stat_=LRCHI | &_stat_=MHCHI | 
                    &_stat_=PCHI %then %do;

                    %let freqout=&freqout _&_stat_._ DF_&_stat_ P_&_stat_;
                    %let freqstat=&freqstat &_stat_;
                    %let freqfmt=&freqfmt &fmt &countfmt &pfmt;
                %end; 
                %else %if &_stat_=KW | &_stat_=RANKSUM | &_stat_=WILCOXON | &_stat_=MW %then %do;
                    %let kwout=&kwout _KW_ DF_KW P_KW;
                    %let kwfmt=&kwfmt &fmt &countfmt &pfmt;
                %end; 
                %else %if &_stat_=CMHCOR %then %do;
                    %if %_version(8) %then %let freqout=&freqout _&_stat_._ DF_CMHCO P_&_stat_;
                    %else %let freqout=&freqout _&_stat_._ DF_CMHCR P_&_stat_;

                    %let freqstat=&freqstat &_stat_;
                    %let freqfmt=&freqfmt &fmt &countfmt &pfmt;
                %end;
                %else %if &_stat_=CMHRMS %then %do;
                    %let freqout=&freqout _&_stat_._ DF_CMHRM P_&_stat_;
                    %let freqstat=&freqstat &_stat_;
                    %let freqfmt=&freqfmt &fmt &countfmt &pfmt;
                %end;
                %else %if &_stat_=LGOR | &_stat_=LGRRC1 | &_stat_=LGRRC2 | &_stat_=MHOR | 
                    &_stat_=MHRRC1 | &_stat_=MHRRC2 | &_stat_=RRC1 | &_stat_=RRC2 | 
                    &_stat_=RROR %then %do;
                                    
                    %let comma=&comma L_&_stat_ U_&_stat_ &_stat_.CI; 
                    %let freqout=&freqout _&_stat_._ L_&_stat_ U_&_stat_;
                    %let freqstat=&freqstat &_stat_; 
                    %let freqfmt=&freqfmt &fmt &fmt &fmt;
                %end;
                %else %if &_stat_=GAMMA | &_stat_=KENTB | &_stat_=LAMCR | &_stat_=LAMDAS | 
                    &_stat_=LAMRC | &_stat_=PCORR | &_stat_=SCORR | &_stat_=SMDCR | 
                    &_stat_=SMDRC | &_stat_=STUTC | &_stat_=UCR | &_stat_=URC %then %do;

                    %let comma=&comma _&_stat_._ E_&_stat_ &_stat_.SD; 
                    %let freqout=&freqout _&_stat_._ E_&_stat_;
                    %let freqstat=&freqstat &_stat_;
                    %let freqfmt=&freqfmt &fmt &stdfmt;
                %end;
                %else %if &_stat_=U %then %do;
                    %if %_version(8) %then %do;
                        %let comma=&comma _&_stat_._ E_&_stat_ &_stat_.SD; 
                        %let freqout=&freqout _&_stat_._ E_&_stat_;
                        %let freqstat=&freqstat &_stat_;
                        %let freqfmt=&freqfmt &fmt &stdfmt;
                    %end;
                    %else %do;
                        %let comma=&comma _UNCERS_ E_UNCERS UNCERSSD; 
                        %let freqout=&freqout _UNCERS_ E_UNCERS;
                        %let freqstat=&freqstat &_stat_;
                        %let freqfmt=&freqfmt &fmt &stdfmt;
                    %end;
                %end;
                %else %if &_stat_=CONTGY | &_stat_=CRAMV | &_stat_=PHI | &_stat_=BDCHI %then %do;
                    %let freqout=&freqout _&_stat_._;
                    %let freqstat=&freqstat &_stat_;
                    %let freqfmt=&freqfmt &fmt;
                %end;
                %else %if &_stat_=KAPPA %then %do;
                    %let comma=&comma _&_stat_._ E_&_stat_ &_stat_._SD L_&_stat_ U_&_stat_ &_stat_._CI; 
                    %let freqout=&freqout _&_stat_._ E_&_stat_ L_&_stat_ U_&_stat_;
                    %let freqstat=&freqstat &_stat_;
                    %let freqfmt=&freqfmt &fmt &stdfmt &fmt &fmt;
                %end;
                %else %if &_stat_=MCNEM %then %do;
                    %let comma=&comma _&_stat_._ P_&_stat_ &_stat_._P; 
                    %let freqout=&freqout _&_stat_._ P_&_stat_;
                    %let freqstat=&freqstat &_stat_;
                    %let freqfmt=&freqfmt &fmt &pfmt;
                %end;
		%else %if "%_substr(&_stat_, 1, 1)"="P" %then %do;
                    %let j=%index(&_stat_, _P);
                            
                    %if &j>0 %then %do;
                        %let temp=%_substr(&_stat_, 1, &j-1) %_substr(&_stat_, &j+1);
                        %let comma=&comma &temp %_substr(&_stat_, 1, 8);
                    %end;
                    %else %let temp=&_stat_;

                    %do j=1 %to %_count(&temp);
                        %let _stat_=%scan(&temp, &j, %str( ));
			%let pctlout=&pctlout %_tr(%_substr(&_stat_, 2), from=_, to=.);
			%let univstat=&univstat &_stat_;
			%let univfmt=&univfmt &fmt;
                    %end;
		%end;
		%else %if &_stat_=MEAN_STD | &_stat_=MEAN_SD %then %do;
                    %let comma=&comma MEAN STD &_stat_;
                    %let univout=&univout mean=mean std=std;
                    %let univstat=&univstat MEAN STD;
                    %let univfmt=&univfmt &fmt &fmt;
                %end;		
                %else %if &_stat_=MEAN_95CI %then %do;
                    %let comma=&comma LO_95CI HI_95CI &_stat_;
                    %let univstat=&univstat LO_95CI HI_95CI;
                    %let univfmt=&univfmt &fmt &fmt;
                %end;
		%else %if &_stat_=MIN_MAX %then %do;
                    %let comma=&comma MIN MAX MIN_MAX; 
		    %let univout=&univout min=min max=max;
                    %let univstat=&univstat MIN MAX;
                    %let univfmt=&univfmt &fmt &fmt;
                        
                    %if %length(&&id&i) %then %do;
                        %let comma=&comma MINID MAXID MINMAXID; 
                        %let univstat=&univstat MINID MAXID;
                        %let univfmt=&univfmt %_repeat(%str( )%scan(&&id&i &format, 2, %str( )), 2);
                        %let id&i=%scan(&&id&i, 1, %str( ));
                    %end;
                %end;
		%else %if &_stat_=Q1_Q3 %then %do;
                    %let comma=&comma Q1 Q3 Q1_Q3;
                    %let univout=&univout q1=q1 q3=q3;
                    %let univstat=&univstat Q1 Q3;
                    %let univfmt=&univfmt &fmt &fmt;
                %end;
		%else %if &_stat_=T %then %do;
                    %let comma=&comma T PROBT T_PROBT;
		    %let univout=&univout t=t probt=probt;
                    %let univstat=&univstat T PROBT;
                    %let univfmt=&univfmt &fmt &pfmt;
                %end;
                %else %if &_stat_=SIGNRANK %then %do;
                    %let comma=&comma SIGNRANK PROBS S_PROBS;
		    %let univout=&univout SIGNRANK=SIGNRANK probs=probs;
                    %let univstat=&univstat SIGNRANK PROBS;
                    %let univfmt=&univfmt &fmt &pfmt;
                %end;
                %else %if &_stat_=MSIGN | &_stat_=SIGNTEST %then %do;
                    %let comma=&comma MSIGN PROBM MS_PROBM;
		    %let univout=&univout MSIGN=MSIGN probm=probm;
                    %let univstat=&univstat MSIGN PROBM;
                    %let univfmt=&univfmt &fmt &pfmt;
                %end;
                %else %if &_stat_=NORMAL %then %do;
                    %let comma=&comma SW PROBSW SW_PROBN NL PROBNL NL_PROBN;
		    %let univout=&univout NORMAL=sw probn=probsw;
                    %let univstat=&univstat SW PROBSW NL PROBNL;
                    %let univfmt=&univfmt &fmt &pfmt &fmt &pfmt;
                %end;
		%else %if &_stat_=MEDIAN_IQR %then %do;
                    %let comma=&comma MEDIAN QRANGE MEDIAN_IQR;
                    %let univout=&univout median=median qrange=qrange;
                    %let univstat=&univstat MEDIAN QRANGE;
                    %let univfmt=&univfmt &fmt &fmt;
                %end;		
		%else %if &_stat_=IQR %then %do;
                    %let comma=&comma MEDIAN QRANGE MEDIAN_IQR Q1 Q3 Q1_Q3 MIN1_5 MAX1_5 IQR1_5 MIN MAX MIN_MAX MIN3 MAX3 IQR3;
                    %let univout=&univout median=median q1=Q1 q3=Q3 qrange=QRANGE MIN=MIN MAX=MAX;
                    %let univstat=&univstat MEDIAN QRANGE Q1 Q3 MIN1_5 MAX1_5 MIN MAX MIN3 MAX3 ;
                    %let univfmt=&univfmt &fmt &fmt &fmt &fmt &fmt &fmt &fmt &fmt &fmt &fmt;
                %end;	
                %else %do;
                    %if %index(&_stat_, =)=0 %then %let _stat_=&_stat_=&_stat_;
                    %let univout=&univout &_stat_;
                    %let univstat=&univstat %scan(&_stat_, 2, =);
                    %let univfmt=&univfmt &fmt;
                %end;
	    %end;
	%end;

        %if %length(&pctlout) %then %let univout=&univout pctlpts=&pctlout pctlpre=p;

	%*call _scratch to get a temporary dataset;
	%let scratch=%_scratch(data=work);

        %if %index(&&stat&i, KAPPA) | %index(&&stat&i, MCNEM) %then %let order&i=;
        %else %if "%upcase(&&format&i)"="YESNO." & %length(&&order&i)=0 & 
            %index(&&stat&i, COUNT) & %index(&&stat&i, MEAN)=0 %then
            %let order&i=Yes\No;
            
        %if %length(&&char&i) | %length(&&order&i) %then %do;
            %let dsid=%sysfunc(open(&out));
            %let varlabel=%sysfunc(varlabel(&dsid, %sysfunc(varnum(&dsid, &&var&i))));
            %let dsid=%sysfunc(close(&dsid)); 
            data &out;
                set &out;
                _var&i._=&&var&i;
            %if %length(&varlabel)=0 %then %let varlabel=&&var&i;
            %if "%lowcase(&&label&i)"="mixedcase" | "%lowcase(&&label&i)"="mixed" %then
                label _var&i._="%upcase(%_substr(&varlabel, 1, 1))%lowcase(%_substr(&varlabel, 2))";
            %else %if "%lowcase(&&label&i)"="lowcase" | "%lowcase(&&label&i)"="lowercase" | "%lowcase(&&label&i)"="lower" %then
                label _var&i._="%lowcase(&varlabel)";
            %else %if "%lowcase(&&label&i)"="upcase" | "%lowcase(&&label&i)"="uppercase" | "%lowcase(&&label&i)"="upper" %then
                label _var&i._="%upcase(&varlabel)";
            %else label _var&i._="&varlabel";;
            *copy the variable before reorder so that it does not impact column summaries;
            run;
            %let var&i=_var&i._;
            %_reorder(data=&out, out=&scratch, by=&by, format=%scan(&&format&i &&char&i, 1, %str( )), 
                var=&&var&i, where=&&where&i, order=&&order&i, split=&split);
            %let format&i=%_substr(&&var&i, 1, 7)_.;
        %end;
        %else %if %length(&&where&i) %then %do;
            data &scratch;
                set &out;
                where &&where&i;
            run;
        %end;
        %else %let scratch=&out;
            
	%*Use summary statistics to Trim/Winsorize the data if requested;
	%if %length(&&trim&i) | %length(&&winsor&i) %then %do;
            %let temp=%_scratch;
            
            %*Cutoffs calculated from all data;
            proc univariate pctldef=&pctldef round=&round vardef=&vardef mu0=&&mu0&i 
                data=&scratch noprint;
                
                id &&id&i;
                by %_by(&by, proc=1);
                %if "&&weight&i"^="1" %then weight _weight_;;
                var &&var&i;
                output out=&temp min=min max=max pctlpre=P pctlpts=&pctlout;
            run;

	    data &scratch;
                %if %length(&by) %then %do;
                    merge &temp(keep=%_by(&by) min max p:) &scratch;
                    by &by;
                %end;
                %else %do;
                    set &scratch;
                    if _n_=1 then set &temp(keep=%_by(&by) min max p:);
                %end;
                
                if n(&&var&i) then 
                %if %length(&&trim&i) %then 
                    if fuzz(&&var&i-%scan(&&trim&i, 1, %str( )))<0 |
                        fuzz(%scan(&&trim&i, 2, %str( ))-&&var&i)<0 then &&var&i=.;
                %else %if %length(&&winsor&i) %then 
                    &&var&i=max(%scan(&&winsor&i, 1, %str( )), min(&&var&i, %scan(&&winsor&i, 2, %str( ))));
                ;
	    run;
        %end;
            
        %if %length(&glmstat) | %length(&kwout) %then %do;
            %if %length(&class)=0 %then %do;
                %let class=%scan(&col1, 1, %str(^&|=<>));
                
                %if %datatyp(&class)=NUMERIC %then %let class=%scan(&col1, 2, %str(^|&=<>));
                
                %let class=%upcase(&class);
                %put WARNING: CLASS default not specified:  CLASS=&class assumed.;
            %end;
        %end;
        
	%let class&i=%upcase(&&class&i);

        %if %_count(&&class&i)=0 %then %let kwout=;
        %else %if %length(&kwout) %then %do;
            %let kwdata=%_scratch(data=work);
            
	    proc npar1way wilcoxon data=&scratch;
		by %_by(&by, proc=1);
                %if &&weight&i^=1 %then freq &&weight&i;;
		%if %_count(&&class&i)=2 %then format &&class&i;;
		class %scan(&&class&i, 1, %str( ));
                var &&var&i;
                output out=&kwdata(keep=%_by(&by) &kwout) wilcoxon;
	    run; 
                
            %*if %_exist(&kwdata) %then %do;
                proc print data=&kwdata;
                run; 

                %if %_level(data=&kwdata, var=df_kw, split=)=1 %then %do;
                    data &kwdata;
                        set &kwdata;
                        drop df_kw;
                        rename _kw_=_mw_ p_kw=p_mw;
                    run;                    
            
                    /*
                    %let kwout=_MW_ P_MW;
                    %let kwfmt=&fmt &pfmt;
                    %let comma=&comma _MW_ P_MW MW_P_MW;
                    The MW/KW p-value is the statistic
                    */
                    %let kwout=P_MW;
                    %let kwfmt=&pfmt;
                %end;
            %*end;
            %*else %let kwout=;
        %end;
            
	%*call PROC GLM if necessary;
        %if %length(&glmstat) %then %do;
            %do j=1 %to %_count(&&class&i);
                %let glmdata=%scan(&&class&i, &j, %str( ));
                %if %index(&glmdata, .)=0 %then %let glmclass=&glmclass &glmdata;
            %end;
            
            %let glmdata=%_scratch(data=work);
            
	    proc glm data=&scratch outstat=&glmdata;
		by %_by(&by, proc=1);
                %if &&weight&i^=1 %then weight &&weight&i;;
		%if %_count(&&class&i)=2 %then format &&class&i;;
		class &glmclass;
                model &&var&i=&glmclass &&model&i / &glmstat;
	    run; 
               
            proc print data=&glmdata;
            run;
            
            data &glmdata;
                set &glmdata(rename=(prob=probf));
		by %_by(&by, proc=1);
                keep %_by(&by, proc=1) &glmout;
                
                retain ddf;
                
                if _type_='ERROR' then ddf=df;
                
                if _type_="&glmstat" & upcase(_source_)="%scan(&&class&i, 1, %str( ))" & n(probf);
                
                ndf=df;
            run;
               
            %if %_nobs(data=&glmdata)=0 %then %let glmdata=;
            %else %do;
            proc print data=&glmdata;
            run;
            %end;
        %end;

	%*call PROC FREQ if necessary;
	%if %length(&freqstat) %then %do;
            %if %length(&table)=0 %then %do;
                %let table=%upcase(%scan(&col1, 1, %str(^&|=<>)));
                
                %if %datatyp(&table)=NUMERIC %then 
                    %let table=%upcase(%scan(&col1, 2, %str(^|&=<>)));
                %else %do;
                    %let j=%index(&table, IN%str(%());
                
                    %if &j=0 %then %let j=%index(&table, IN:);
                    
                    %if &j %then %let table=%substr(&table, 1, &j-1);
                %end;
                
                %put WARNING: TABLE default not specified:  TABLE=&table assumed.;
            %end;
            
            %if %length(&table)>0 %then %do j=1 %to %_count(&freqstat);
                %let freqdata=%scan(&freqstat, &j, %str( ));
            
                %if &freqdata=LGOR | &freqdata=MHOR | %index(&freqdata, CMH) | 
                    %index(&freqdata, LGRRC) | %index(&freqdata, MHRRC) 
                    %then %let freqcmh=&freqcmh &freqdata;
                %else %let freqoth=&freqoth &freqdata;
            %end;
            
            %if %length(&freqcmh) %then %do;
                %let freqdata=%_scratch(data=work);

                proc freq data=&scratch;
                    by %_by(&by, proc=1);
                    %if &&weight&i^=1 %then weight &&weight&i;;
                    format &&var&i &&format&i;
        	    tables &&table&i / cmh alpha=&alpha &&freq&i;
                    output out=&freqdata &freqcmh;
        	run;
            %end;
    
            %if %length(&freqoth) %then %do;
                %let freqstat=%_scratch(data=work);

                proc freq data=&scratch;
                    by %_by(&by, proc=1);
                    %if &&weight&i^=1 %then weight &&weight&i;;
                    format &&var&i &&format&i;
        	    tables &&table&i / agree chisq measures alpha=&alpha &&freq&i
                    %if %_indexw(&freqoth,EXACT) %then fisher;;
                    output out=&freqstat &freqoth;
        	run;
            
                %if %length(&freqcmh) %then %do;
                    data &freqdata;
                        merge &freqdata &freqstat;
                        by %_by(&by, proc=1);
                    run;
                %end;
                %else %let freqdata=&freqstat;
            %end;            
            
            %if %_dsexist(&freqdata) %then %do;
                proc print data=&freqdata;
                run;
            %end;
            %else %let freqdata=;
	%end;
    
	%*call _scratch to get a temporary dataset;
	%let data&i=%_scratch(data=work); %*(notes=1);

	%*keep a list of temporary datasets;
	%let data=&data &&data&i;

	%*loop through the columns that you need to create;
	%do j=1 %to &col0;
	    data &&data&i;
		set &scratch;
		%*subset with column where clause;
		%if &j<&col0 %then where &&col&j;;
		by &by;
                
		%*format the variable;
		format &&var&i &&format&i;
		
		%*create the WEIGHT dataset variable so PROC MEANS can calculate N correctly;
                _weight_=&&weight&i; 
                
		%*create the _MISSING dataset variable so NMISS can be weighted; 
                %if "&&weight&i"^="1" %then _missing=_weight_*nmiss(&&var&i);;
                
                %*keep only the variables that you need;
                keep %_by(&by) &&var&i &&id&i _weight_ %if "&&weight&i"^="1" %then _missing;; 

                %if &j=1 %then %do;
                    %*set the label for the variable whether it was part of the macro call or
			defined in the input dataset -- and handle embedded single/double
                        quotes if necessary;

                    %let temp=%upcase(&&label&i);

                    %if "&temp"="MIXEDCASE" | "&temp"="MIXED" |
                        "&temp"="LOWCASE"   | "&temp"="LOWERCASE" | "&temp"="LOWER" |
                        "&temp"="UPCASE"    | "&temp"="UPPERCASE" | "&temp"="UPPER" |
                        "&temp"="NAMEONLY"  | "&temp"="NAMEPLUS" %then %do;

			length _label_ $ &len;
			%*drop _label_;

			if _n_=1 then do;
                            %if "&temp"="NAMEONLY" %then _label_="&&var&i";
                            %else %do;
                                call label(&&var&i, _label_);
                                
                                %if "&temp"="NAMEPLUS" %then _label_="&&var&i:"||_label_;
                            %end;
                            ;
                            if "&&var&i"=upcase(_label_) then select("&temp");
                                when("MIXEDCASE", "MIXED") _label_=upcase(substr(_label_, 1, 1))||
                                    lowcase(substr(_label_, 2));
                                when("LOWCASE", "LOWERCASE", "LOWER") _label_=lowcase(_label_);
                                when("UPCASE", "UPPERCASE", "UPPER") _label_=upcase(_label_);
                                otherwise;
                            end;
                        
                            call symput("label&i", trim(_label_));
                    	end;
                    %end;
                    %else %if %length(%bquote(&&label&i)) %then %do;
                        %if %_count(%bquote(&&label&i), split=''"")=1 %then
                            %let label&i=%scan(%bquote(&&label&i), 1, ''"");
                    %end;
                %end;
	    run;

            &debug.%_printto(file=%_null);
            
	    %*call PROC UNIVARIATE with the statistics it needs to compute;
            %if "&&weight&i"^="1" %then %do;
            %*special handling so that _MISSING is weighted correctly;
	    proc univariate round=&round vardef=&vardef mu0=&&mu0&i data=&&data&i;
                id &&id&i;
                by %_by(&by, proc=1);
		var _missing;
                output out=_missing sum=_missing;
	    run;

            %* PCTLDEF not allowed with a WEIGHT statement;
            proc univariate /*pctldef=&pctldef*/ round=&round vardef=&vardef mu0=&&mu0&i
                %if %length(&debug) %then plot;
                %if %index(&univstat, PROBSW) %then normal;
                data=&&data&i;
                
                id &&id&i;
                by %_by(&by, proc=1);
                weight _weight_;;
		var &&var&i;
                output out=col&j sumwgt=_nonmiss &univout;
	    run;

            data col&j;
                merge col&j _missing;
            run;
            %end;
            %else %do;
	    proc univariate pctldef=&pctldef round=&round vardef=&vardef mu0=&&mu0&i
                %if %length(&debug) %then plot;
                %if %index(&univstat, PROBSW) %then normal;
                data=&&data&i;
                
                id &&id&i;
                by %_by(&by, proc=1);
		var &&var&i;
                output out=col&j sumwgt=_nonmiss &univout nmiss=_missing;
	    run;
            %end;
                %*Requesting IQR implies computing Box-Whisker stats 1.5*IQR and 3*IQR;
                %if %_indexw(&&stat&i, IQR) %then %do;
                    data col&j;
                        set col&j;
                        
                        min1_5=q1-1.5*qrange;
                        max1_5=q3+1.5*qrange;
                        min3=q1-3*qrange;
                        max3=q3+3*qrange;
                    run;

                    proc print data=col&j;
                        var qrange min3 min min1_5 q1 median q3 max1_5 max max3;
                    run;
                %end;            
        
                %if %_indexw(&&stat&i, MEAN_95CI) %then %do;
                    data col&j;
                        set col&j;
                        
                        lo_95ci=mean-1.96*std/sqrt(_nonmiss);
                        hi_95ci=mean+1.96*std/sqrt(_nonmiss);
                    run;

                    proc print data=col&j;
                        var mean std lo_95ci hi_95ci;
                    run;
                %end;            

                %*Normality test depends on sample size;
                %if %index(&univstat, PROBSW) %then %do;
                    data col&j;
                        set col&j;
                        
                        if _nonmiss>2000 then do;
                            nl=sw; sw=.;
                            probnl=probsw; probsw=.;
                        end;
                    run;

                    proc print data=col&j;
                        var _nonmiss sw probsw nl probnl;
                    run;
                %end;
                    
		%*if total column, merge in the PROC FREQ/GLM/NPAR1WAY output, if any;
		%if &j=&total & %length(&glmdata.&kwdata.&freqdata) %then %do;
		    data col&j;
			merge &glmdata &kwdata &freqdata col&j;
			by &by;
		    run;
		%end;
                                
                %if %length(&&id&i) %then %do;
                    %*call PROC MEANS computing MINID/MAXID;
		    proc means &&means&i data=&&data&i;
		        by %_by(&by, proc=1);
                        %if "&&weight&i"^="1" %then weight _weight_;;
                        id &&id&i;
		        var &&var&i;
                        output out=col00 minid=minid maxid=maxid;
		    run;
                
		    data col&j;
			merge col00 col&j;
			by &by;
		    run;
                %end;
                
		%*if COUNT, COUNTCOL or COUNTROW is a statistic that you want to compute,
                    then call PROC MEANS; 
		%if &count=COL | &count=PCT %then %do;
		    proc means &&means&i nway data=&&data&i;
			by %_by(&by, proc=1);
			class &&var&i;
			var _weight_;
			output out=&&data&i sum=count;
		    run;

		/*
                    proc print data=&&data&i;
                    run;
                    
                    proc print data=col&j;
                    run;
                */
                    
		    data col&j;
			set col&j &&data&i; 
			by &by;
			drop _type_ _freq_ _total_;
			retain _total_;

			if %_first(&by) then do;
                            %*The MISSING option to the PROC MEANS statement specifies that
                                a missing CLASS variable should not be ignored, i.e. it is
                                valid to perform a count of the observations grouped into the 
                                missing CLASS.  Therefore, the total number of observations
                                needs to be adjusted accordingly and an observation of the
                                missing type may need to be created if one does not already
                                exist.  Use this option with caution.  If your data does not
                                have missing values you may have MERGE problems.;
                            %if %index(&&means&i, MISSING) %then %do;
                                _nonmiss=sum(_nonmiss, _missing);
                                _total_=_nonmiss;
                                output;

                                if _missing=0 then do;
                                    &&var&i=.;
                                    _nonmiss=.;
                                    _missing=.;
                                    count=0;
                                    pct_col=0;
                                    output;
                                end;
                            %end;
                            %else %do;
                                _total_=_nonmiss;
                                output;
                            %end;
                        end;
            
			%*compute PCT_COL;
			else if _total_ then do;
                            pct_col=100*count/_total_;
                            output;
                        end;
		    run;
		%end;
		%else %do;
		    data col&j;
			set col&j;
			&&var&i=.;
		    run;
		%end;

            &debug.%_printto;

                /*
                    proc print data=col&j;
                    run;
                */    
                
		%*transpose the dataset;
                %if &count=COL | &count=PCT %then %let temp=count pct_col;
                %else %let temp=;
                
                %if ^%index(&&means&i, MISSING) %then %let temp=&temp _missing;
                %if &j=&total %then %let temp=&glmout &kwout &freqout &temp;

                %_transpo(data=col&j, out=col&j, name=_stat_, value=_col&j, 
                    var=_nonmiss &univstat &temp, copy=%_by(&by) &&var&i, label=, text=);

		%*FMT:  the list of PROC UNIVARIATE statistics formats followed by
                    the PROC FREQ statistics formats;
		%let fmt=&univfmt &glmfmt &kwfmt &freqfmt;
		%let fmtcount=%_count(&fmt);
                %let _index_=%_substr(_%_by(&by)&&var&i, 1, 32);
                
		data col&j(index=(&_index_=(%_by(&by) &&var&i _index_)));
		%*data col&j(index=(%_by(&by)&&var&i.._index_=(%_by(&by) &&var&i _index_)));
                    length col&j $ &length;
                    set col&j;
                    %*create the _INDEX_ dataset variable based on the order that
                        the statistics were specified;
                    _index_=100*indexw("_NONMISS &univstat &glmout &kwout &freqout COUNT PCT_COL _MISSING", trim(_stat_));

                    %*create the COL&J dataset variable as a character string of 
                        the specified statistic;
                    %if &fmtcount %then %do k=1 %to &fmtcount;
                        %local fmt&k;
                        %let fmt&k=%scan(&fmt, &k, %str( ));
                        
			if _stat_="%scan(&univstat &glmout &kwout &freqout, &k, %str( ))" then do;
			    col&j=put(_col&j, &&fmt&k);
                        
                            %if "&pfmt"="&&fmt&k" %then %do;
                                if col&j=put(0, &pfmt) then do;
                                    substr(col&j, &length, 1)='1';
                                    
                                    substr(col&j, %eval(&length-2-%scan(&pfmt, 2, .)), 1)='<';
                                end;
                            %end;
                        end;
                    %end;
                    %else col&j=" ";;
		run;

                %if "%upcase(&&means&i)"="MISSING" %then %do;
                data col&j(index=(&_index_=(%_by(&by) &&var&i _index_)));
                %*data col&j(index=(%_by(&by)&&var&i.._index_=(%_by(&by) &&var&i _index_)));
                    set col&j;
                    by %_by(&by) &&var&i _index_;
                    if &&var&i=. & ^first._index_ then delete;
                run;
                %end;
	%end;

	data &&data&i;
            length _name_ $ 8 _label_ $ &len;
            
            %*create arrays of the character and numeric column variables;
            array col(&col0) $ &length;
            array _col(&col0);
            
            drop j k;
            
            %*create the _VAR_ and _NAME_ variables which will be used to sort the dataset;
            retain _var_ &h _name_ "&&var&i";

            %*merge all of the columns into one dataset;
            merge %do j=1 %to &col0;
		col&j
            %end;
            ;
            by &by groupformat &&var&i _index_;
            
            %*create the _VALUE_ variable which will be used to report frequencies;
            _value_=&&var&i;

            %if &count=ROW | &count=PCT | &count=NROW %then pct_row:;

            if _stat_ in ('_NONMISS', '_MISSING', 'COUNT', 'PCT_COL', 'PCT_ROW') then do j=1 to &col0;
		%*if a particular column is missing, then it is a zero cell;
		if _col(j)=. then _col(j)=0;

		%*create the character string for PCT_COL;
		if _stat_='PCT_COL' then do;
		    col(j)=put(_col(j), &pctfmt);
		    k=index(col(j), '(00');
		    if k then substr(col(j), k, 3)='(  ';
		    k=index(col(j), '(0');
		    if k then substr(col(j), k, 2)='( ';
		end;
		%*create the character string for PCT_ROW;
		else if _stat_='PCT_ROW' then do;
		    if j^=&col0 then do;
                        if _col(&col0)=0 then _col(j)=0;
			else _col(j)=100*_col(j)/_col(&col0);
                    
                        col(j)=put(_col(j), &pctfmt);
                        
                        k=index(col(j), '(00');
		        if k then substr(col(j), k, 3)='(  ';
                        k=index(col(j), '(0');
                        if k then substr(col(j), k, 2)='( ';
		    end;
		end;
		%*create the character string for N, MISSING and COUNT;
		else col(j)=put(_col(j), &countfmt);
            end;
        

            %*if you are computing N, let the _LABEL_ be the variable label;
            if _stat_='_NONMISS' | _index_=200 then _label_=
		%if &&indent&i %then repeat(" ", &&indent&i-1)||;
                "&&label&i";
        
            %*if you are computing a frequency or a count, let the _LABEL_ be the value itself;
            else if _stat_ in ('COUNT', 'PCT_COL', 'PCT_ROW') then 
		_label_=%if &offset %then repeat(" ", &offset-1)||;
			%if &&indent&i %then repeat(" ", &&indent&i-1)||;
		put(&&var&i, &&format&i-L);

            %*else if you are computing MISSING, let the _LABEL_ be specified by the user;
            else if _stat_='_MISSING' then _label_=
		%if &offset %then repeat(" ", &offset-1)||;
		%if &&indent&i %then repeat(" ", &&indent&i-1)||;
                "&&miss&i";

            %*else if you are computing a statistic, then _LABEL_ is defined by the format $_STAT_.;
            else _label_=%if &offset %then repeat(" ", &offset-1)||;
		%if &&indent&i %then repeat(" ", &&indent&i-1)||;
            put(_stat_, $_stat_.);

            %*in order to compute PCT_ROW, you need to create an observation for the PCT_ROW statistic;
            %if &count=ROW | &count=PCT | &count=NROW %then %do;
		if _stat_ in ('_NONMISS' %if &count=ROW | &count=PCT %then , 'COUNT';) then do;
			output;
			_stat_='PCT_ROW';
                        _index_=_index_+100;
			goto pct_row;
		end;
		else if _stat_='PCT_ROW' then do;
			_col(&col0)=100;
			col(&col0)=put(100, &pctfmt);
			output;
		end;
		else output;
            %end;
	run;
/*proc print;endsas;*/
	%*special case 1:  when a label has been specified with the split character
            force out one blank observation for each line;

	%if %index(%bquote(&&label&i), &split) %then %do;
            %let k=%_count(%bquote(&&label&i), split=&split);

            data &&data&i;
		set &&data&i;
		array col(&col0);
		array _col(&col0);
		drop j k;

		if _index_= %if &count=PCT | &count=ROW | &count=NROW %then 200; %else 100; then do k=1 to &k;
                    _index_=_index_+k-1;

                    _label_= %if &&indent&i %then repeat(" ", &&indent&i-1)||;
			scan("&&label&i", k, "&split");

                    if k=2 then do j=1 to &col0;
                        col(j)='';
                        _col(j)=.;
                    end;

                    output;
		end;
		else output;
            run;
	%end;
/*proc print;endsas;*/
	%*special case 2:  when COUNTCOL or COUNTROW statistic has been specified create one
		observation with character string that has frequency and percentage together;
	%if &count=COL | &count=ROW | &count=PCT | &count=NROW %then %do;
            data &&data&i;
		array col(&col0) $ 
                    %if &count=PCT %then %eval(3*&length);
                    %else %eval(2*&length);
                ;
        
		set &&data&i; 
		by &by groupformat &&var&i _index_;
		array _col(&col0);
		array _count(&col0) $ %eval(2*&length) _temporary_;
		drop j;

		if %_first(&by &&var&i) then do j=1 to &col0;
		    _count(j)='';
		end;

		if _stat_ in ('COUNT' %if &count^=COL %then , '_NONMISS';) then do j=1 to &col0;
		    _count(j)=col(j);
		end; 
		else if _stat_='PCT_ROW' then do;
                    if _index_<300 then _stat_='NROW';
                    else _stat_="COUNT&count";
                    
                    do j=1 to &col0;
                        _count(j)=trim(_count(j))||left(col(j));
                    
                        if _stat_='COUNTROW' | _index_=200 then do;
                            col(j)=_count(j);
                            _col(j)=scan(col(j), 1, '(');
                        end;
                    end;
                    
                    if _stat_='COUNTROW' | _stat_='NROW' then output;
		end; 
		else if _stat_="PCT_COL" then do;
		    _stat_="COUNT&count";

		    do j=1 to &col0;
                        col(j)=trim(_count(j))||left(col(j));
                        _col(j)=scan(col(j), 1, '(');
		    end;

		    if _stat_ in ('COUNTCOL', 'COUNTPCT') then output;
		end;
		else output;
            run;
	%end;
/*proc print;endsas;*/
	%*special case 3:  the comma variable passes a list of two variable 
            combinations to create one observation/character string that has 
            them both with a comma in between (or if it is a mean/std pair, 
            the mean followed by the std in parentheses);
	%if %length(&comma) %then %do;
            %let arg0=%_count(&comma)/3;
	    
	    %do k=1 %to &arg0;
	        %let arg1=%scan(&comma, 3*(&k-1)+1, %str( ));
	        %let arg2=%scan(&comma, 3*(&k-1)+2, %str( ));
	        %let arg3=%scan(&comma, 3*(&k-1)+3, %str( ));

	    data &&data&i;
	    	array col(&col0) $
                        %if "&count"="ROW" %then %eval(3*&length+2);
                        %else %eval(2*&length+2);
                    ;
                    
	    	set &&data&i;
	    	by &by groupformat &&var&i _index_;
	    	array _col(&col0);
	    	array _comma(&col0) $ &length _temporary_;
	    	drop j;
	
	    	if %_first(&by &&var&i) then do j=1 to &col0;
	    	    _comma(j)='';
	    	end;

	    	if _stat_="&arg1" then do j=1 to &col0;
	    	    _comma(j)=col(j);
	    	end; 
	    	else if _stat_="&arg2" then do;
	    	    _stat_="&arg3";
	    	    _label_=%if &offset %then repeat(" ", &offset-1)||;
	    		    %if &&indent&i %then repeat(" ", &&indent&i-1)||;
	    	    put(_stat_, $_stat_.);
	
	    	    do j=1 to &col0;
	    		if col(j)^='' then col(j)=trim(_comma(j))||
	    		    %if "%_substr(&arg1, 1, 4)"="MEAN" | "%_substr(&arg2, 1, 4)"="PROB" |
                                "%_substr(&arg2, 1, 2)"="P_"   | "%_substr(&arg2, 1, 2)"="E_"   |
                                "%_substr(&arg1, 1, 6)"="MEDIAN"
                            %then '('||trim(left(col(j)))||')';
	    		    %else ', '||left(col(j));
	    			;
	    		    _col(j)=.;
	    	    end;

	    	    output;
	    	end;
	    	else output;
	    run;
            %end;
	%end;
    %end;
%end;

data &out;
    set &data;
run;
    
proc sort data=&out;
    by %_by(&by, proc=1) _var_ _index_ _value_;
run;

%if %_nobs(data=&out)=0 %then 
    %put ERROR: SAS Dataset OUT=&out is empty.;
%else %if %length(&file) %then %do;
    %global pageno;

    %if %length(&pageno)=0 %then %let pageno=1;
    
    %local headers;
    %let outpct=%upcase(&outpct);

    %if %length(&&head&col0)=0 %then %let head&col0=Total;
    %if %length(&head1)=0 %then %let head1=%upcase(&col1);

    %if %length(&head2)=0 %then %do;
        %if "&col2"="((&col1)=0)" %then %let head2=No &head1;
        %else %do i=2 %to &col0-1; 
            %let head&i=%upcase(&&col&i);
        %end;
    %end;
    
    %if %length(&colorder)=0 %then %let colorder=1 to &col0;
    %else %let colorder=%_list(&colorder, split=%str(,));
    
    %do i=0 %to &col0;
        %local len&i beg&i;
    %end;
    
data col0(keep=%_by(&by) _var_ _lines_);
    length %do i=0 %to &col0; head&i $ %_max(1, %length(&&head&i)) %end;;
    set &out(keep=%_by(&by) _var_ _label_ col1-col&col0) end=eof;
    by &by _var_;
        
    %_retain(var=_lines_=%eval(&foot0+1), by=&by _var_);
    _lines_+1;
        
    if last._var_ then output col0;
    
    array col(0:&col0) $ _label_ col1-col&col0;
    array _len(0:&col0)  len0-len&col0 (%eval(&col0+1)*0);
    array _beg(0:&col0)  beg0-beg&col0;
    array _head(0:&col0) head0-head&col0 (%do i=0 %to &col0; "&&head&i " %end;);

    retain beg0-beg&col0;
        
    do i=0 to &col0;
        j=length(col(i));
        _len(i)=max(_len(i), j);
        
        if col(i)>'' then _beg(i)=min(_beg(i), j-length(left(col(i))));
    end;
    
    if eof then do;
        headers=1;
    
        do i=0 to &col0;
            j=indexc(_head(i), "&split");
            h=0;
            k=1;
            
            do while(j);
                k=k+1;
                h=max(h, j-1);    
                _head(i)=substr(_head(i), j+1);
                j=indexc(_head(i), "&split");
            end;
        
            headers=max(headers, k);
            
            h=max(h, length(_head(i)));
        
            if h>(_len(i)-_beg(i)) then _len(i)=h+_beg(i);
        
            call symput('len'||left(i), trim(left(_len(i))));
            call symput('beg'||left(i), trim(left(_beg(i))));
        end;
        
        call symput('headers', trim(left(headers)));
    end;
run;

%if &latex %then %do;
footnote;
options nodate nonumber;
%end;

data col0;
    merge col0 &out;
    by &by _var_;
    drop i;
    array col(&col0) $ col1-col&col0;
    array _beg(&col0) _temporary_ (%do i=1 %to &col0; &&beg&i %end;);
                        
    do i=1 to &col0;
        col(i)=substr(col(i), _beg(i)+1);
                    
        %if "&outpct"="COL" | "&outpct"="NOROW" %then %do;
        if _stat_ in('NROW', 'COUNTPCT') & index(col(i), ')') then 
            col(i)=substr(col(i), 1, index(col(i), '(')-1)||substr(col(i), index(col(i), ')')+1);
        %end;
        %else %if "&outpct"="ROW" | "&outpct"="NOCOL" %then %do;
        if _stat_='COUNTPCT' & index(col(i), ')') then col(i)=substr(col(i), 1, index(col(i), ')'));
        if i=&col0 & _stat_ in('NROW', 'COUNTPCT') & index(col(i), '(100.0%)') then 
            col(i)=substr(col(i), 1, index(col(i), '(100.0%)')-1);
        %end;
    end;
run;

    %if %length(&by) %then %do;
        %let h=0;
    
        %do i=1 %to &title0;
            %let j=%index(%qupcase(&&title&i), #BYVAL);
            
            %if &j %then %do;
                %let h=%eval(&h+1);
                %let var&h=%scan(%_by(&by), %substr(&&title&i, &j+6, 1), %str( ));
                %*let var&h=%scan(%substr(&&title&i, &j+6), 1, ());
                %let format&h=&&var&h;
                %let var&h=%_blist(&&format&h, data=col0);
            
                %if %_count(&&var&h)=1 %then %let var&h=&&var&h &format;
            %end;       
        %end;
            
        %let var0=&h;
    %end;   

%if &latex=1 %then 
    %_printto(print=&filetex, append=&append, pageno=&pageno);
%else
    %_printto(print=&file, append=&append, pageno=&pageno);

    %let options=%sysfunc(getoption(date)) %sysfunc(getoption(number));
    
data _null_;
    length _label_ $ %eval(&len0+&latex) 
            tmp0 $ &len0 head0 $ %_max(%length(&head0), 1)
        %do i=1 %to &col0; 
            col&i  $ %eval(&&len&i-&&beg&i+2*&latex) 
            tmp&i  $ %eval(&&len&i-&&beg&i+3*&latex) 
            head&i $ %_max(%length(&&head&i), 1)
        %end;;
    set col0 end=eof;
    by &by _var_;
    
/* 
   need to be careful with variable names like PAGENO
   if we are summarizing a variable by that name
   then the output is buggy FIXME
   for example, PAD was replaced with _PAD_
   that is a far more unlikely variable name
   however there is still a possibility of collision
*/
    retain pageno &pageno _ls_ %_ls _pad_ _maxlines_;
    drop i j k _ptr_;
    
    file print footnotes linesleft=linesleft 
    %if %length(&by) %then notitles;;
    
    array col(0:&col0)  $ _label_ col1-col&col0;
    array _tmp(0:&col0)  $ tmp0-tmp&col0;
    array _head(0:&col0) $ head0-head&col0 
        (%do i=0 %to &col0; "&&head&i " %end;);
    array _len(0:&col0) _temporary_ 
        (%eval(&len0+&latex) 
            %do i=1 %to &col0; %eval(&&len&i-&&beg&i+2*&latex) %end;);

    if _n_=1 then do;
        _maxlines_=%_ps-&foot0;
        _pad_=0;
        
        do i=0, &colorder;
            _pad_=_pad_+_len(i);
        end;
        
        _ptr_=1;
    
        do i=0, &colorder;
            _ptr_=_ptr_+1;
        end;
        
        _pad_=_ls_-_pad_;
        
        _pad_=max(1, floor(_pad_/_ptr_));
    end;    
    
    *put;
    
    if (first._var_ & linesleft<_lines_<=_maxlines_) | %_first(&by) then do;

        link header;
        put;
    end;

    _ptr_=_pad_;
        
    do i=0, &colorder;
        %if &latex %then %do;
                col(i)=translate(col(i), '-', '_');
                col(i)=tranwrd(col(i), '#', '\#');
                col(i)=tranwrd(col(i), '$', '\$');
                col(i)=tranwrd(col(i), '<=', '$\le$');
                col(i)=tranwrd(col(i), '>=', '$\ge$');
                col(i)=tranwrd(col(i), '<', '$<$');
                col(i)=tranwrd(col(i), '>', '$>$');
                
            if i=0 then do;
                col(i)=tranwrd(col(i), '%', '\%');
                col(i)=tranwrd(col(i), '&', '\&');
                col(i)=trim(left(col(i)))||'&';
            end;
            else do;
                col(i)=tranwrd(col(i),  '%)', '\%');
                col(i)=translate(col(i), '&& ', '(,)');
                if i=%_tail(%_tail(%bquote(&colorder), split=%str(,))) then col(i)=trim(left(col(i)))||'\\';
                else do;
                j=count(col(i), '&');
            %if "&outpct"="COL" | "&outpct"="NOROW" | "&outpct"="ROW" | "&outpct"="NOCOL" %then if j<2 then col(i)=trim(left(col(i)))||repeat('&', 1-j);  
            %else if j<3 then col(i)=trim(left(col(i)))||repeat('&', 2-j);;
            end;
            end;
        %end;
        put @(_ptr_) col(i) $char. @;
    
        _ptr_=_ptr_+_len(i)+_pad_;
    end;
    
    put;
    
    if last._var_ & linesleft>&foot0 then put %if &latex %then "\\\hline";;

    %if &latex %then %do;
        if eof then do;
            put "\end{tabular}";
            %*put "\end{center}";
            put "\end{document}";
        end;
    %end;
    
    call symput('pageno', trim(left(pageno)));
return;

header:
    %if &latex %then %do;
    if _n_=1 then do;
        put "\documentclass{article}";
        put "\begin{document}";
        %*put "\begin{center}";
        %if "&outpct"="COL" | "&outpct"="NOROW" | "&outpct"="ROW" | "&outpct"="NOCOL" %then
        put "\begin{tabular}{l%_repeat(r, 2*%_tail(%_tail(%bquote(&colorder), split=%str(,))))} \hline";
        %else
        put "\begin{tabular}{l%_repeat(r, 3*%_tail(%_tail(%bquote(&colorder), split=%str(,))))} \hline";;
    end;
    %end;
    %else if _n_>1 then put _page_;;

    %if %length(&by) & &latex=0 %then %do;
        %let h=0;
        
        %do i=1 %to &title0;
            %let j=%index(%qupcase(&&title&i), #BYVAL);
            
            %if &j %then %do;
                %let h=%eval(&h+1);
                %let arg1=%_substr(&&title&i, 1, &j-1);
                %let arg2=%_substr(&&title&i, &j+7);
                %*let k=%length(&&format&h);
                %*let arg2=%_substr(&&title&i, &j+6+&k+2);
                
                %*a formatted value cannot be reliably centered:  when the 
                  longest formatted value will not fit on the current line,
                  an unwanted new line is triggered, even when the current 
                  formatted value will fit (beware, this is not just a
                  problem with centering, any formatted output can trigger);
                
                put "&arg1 " &&var&h-l "&arg2 " 
            %end;
            %else put %_cj(&&title&i);
            
            %if &i=1 %then %do;
                %if %index(&options,NODATE)=0 %then %do;
                    %if %index(&options,NONUMBER)=0 %then 
                        @(_ls_-17) "&systime" @(_ls_-11) "&sysdate" @(_ls_-3) pageno 3.-r;
                    %else @(_ls_-13) "&systime" @(_ls_-7) "&sysdate";
                %end;
                %else %if %index(&options,NONUMBER)=0 %then @(_ls_-3) pageno 3.-r;
            %end;;
        %end;
    %end;
    
/*
    %if &page=1 %then if page>1 then;
        put %_cj((Continued));
*/
    %if &latex=0 %then if pageno>&pageno then put %_cj((Continued));;
    *else put;
    
    put;
    
    do k=1 to &headers;
        _ptr_=_pad_;
        
        do i=0, &colorder;
            %if &latex=1 %then %do;
                _tmp(i)=_head(i);
                if i=0 then _tmp(i)=trim(left(_tmp(i)))||'&'; 
                else if i=%_tail(%_tail(%bquote(&colorder), split=%str(,))) then
                _tmp(i)=trim(left(_tmp(i)))||'\\';
                else do;
                j=count(_tmp(i), '&');
            %if "&outpct"="COL" | "&outpct"="NOROW" | "&outpct"="ROW" | "&outpct"="NOCOL" %then if j<2 then _tmp(i)=trim(left(_tmp(i)))||repeat('&', 1-j);  
            %else if j<3 then _tmp(i)=trim(left(_tmp(i)))||repeat('&', 2-j);;
            end;
                put @(_ptr_+max(0, j)) _tmp(i) $char. @;
            %end;
            %else %do;
            _tmp(i)=scan(_head(i), k, "&split");
    
            if _tmp(i)^='' then do;
                j=floor((_len(i)-length(_tmp(i)))/2);
        
                %let j=%_tail(%bquote(&colorder), split=%str(,));
                %let j=%_tail(&j);
                %let i=%eval(%length(&&head&j)+2*&latex);
                %if &i=0 %then %let i=1;  
                        
                if i=&j then put @(_ptr_+max(0, j)) _tmp(&j) $char&i.. @;
                else put @(_ptr_+max(0, j)) _tmp(i) $char. @;
            end;
            %end;
            
            _ptr_=_ptr_+_len(i)+_pad_;
        end;   
            
        put;
    end;
    
    pageno+1;
return;
run;

    %_printto;    

    data _null_;
        retain pageno 2;
        %if &latex=1 %then infile "&filetex";
        %else infile "&file";;
        input @'0c'x;
        pageno+1;
        call symput('pageno', trim(left(pageno)));
    run;
    /*
    %sysexec which pandoc;
    %if &sysrc=0 %then 
        %sysexec pandoc -t html5 -o &fnhtml &file;
    */
%if "%_unwind(unix=UNIX)"="UNIX" %then %do;
%if &latex %then %do;
    %sysexec which tr > /dev/null;
    %if &sysrc=0 %then %do;
        %sysexec tr -d \\f < &filetex > &sysjobid..tex;
        %sysexec cp &sysjobid..tex &filetex;
    %sysexec which pdflatex > /dev/null;
    %if &sysrc=0 %then %do;
        %sysexec pdflatex &sysjobid..tex;
        %if &sysrc=0 %then %do;
        %sysexec mv &sysjobid..pdf &filepdf;
        %sysexec rm &sysjobid..log;
        %end;
        %sysexec rm -f &sysjobid..aux &sysjobid..tex;
    %end;
    %end;
%end;
%else %do;
    %sysexec which sed > /dev/null;
    %if &sysrc=0 %then %do;
        %sysexec echo "<pre><code>" > &filehtml;
        %sysexec sed -e 's/&/\&amp;/' &file | sed -e 's/</\&lt;/' | sed -e 's/>/\&gt;/' | tr -d '\014' >> &filehtml;
        %sysexec echo "</code></pre>" >> &filehtml;
    %end;
%end;
%end;
    
    %let syslast=&out;
%end;

%if %length(&log) %then %_printto;
%mend _summary;

%*VALIDATION TEST STREAM;
/* un-comment to re-validate
*/

