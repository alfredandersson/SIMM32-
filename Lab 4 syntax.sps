* Encoding: UTF-8.

*Estimating a mixed model

DATASET ACTIVATE DataSet1.
MIXED pain WITH gender age STAI_trait pain_cat mindfulness cortisol_serum
  /CRITERIA=CIN(95) MXITER(100) MXSTEP(10) SCORING(1) SINGULAR(0.000000000001) HCONVERGE(0, 
    ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)
  /FIXED=gender age STAI_trait pain_cat mindfulness cortisol_serum | SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT | SUBJECT(hospital) COVTYPE(VC)
  /SAVE=FIXPRED.

*Checking the variance for the fixed effect

DESCRIPTIVES VARIABLES=FXPRED_1
  /STATISTICS=MEAN STDDEV VARIANCE MIN MAX.

*Applying the regression equation on dataset B

DATASET ACTIVATE DataSet3.
COMPUTE predicted_value_B=3.8 + (0.298 * gender) + (-0.054 * age) + (0.001 * STAI_trait) + (0.037 * 
    pain_cat) + (-0.262 * mindfulness) + (0.610 * cortisol_serum).
EXECUTE.

*Conducting linear regression with the new variable in dataset B to retrieve R2 value

REGRESSION
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS R ANOVA
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT pain
  /METHOD=ENTER predicted_value_B.
