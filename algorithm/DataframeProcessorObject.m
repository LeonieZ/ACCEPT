classdef DataframeProcessorObject < handle
    % DataframeProcessorObject is the base class for all steps in dataframe analysis.
    % DataframeProcessorObject provides the basic functions needed by all image
    % analysis steps classes such as logging, interaction with the gui,
    % etc..  
    
    properties

      
    end
    
    events
        logMessage
    end
   
    methods
        function returnFrame = run(this,dataFrame)
            returnFrame.name=dataFrame.name;
        end
    end
end % classdef
