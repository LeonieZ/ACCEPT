function load_use_case(useCase)
%Helper function to load default algorithm parameters for each use case to the global.

global ACTC
ACTC.Program.useCase=input.Results.useCase;
switch useCase
    case 'FullAuto'
        ACTC.Algorithm.preProcessFunction=[];
        ACTC.Algorithm.segmentationFunction=[];
        ACTC.Algorithm.measurementFunction=[];
        ACTC.Algorithm.segmentationFunction=[];
    case 'SemiSupervised'
        ACTC.Algorithm.preProcessFunction=[];
        ACTC.Algorithm.segmentationFunction=[];
        ACTC.Algorithm.measurementFunction=[];
        ACTC.Algorithm.segmentationFunction=[];
    case 'QuantifyMarkerExpression'
        ACTC.Algorithm.preProcessFunction=[];
        ACTC.Algorithm.segmentationFunction=[];
        ACTC.Algorithm.measurementFunction=[];
        ACTC.Algorithm.segmentationFunction=[];
end

end