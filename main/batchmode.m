classdef batchmode < ui
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
            self.ioHandle.samplesPath=self.input.Results.inputFolder;
            self.ioHandle.savePath=self.input.Results.outputFolder;
            self.ioHandle.overwriteResults=self.input.Results.overwriteResults;
            keyboard
        end

        function build_valid_input_arguments(self)
            %Required: the use case
            self.input=inputParser;
            expectedUseCases={'FullAuto','SemiSupervised','QuantifyMarkerExpression'};
            self.input.FunctionName='batchmode input parser';
            self.input.addRequired('useCase',@(a) any(validatestring(a,expectedUseCases)));
            %Optional: io atributes, defaults set to io defaults.
            self.input.addOptional('inputFolder',self.ioHandle.samplesPath,@(x) isdir(x));
            self.input.addOptional('outputFolder',self.ioHandle.savePath,@(x) isdir(x));
            self.input.addOptional('overwriteResults',self.ioHandle.overwriteResults,@(x)islogical(x))
            %additional inputs can be added:

        end
    end
    
end

