classdef workflow < handle
    %WORKFLOW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        loopResults={};
        algorithm=cell(0);
    end
    
    methods
        function obj=workflow(savedWorkflow)
            if isa(savedWorkflow,'workflow_object')
                obj.algorithm=savedWorkflow;
            else
                %give error message
                
            end
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
        
        function  add_workflow_object(self,object)
            if ~isa(object,'workflow_object')
                error('cannot add non workflow_objects to algorithm')                
            end
            self.algorithm{end+1}=object;
        end
        
    end
    
end

