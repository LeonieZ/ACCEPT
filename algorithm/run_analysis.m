function Results=run_analysis(imageList,ACTC);
% This function excecutes all steps on the dataset. 

ACTC.Data.loadFunction=[];        
ACTC.Algorithm.preProcessFunction=[];
ACTC.Algorithm.segmentationFunction=[];
ACTC.Algorithm.measurementFunction=[];
ACTC.Algorithm.segmentationFunction=[];
ACTC.Program.saveResults=[];
ACTC.Program.guiFunction=[];


end