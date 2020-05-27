* Encoding: UTF-8.
* Encoding:     UTF-8.

DATASET ACTIVATE DataSet2.
RECODE sex ('female'=1) ('male'=0) INTO gender.
EXECUTE.

VARSTOCASES
  /MAKE pain_over_time FROM pain1 pain2 pain3 pain4
  /INDEX=time(4) 
  /KEEP=ID gender age STAI_trait pain_cat cortisol_serum cortisol_saliva mindfulness weight IQ 
    household_income 
  /NULL=KEEP.

MIXED pain_over_time WITH gender age STAI_trait pain_cat cortisol_serum mindfulness time
  /CRITERIA=CIN(95) MXITER(100) MXSTEP(10) SCORING(1) SINGULAR(0.000000000001) HCONVERGE(0, 
    ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)
  /FIXED=gender age STAI_trait pain_cat cortisol_serum mindfulness time | SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT | SUBJECT(ID) COVTYPE(VC)
  /SAVE=PRED.

MIXED pain_over_time WITH gender age STAI_trait pain_cat cortisol_serum mindfulness time
  /CRITERIA=CIN(95) MXITER(100) MXSTEP(10) SCORING(1) SINGULAR(0.000000000001) HCONVERGE(0, 
    ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)
  /FIXED=gender age STAI_trait pain_cat cortisol_serum mindfulness time | SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT time | SUBJECT(ID) COVTYPE(UN)
  /SAVE=PRED.

VARSTOCASES
  /MAKE pain_pred_int_slope FROM pain_over_time pred_intercept pred_slope
  /INDEX=obs_or_pred(pain_pred_int_slope) 
  /KEEP=ID gender age STAI_trait pain_cat cortisol_serum cortisol_saliva mindfulness weight IQ 
    household_income time 
  /NULL=KEEP.

SORT CASES  BY ID.
SPLIT FILE SEPARATE BY ID.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=time pain_pred_int_slope obs_or_pred MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: time=col(source(s), name("time"), unit.category())
  DATA: pain_pred_int_slope=col(source(s), name("pain_pred_int_slope"), unit.category())
  DATA: obs_or_pred=col(source(s), name("obs_or_pred"), unit.category())
  GUIDE: axis(dim(1), label("time"))
  GUIDE: axis(dim(2), label("pain_pred_int_slope"))
  GUIDE: legend(aesthetic(aesthetic.color.interior), label("obs_or_pred"))
  GUIDE: text.title(label("Multiple Line of pain_pred_int_slope by time by obs_or_pred"))
  ELEMENT: line(position(time*pain_pred_int_slope), color.interior(obs_or_pred), missing.wings())
END GPL.

SPLIT FILE OFF.

DESCRIPTIVES VARIABLES=time
/STATISTICS=MEAN STDDEV MIN MAX.

COMPUTE time_centered=time-2.5.
EXECUTE.

COMPUTE time_centered_sq=time_centered*time_centered.
EXECUTE.


DATASET ACTIVATE DataSet11.
MIXED pain_over_time_copy WITH gender age STAI_trait pain_cat cortisol_serum mindfulness 
    time_centered time_centered_sq
  /CRITERIA=CIN(95) MXITER(100) MXSTEP(10) SCORING(1) SINGULAR(0.000000000001) HCONVERGE(0, 
    ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)
  /FIXED=gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered time_centered_sq | 
    SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT time_centered time_centered_sq | SUBJECT(ID) COVTYPE(UN)
  /SAVE=PRED.


VARSTOCASES
  /MAKE all_predictions FROM pain_over_time_copy pred_intercept_copy pred_slope_copy 
    pred_slope_timesq_copy
  /INDEX=pain_int_slope_timesq(all_predictions) 
  /KEEP=ID gender age STAI_trait pain_cat cortisol_serum cortisol_saliva mindfulness weight IQ 
    household_income Index1 time_int_slope time time_centered time_centered_sq 
  /NULL=KEEP.


DATASET ACTIVATE DataSet10.
SORT CASES  BY ID.
SPLIT FILE SEPARATE BY ID.


* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=time 
    MEAN(all_predictions)[name="MEAN_all_predictions"] pain_int_slope_timesq MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: time=col(source(s), name("time"), unit.category())
  DATA: MEAN_all_predictions=col(source(s), name("MEAN_all_predictions"))
  DATA: pain_int_slope_timesq=col(source(s), name("pain_int_slope_timesq"), unit.category())
  GUIDE: axis(dim(1), label("time"))
  GUIDE: axis(dim(2), label("Mean all_predictions"))
  GUIDE: legend(aesthetic(aesthetic.color.interior), label("pain_int_slope_timesq"))
  GUIDE: text.title(label("Multiple Line Mean of all_predictions by time by pain_int_slope_timesq"))    
  SCALE: linear(dim(2), include(0))
  ELEMENT: line(position(time*MEAN_all_predictions), color.interior(pain_int_slope_timesq), 
    missing.wings())
END GPL.

*Model diagnostics
*Influential outliers: first selecting only the reported pain variable and then producing graphs

DATASET ACTIVATE DataSet1.
RECODE pain_int_slope_timesq ('pain_over_time_copy'=1) ('pred_intercept_copy'=2) 
    ('pred_slope_copy'=3) ('pred_slope_timesq_copy'=4) INTO labels.
EXECUTE.

