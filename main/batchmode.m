classdef batchmode < ui
    %BATCHMODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        input=inputParser(); %inputParser() handle
        useCase;
    end
    
    methods
        function self=batchmode(varargin)
            %Build valid options for inputParser
            self.input=self.build_valid_input_arguments();
            %Parse input en set values. 
            parse(self.input,varargin{:});
            self.useCase=self.input.Results.useCase;
            self.ioHandle.samplesPath=self.input.Results.inputFolder;
            self.ioHandle.savePath=self.input.Results.outputFolder;
            self.ioHandle.overwriteResults=self.input.Results.overwriteResults;
            keyboard
        end

        function input=build_valid_input_arguments(self)
            %Required: the use case
            input=inputParser;
            expectedUseCases={'FullAuto','SemiSupervised','QuantifyMarkerExpression'};
            input.FunctionName='batchmode input parser';
            input.addRequired('useCase',@(a) any(validatestring(a,expectedUseCases)));
            %Optional: io atributes, defaults set to io defaults.
            input.addOptional('inputFolder',self.ioHandle.samplesPath,@(x) isdir(x));
            input.addOptional('outputFolder',self.ioHandle.savePath,@(x) isdir(x));
            input.addOptional('overwriteResults',self.ioHandle.overwriteResults,@(x)islogical(x))
            %additional inputs can be added:

        end
    end
    
end

