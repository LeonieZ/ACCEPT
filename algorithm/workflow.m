classdef workflow < handle
    %WORKFLOW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='Empty'
        version='0.1'
        algorithm=cell(0);
    end
    
    events
        logMessage
    end
    
    methods
        function self=workflow(inputWorkflow)
            if nargin==1
                validateattributes(inputWorkflow,{'workflow'},{'nonempty'},'','inputWorkflow');
            end
            notify(self,'logMessage',logmessage(4,[self.name,' workflow is constructed.']));
        end
        
        function returnFrame=run_workflow(self,data)
            if isempty(self.algorithm)
                %some kind of logging
            else
            for i=1:numel(self.algorithm)
                data=self.algorithm{i}.run(data);
            end
            returnFrame=data;
            end
        end
        
        function  set.algorithm(self,value)
            if any(cellfun(@(x) ~isa(x,'workflow_object'),value))
                error('cannot add non workflow_objects to algorithm')                
            end
            self.algorithm=value;
        end
     
    end
    
end

