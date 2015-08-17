classdef batchmode < base
    %BATCHMODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        input; %inputParser() handle
        useCase;
    end
    
    methods
        function self=batchmode(varargin)
            %Build valid options for inputParser
            self.build_valid_input_arguments();
            %Parse input en set values. 
            parse(self.input,varargin{:});
            self.useCase=self.input.Results.useCase;
            self.workflow.io.samplesPath=self.input.Results.inputFolder;
            self.io.savePath=self.input.Results.outputFolder;
            self.io.overwriteResults=self.input.Results.overwriteResults;
            self.run_use_case;
        end

        function build_valid_input_arguments(self)
            %Required: the use case
            self.input=inputParser;
            expectedUseCases={'createThumbnails','CLI'};
            self.input.FunctionName='batchmode input parser';
            self.input.addRequired('useCase',@(a) any(validatestring(a,expectedUseCases)));
            %Optional: io atributes, defaults set to io defaults.
            self.input.addOptional('inputFolder',self.io.samplesPath,@(x) isdir(x));
            self.input.addOptional('outputFolder',self.io.savePath,@(x) isdir(x));
            self.input.addOptional('overwriteResults',self.io.overwriteResults,@(x)islogical(x))
            %additional inputs can be added:
        end
        
        function run_use_case(self)
            switch self.useCase
                case 'createThumbnails'
                    
                case 'CLI'

                otherwise
                
            end

        end
    end
    
end

