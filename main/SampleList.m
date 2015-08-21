classdef SampleList < handle
    %SAMPLELIST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sampleProcessorId='empty'
        inputPath = '';
        resultPath = '';
        sampleNames = {}
        isProccessed = []
        isToBeProccessed = []
    end
        
    properties(Access={?IO})
        loaderToBeUsed = {}
    end
        
    events
        updatedPocessorId
        updatedInputPath
        updatedResultPath
    end
    
    methods
        
        
    end
    
end

