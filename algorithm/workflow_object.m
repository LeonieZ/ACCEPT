classdef workflow_object < handle
    %workflow_object is the base class for all steps in analysis.
    % Workflow_object provides the basic functions needed by all image
    % analysis stepps classes such as logging, interaction with the gui,
    % etc..  
    
    properties

      
    end
   
    methods
        function returnFrame = run(dataFrame)
            returnFrame=dataFrame;
        end
    end
end % classdef
