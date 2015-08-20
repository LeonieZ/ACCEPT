classdef Batchmode < Base
    %BATCHMODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        input; %inputParser() handle
        useCase;
    end
    
    methods
        function this=batchmode(varargin)
            %Build valid options for inputParser
            this.build_valid_input_arguments();
            %Parse input en set values. 
            parse(this.input,varargin{:});
            this.useCase=this.input.Results.useCase;
            this.workflow.io.samplesPath=this.input.Results.inputFolder;
            this.workflow.io.savePath=this.input.Results.outputFolder;
            this.workflow.io.overwriteResults=this.input.Results.overwriteResults;
            this.run_use_case;
        end

        function build_valid_input_arguments(this)
            %Required: the use case
            this.input=inputParser;
            expectedUseCases={'createThumbnails','CLI'};
            this.input.FunctionName='batchmode input parser';
            this.input.addRequired('useCase',@(a) any(validatestring(a,expectedUseCases)));
            %Optional: io atributes, defaults set to io defaults.
            this.input.addOptional('inputFolder',this.io.samplesPath,@(x) isdir(x));
            this.input.addOptional('outputFolder',this.io.savePath,@(x) isdir(x));
            this.input.addOptional('overwriteResults',this.io.overwriteResults,@(x)islogical(x))
            %additional inputs can be added:
        end
        
        function run_use_case(this)
            switch this.useCase
                case 'createThumbnails'
                    
                case 'CLI'

                otherwise
                
            end

        end
    end
    
end

