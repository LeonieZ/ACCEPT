classdef SampleProcessorObject < handle
    % SampleProcessorObject is the base class for all steps in sample analysis.  
    
    properties  
    end
    
    events
        logMessage
    end
   
    methods (Abstract)
        run(this, sample) %every SampleProcessorObject needs a run function that acts on a sample
    end
end 