USE ALL.
COMPUTE filter_$=(labels = 1).
VARIABLE LABELS filter_$ 'labels = 1 (FILTER)'.
VALUE LABELS filter_$ 0 'Not Selected' 1 'Selected'.
FORMATS filter_$ (f1.0).
FILTER BY filter_$.
EXECUTE.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=time 
    MEAN(all_predictions)[name="MEAN_all_predictions"] ID MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: time=col(source(s), name("time"), unit.category())
  DATA: MEAN_all_predictions=col(source(s), name("MEAN_all_predictions"))
  DATA: ID=col(source(s), name("ID"), unit.category())
  GUIDE: axis(dim(1), label("time"))
  GUIDE: axis(dim(2), label("Mean all_predictions"))
  GUIDE: legend(aesthetic(aesthetic.color.interior), label("ID"))
  GUIDE: text.title(label("Multiple Line Mean of all_predictions by time by ID"))
  SCALE: linear(dim(2), include(0))
  ELEMENT: line(position(time*MEAN_all_predictions), color.interior(ID), missing.wings())
END GPL.

EXAMINE VARIABLES=all_predictions BY ID
  /PLOT BOXPLOT STEMLEAF
  /COMPARE GROUPS
  /STATISTICS NONE
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

*Normality assumption

FILTER OFF.
USE ALL.
EXECUTE.

MIXED all_predictions WITH gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered 
    time_centered_sq
  /CRITERIA=CIN(95) MXITER(100) MXSTEP(10) SCORING(1) SINGULAR(0.000000000001) HCONVERGE(0, 
    ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)
  /FIXED=gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered time_centered_sq | 
    SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT time_centered time_centered_sq | SUBJECT(ID) COVTYPE(UN)
  /SAVE=RESID.

EXAMINE VARIABLES=RESID_1
  /PLOT BOXPLOT STEMLEAF HISTOGRAM NPPLOT
  /COMPARE GROUPS
  /STATISTICS NONE
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

EXAMINE VARIABLES=RESID_1
  /PLOT NONE
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

*Linearity

MIXED all_predictions WITH gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered 
    time_centered_sq
  /CRITERIA=CIN(95) MXITER(100) MXSTEP(10) SCORING(1) SINGULAR(0.000000000001) HCONVERGE(0, 
    ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)
  /FIXED=gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered time_centered_sq | 
    SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT time_centered time_centered_sq | SUBJECT(ID) COVTYPE(UN)
  /SAVE=PRED.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=PRED_1 RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: PRED_1=col(source(s), name("PRED_1"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("Predicted Values"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by Predicted Values"))
  ELEMENT: point(position(PRED_1*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=age RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: age=col(source(s), name("age"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("age"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by age"))
  ELEMENT: point(position(age*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=gender RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: gender=col(source(s), name("gender"), unit.category())
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("gender"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by gender"))
  SCALE: cat(dim(1), include("0", "1"))
  SCALE: linear(dim(2), include(0))
  ELEMENT: point(position(gender*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=STAI_trait RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: STAI_trait=col(source(s), name("STAI_trait"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("STAI_trait"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by STAI_trait"))
  ELEMENT: point(position(STAI_trait*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=pain_cat RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: pain_cat=col(source(s), name("pain_cat"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("pain_cat"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by pain_cat"))
  ELEMENT: point(position(pain_cat*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=cortisol_serum RESID_1 MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: cortisol_serum=col(source(s), name("cortisol_serum"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("cortisol_serum"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by cortisol_serum"))
  ELEMENT: point(position(cortisol_serum*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=mindfulness RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: mindfulness=col(source(s), name("mindfulness"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("mindfulness"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by mindfulness"))
  ELEMENT: point(position(mindfulness*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=time_centered RESID_1 MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: time_centered=col(source(s), name("time_centered"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("time_centered"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by time_centered"))
  ELEMENT: point(position(time_centered*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=time_centered_sq RESID_1 MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: time_centered_sq=col(source(s), name("time_centered_sq"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("time_centered_sq"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by time_centered_sq"))
  ELEMENT: point(position(time_centered_sq*RESID_1))
END GPL.

*Homogeneity of variance

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=PRED_1 RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: PRED_1=col(source(s), name("PRED_1"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("Predicted Values"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by Predicted Values"))
  ELEMENT: point(position(PRED_1*RESID_1))
END GPL.

*Multicollinearity diagnostics

CORRELATIONS
  /VARIABLES=gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered 
    time_centered_sq
  /PRINT=TWOTAIL SIG
  /MISSING=PAIRWISE.

*Constant variance of residuals across clusters

COMPUTE resid_square=RESID_1 * RESID_1.
EXECUTE.

SPSSINC CREATE DUMMIES VARIABLE=ID 
ROOTNAME1=id 
/OPTIONS ORDER=A USEVALUELABELS=YES USEML=YES OMITFIRST=NO.

REGRESSION
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS R ANOVA
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT resid_square
  /METHOD=ENTER id_2 id_3 id_4 id_5 id_6 id_7 id_8 id_9 id_10 id_11 id_12 id_13 id_14 id_15 id_16 
    id_17 id_18 id_19 id_20.

* Normal distribution of the random effects

MIXED all_predictions WITH gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered 
    time_centered_sq
  /CRITERIA=CIN(95) MXITER(100) MXSTEP(10) SCORING(1) SINGULAR(0.000000000001) HCONVERGE(0, 
    ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)
  /FIXED=gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered time_centered_sq | 
    SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT time_centered time_centered_sq | SUBJECT(ID) COVTYPE(UN) SOLUTION
  /SAVE=PRED.

EXAMINE VARIABLES=random_effects
  /PLOT NONE
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

* Dependency structure of the random effects

MIXED all_predictions WITH gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered 
    time_centered_sq
  /CRITERIA=CIN(95) MXITER(100) MXSTEP(10) SCORING(1) SINGULAR(0.000000000001) HCONVERGE(0, 
    ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)
  /FIXED=gender age STAI_trait pain_cat cortisol_serum mindfulness time_centered time_centered_sq | 
    SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT time_centered time_centered_sq | SUBJECT(ID) COVTYPE(UN)
  /SAVE=PRED.

*END
