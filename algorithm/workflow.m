classdef Workflow < handle
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
        function this=workflow(inputWorkflow)
            if nargin==1
                validateattributes(inputWorkflow,{'workflow'},{'nonempty'},'','inputWorkflow');
            end
            notify(this,'logMessage',logmessage(4,[this.name,' workflow is constructed.']));
            
            % therefore we need an io handler, e.g. for parallelization,
            % housekeeping etc.
            installDir = fileparts(which('ACCEPT.m'));
            this.io=io([installDir,filesep,'examples',filesep,'test_images'],...
                [installDir,filesep,'examples',filesep,'results',filesep,...
                this.workFlow.name,'_',this.workFlow.version]);
        end
        
        function run_workflow(this,currentSample)
            if isempty(this.algorithm)
                notify(this,'logMessage',logmessage(1,[this.name,'no results applied an empty workflow on sample.']));
            else
                for j=1:currentSample.nrOfFrames
                    data=this.io.loader.load_data_frame(j);
                    for i=1:numel(this.algorithm)
                        data=this.algorithm{i}.run(data);
                    end
                    currentSample.results.features=vertcat(currentSample.results.features,data.features);
                    currentSample.results.classefication=vertcat(currentSample.results.classefication,data.classificationResults);
                    currentSample.results.thumbnails=vertcat(currentSample.results.thumbnails,data.thumbnails);
                end
            end
        end
        
        function  set.algorithm(this,value)
            if any(cellfun(@(x) ~isa(x,'workflow_object'),value))
                error('cannot add non workflow_objects to algorithm')                
            end
            this.algorithm=value;
        end
     
    end
    
end

