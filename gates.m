% gates
% Standard gates for classification of measured events in cartridge 
GatesVersion=25;

% % %AR Mean intensity for creating an intensity classification based on quantiles of AR mean of patients.
% % ARgateP1=   25;
% % ARgateP2=   45;
% % ARgateP3=   71;
% % ARgateP4=  118; 
% % ARgateP5= 4095;
% % 
% % ARRatioP1=1;
% % ARRatioP2=1.50;
% % ARRatioP3=1.94;
% % ARRatioP4=2.50;
% % ARRatioP5=Inf;

Breast{1,1} = 'PEStdDev';
Breast{1,2} = 'lower';
Breast{1,3} = 50;
Breast{2,1} = 'PESize';
Breast{2,2} = 'lower';
Breast{2,3} = 75;
Breast{3,1} = 'PESize';
Breast{3,2} = 'upper';
Breast{3,3} = 2000;
Breast{4,1} = 'DAPIMaxval';
Breast{4,2} = 'lower';
Breast{4,3} = 170;
Breast{5,1} = 'APCMaxval';
Breast{5,2} = 'upper';
Breast{5,3} = 60;

Prostate{1,1} = 'PEStdDev';
Prostate{1,2} = 'lower';
Prostate{1,3} = 50;
Prostate{2,1} = 'PESize';
Prostate{2,2} = 'lower';
Prostate{2,3} = 75;
Prostate{3,1} = 'PESize';
Prostate{3,2} = 'upper';
Prostate{3,3} = 500;
Prostate{4,1} = 'DAPIMaxval';
Prostate{4,2} = 'lower';
Prostate{4,3} = 170;
Prostate{5,1} = 'APCMaxval';
Prostate{5,2} = 'upper';
Prostate{5,3} = 60;

Cellline{1,1} = 'PEMaxval';
Cellline{1,2} = 'lower';
Cellline{1,3} = 400;
Cellline{2,1} = 'PESize';
Cellline{2,2} = 'lower';
Cellline{2,3} = 75;
Cellline{3,1} = 'PESize';
Cellline{3,2} = 'upper';
Cellline{3,3} = 10000;
Cellline{4,1} = 'DAPIMaxval';
Cellline{4,2} = 'lower';
Cellline{4,3} = 170;
Cellline{5,1} = 'APCMaxval';
Cellline{5,2} = 'upper';
Cellline{5,3} = 200;

WBC{1,1} = 'PEStdDev';
WBC{1,2} = 'upper';
WBC{1,3} = 50;
WBC{2,1} = 'DAPISize';
WBC{2,2} = 'lower';
WBC{2,3} = 50;
WBC{3,1} = 'DAPISize';
WBC{3,2} = 'upper';
WBC{3,3} = 1000;
WBC{4,1} = 'DAPIMaxval';
WBC{4,2} = 'lower';
WBC{4,3} = 170;
WBC{5,1} = 'APCMaxval';
WBC{5,2} = 'lower';
WBC{5,3} = 100;
WBC{6,1} = 'DAPIP2A';
WBC{6,2} = 'upper';
WBC{6,3} = 1.5;

%ck+cd45+
CKCD45{1,1} = 'PEStdDev';
CKCD45{1,2} = 'lower';
CKCD45{1,3} = 50;
CKCD45{2,1} = 'DAPISize';
CKCD45{2,2} = 'lower';
CKCD45{2,3} = 50;
CKCD45{3,1} = 'DAPISize';
CKCD45{3,2} = 'upper';
CKCD45{3,3} = 1000;
CKCD45{4,1} = 'DAPIMaxval';
CKCD45{4,2} = 'lower';
CKCD45{4,3} = 170;
CKCD45{5,1} = 'APCMaxval';
CKCD45{5,2} = 'lower';
CKCD45{5,3} = 100;
CKCD45{6,1} = 'DAPIP2A';
CKCD45{6,2} = 'upper';
CKCD45{6,3} = 1.5;

%ck-
Nucleus{1,1} = 'PEStdDev';
Nucleus{1,2} = 'upper';
Nucleus{1,3} = 50;
Nucleus{2,1} = 'DAPISize';
Nucleus{2,2} = 'lower';
Nucleus{2,3} = 50;
Nucleus{3,1} = 'DAPISize';
Nucleus{3,2} = 'upper';
Nucleus{3,3} = 1000;
Nucleus{4,1} = 'DAPIMaxval';
Nucleus{4,2} = 'lower';
Nucleus{4,3} = 170;
% Nucleus{5,1} = 'apcMaxval';
% Nucleus{5,2} = 'upper';
% Nucleus{5,3} = 100;
Nucleus{5,1} = 'DAPIP2A';
Nucleus{5,2} = 'upper';
Nucleus{5,3} = 1.5;

ONLYFITC{1,1} = 'PEStdDev';
ONLYFITC{1,2} = 'upper';
ONLYFITC{1,3} = 50;
ONLYFITC{2,1} = 'DAPISize';
ONLYFITC{2,2} = 'lower';
ONLYFITC{2,3} = 50;
ONLYFITC{3,1} = 'DAPISize';
ONLYFITC{3,2} = 'upper';
ONLYFITC{3,3} = 1000;
ONLYFITC{4,1} = 'DAPIMaxval';
ONLYFITC{4,2} = 'lower';
ONLYFITC{4,3} = 170;
ONLYFITC{5,1} = 'EXTRAMean';
ONLYFITC{5,2} = 'lower';
ONLYFITC{5,3} = 25;
ONLYFITC{6,1} = 'DAPIP2A';
ONLYFITC{6,2} = 'upper';
ONLYFITC{6,3} = 1.5;
ONLYFITC{7,1} = 'APCMaxval';
ONLYFITC{7,2} = 'upper';
ONLYFITC{7,3} = 60;

ONLYFITC2{1,1} = 'PEStdDev';
ONLYFITC2{1,2} = 'upper';
ONLYFITC2{1,3} = 50;
ONLYFITC2{2,1} = 'DAPISize';
ONLYFITC2{2,2} = 'lower';
ONLYFITC2{2,3} = 50;
ONLYFITC2{3,1} = 'DAPISize';
ONLYFITC2{3,2} = 'upper';
ONLYFITC2{3,3} = 1000;
ONLYFITC2{4,1} = 'DAPIMaxval';
ONLYFITC2{4,2} = 'lower';
ONLYFITC2{4,3} = 170;
ONLYFITC2{5,1} = 'EXTRAMean';
ONLYFITC2{5,2} = 'lower';
ONLYFITC2{5,3} = 25;
ONLYFITC2{6,1} = 'DAPIP2A';
ONLYFITC2{6,2} = 'upper';
ONLYFITC2{6,3} = 1.5;
ONLYFITC2{7,1} = 'APCMaxval';
ONLYFITC2{7,2} = 'upper';
ONLYFITC2{7,3} = 60;
ONLYFITC2{8,1} = 'PEStdDev';
ONLYFITC2{8,2} = 'lower';
ONLYFITC2{8,3} = 15;






