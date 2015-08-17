classdef WorkflowObject < handle
    %workflow_object is the base class for all steps in analysis.
    % Workflow_object provides the basic functions needed by all image
    % analysis steps classes such as logging, interaction with the gui,
    % etc..  
    
    properties

      
    end
    
    events
        logMessage
    end
   
    methods
        function returnFrame = run(this,dataFrame)
            returnFrame=dataFrame;
        end
    end
end % classdef
