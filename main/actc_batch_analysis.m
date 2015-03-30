function actc_batch_analysis(varargin)
% Function that handles the batch analysis use cases. It should be
% called from the main function actc.m as it uses some globals which where
% previously set. 
global ACTC

%parse the imput arguments and start with the specified usecase
parse_arguments(varargin{:});
switch ACTC.Program.useCase
    case 'FullAuto'

    case 'SemiSupervised'
    
    case 'QuantifyMarkerExpression'
        
end
end

function parameters = parse_arguments(varargin)
global ACTC
%Function to define default input parameters. 
input=inputParser();

%Required: the use case
expectedUseCases={'FullAuto','SemiSupervised','QuantifyMarkerExpression'};
input.addRequired('useCase',@(a) any(validatestring(a,expectedUseCases)));

%Optional arguments: input and output dir
input.addOptional('input_folder',ACTC.Program.input_folder,@(x) isdir(x));
input.addOptional('output_folder',ACTC.Program.output_folder,@(x) isdir(x));

%optional parameters:
input.addParameter('preprocessing_alpha',1);

%Parse input and store variables
parse(input,varargin{:});
ACTC.Program.useCase=input.Results.useCase;
ACTC.Program.input_folder=input.Results.input_folder;
ACTC.Program.output_folder=input.Results.output_folder;

end