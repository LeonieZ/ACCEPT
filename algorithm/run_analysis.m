function Results=run_analysis(Temp);
% This function excecutes all steps on the dataset. 
global ACTC

if ACTC.Algoritm.twoStepSegmentation
    %first pass
    for i=1:numel(Temp.imageNames)
        ACTC.Algorithm.preProccessFunction
        ACTC.Algorithm.preSegmentationFunction
    end
    %Second pass
end
    for i=1:numel()
        ACTC.Data.loadFunction=[];
        ACTC.Algorithm.preProcessFunction=[];
        ACTC.Algorithm.segmentationFunction=[];
        ACTC.Algorithm.measurementFunction=[];
        ACTC.Algorithm.clasificationFunction=[];



end