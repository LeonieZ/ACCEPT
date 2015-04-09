function actc_batch_analysis(varargin)
% Function that handles the batch analysis use cases. It should be
% called from the main function actc.m as it uses some globals which where
% previously set. 
global ACTC

%parse the imput arguments and start with the specified usecase
parse_arguments(varargin{:});

%Turn on profiler 
if ACTC.Program.profilerOn
        profile -memory on;
end

%Create sample list
[sampleList, outputList]=create_sample_list(ACTC);

keyboard
for i=1:numel(sampleList)
    Temp=preload_priors_and_imageList(sampleList(i));
    Results=run_analysis(Temp);
    ACTC.Program.saveResults(Results,sampleList(i),outputList(i));
end

%Turn of profiler and show results
if ACTC.Program.profilerOn
    profile off;
    profile viewer;
end
end

function parse_arguments(varargin)
global ACTC
%Function to define default input parameters. 
input=inputParser();

%Required: the use case
expectedUseCases={'FullAuto','SemiSupervised','QuantifyMarkerExpression'};
input.addRequired('useCase',@(a) any(validatestring(a,expectedUseCases)));

%parse input to get useCase and load defaults
parse(input,varargin{:});
ACTC.Program.loadUseCaseFunction(input.Results.useCase);

%optional parameters:
%input.addParameter('preprocessing_alpha',1);

%Optional arguments: input and output dir
input.addOptional('inputFolder',ACTC.Program.inputFolder,@(x) isdir(x));
input.addOptional('outputFolder',ACTC.Program.outputFolder,@(x) isdir(x));
input.addOptional('overwriteResults',ACTC.Program.overwriteResults,@(x)islogical(x))

input.addOptional('preProcessFunction',ACTC.Algorithm.preProcessFunction,@(x) isa(x,'function_handle'))
input.addOptional('segmentationFunction',ACTC.Algorithm.segmentationFunction,@(x) isa(x,'function_handle'))
input.addOptional('measurementFunction',ACTC.Algorithm.measurementFunction,@(x) isa(x,'function_handle'))
input.addOptional('classificationFunction',ACTC.Algorithm.classificationFunction,@(x) isa(x,'function_handle'))


%Parse input again and overwrite any changed variables. 
%(This solution is not elegant, feel free to improve \G) 
parse(input,varargin{:});
ACTC.Program.inputFolder=input.Results.inputFolder;
ACTC.Program.outputFolder=input.Results.outputFolder;
ACTC.Algorithm.preProcessFunction=input.Results.preProcessFunction;
ACTC.Algorithm.segmentationFunction=input.Results.segmentationFunction;
ACTC.Algorithm.measurementFunction=input.Results.measurementFunction;
ACTC.Algorithm.classificationFunction=input.Results.classificationFunction;


end

