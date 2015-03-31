function actc_batch_analysis(varargin)
% Function that handles the batch analysis use cases. It should be
% called from the main function actc.m as it uses some globals which where
% previously set. 
global ACTC

%parse the imput arguments and start with the specified usecase
parse_arguments(varargin{:});

%Create sample list
sampleList=create_sample_List(ACTC);

for i=1:numel(sampleList)
    imageList=preload_priors_and_imageList(sampleList(i));
    for j=1:numel(imageList)
        Results(j)=run_analysis(imageList(j),ACTC)
    end
    ACTC.Program.saveResults(Results,sampleList(i))
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
load_use_case(input.Results.useCase);

%optional parameters:
%input.addParameter('preprocessing_alpha',1);

%Optional arguments: input and output dir
input.addOptional('input_folder',ACTC.Program.input_folder,@(x) isdir(x));
input.addOptional('output_folder',ACTC.Program.output_folder,@(x) isdir(x));
input.addOptional('preProcessFunction',ACTC.Algorithm.preProcessFunction,@(x) isa(x,'function_handle'))
input.addOptional('segmentationFunction',ACTC.Algorithm.preProcessFunction,@(x) isa(x,'function_handle'))
input.addOptional('measurementFunction',ACTC.Algorithm.preProcessFunction,@(x) isa(x,'function_handle'))
input.addOptional('segmentationFunction',ACTC.Algorithm.preProcessFunction,@(x) isa(x,'function_handle'))


%Parse input again and overwrite any changed variables. 
%(This solution is not elegant, feel free to improve \G) 
parse(input,varargin{:});
ACTC.Program.input_folder=input.Results.input_folder;
ACTC.Program.output_folder=input.Results.output_folder;
ACTC.Algorithm.preProcessFunction=input.Results.preProcessFunction;
ACTC.Algorithm.segmentationFunction=input.Results.segmentationFunction;
ACTC.Algorithm.measurementFunction=input.Results.measurementFunction;
ACTC.Algorithm.segmentationFunction=input.Results.segmentationFunction;


end

