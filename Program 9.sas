/* Set options for detailed logging */
options notes source source2 macrogen mprint mlogic symbolgen;

/* Importing the dataset */
proc import datafile="/home/u63930836/Andrew/Example_Anrew.xlsx"
    out=work.imported_data
    dbms=xlsx replace;
    getnames=yes;
run;

/* Data Preparation: Converting character variables to numeric, creating binary variables */
data analysis_data;
    set work.imported_data;

    /* Convert character variables 'Diabetes', 'Insulin resistance', and 'Mets_HD' to binary */
    Diabetes_bin = (Diabetes = 'Y');
    Insulin_resistance_bin = (strip(Insulin_resistance) = 'Y');
    Mets_HD_bin = (Mets_HD = 'Y');

    /* Convert numeric variables from character to numeric */
    BMI_num = input(BMI, best32.);
    HDL_num = input(HDL, best32.);
    LDL_num = input(LDL, best32.);
    Insulin_num = input(Insulin, best32.);

    /* Apply log transformation where applicable */
    if BMI_num > 0 then Log_BMI = log(BMI_num); else Log_BMI = .;
    if Insulin_num > 0 then Log_Insulin = log(Insulin_num); else Log_Insulin = .;
    if HDL_num > 0 then Log_HDL = log(HDL_num); else Log_HDL = .;
    if LDL_num > 0 then Log_LDL = log(LDL_num); else Log_LDL = .;

    /* Ensuring all transformations have no missing values for analysis */
    if BMI_num = . or HDL_num = . or LDL_num = . or Insulin_num = . then delete;
run;

/* Logistic Regression and ROC Analysis */
%macro regression_analysis(outcome=, label=);
    proc logistic data=analysis_data plots(only)=roc;
        model &outcome.(event='1') = Log_Insulin Log_HDL Log_LDL / lackfit;
        title "Logistic Regression for Predicting &label.";
        output out=log_&outcome. predicted=predicted_prob p=p;
    run;

    /* Generate ROC Curve */
    proc sgplot data=log_&outcome.;
        title "ROC Curve for &label. Prediction Model";
        roc x=p y=&outcome. / markerattrs=(symbol=CircleFilled color=blue) lineattrs=(color=red);
        rocanno / colormodel=(red);
    run;

    /* Compute AUC - Area Under the Curve */
    proc logistic data=analysis_data;
        model &outcome.(event='1') = Log_Insulin Log_HDL Log_LDL;
        ods select Association;
    run;
%mend;

/* Run analysis for each condition */
%regression_analysis(outcome=Diabetes_bin, label=Diabetes);
%regression_analysis(outcome=Insulin_resistance_bin, label=Insulin Resistance);
%regression_analysis(outcome=Mets_HD_bin, label=Metabolic Syndrome HD);
