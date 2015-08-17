classdef workflow < handle
    %WORKFLOW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='Empty'
        version='0.1'
        algorithm=cell(0);
        io;
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
            
            % therefore we need an io handler, e.g. for parallelization,
            % housekeeping etc.
            installDir = fileparts(which('ACCEPT.m'));
            self.io=io([installDir,filesep,'examples',filesep,'test_images'],...
                [installDir,filesep,'examples',filesep,'results',filesep,...
                self.workFlow.name,'_',self.workFlow.version]);
        end
        
        function run_workflow(self,IO,currentSample)
            if isempty(self.algorithm)
                notify(self,'logMessage',logmessage(1,[self.name,'no results applied an empty workflow on sample.']));
            else
                for j=1:currentSample.nrOfFrames
                    data=IO.loader.load_data_frame(j);
                    for i=1:numel(self.algorithm)
                        data=self.algorithm{i}.run(data);
                    end
                    currentSample.results.features=vertcat(currentSample.results.features,data.features);
                    currentSample.results.classefication=vertcat(currentSample.results.classefication,data.classificationResults);
                    currentSample.results.thumbnails=vertcat(currentSample.results.thumbnails,data.thumbnails);
                end
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

