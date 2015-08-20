classdef SampleProcessor < handle
    %WORKFLOW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='Empty'
        version='0.1'
        imageProcessor;
        pipeline=cell(0);
        io;
    end
    
    events
        logMessage
    end
    
    methods
        function this=workflow(inputIO,inputSampleProcessor)
            if nargin==2
                validateattributes(inputSampleProcessor,{'SampleProcessor'},{'nonempty'},'','inputSampleProcessor');
                this=inputSampleProcessor;
            end
                        
            % therefore we need an io handler, e.g. for parallelization,
            % housekeeping etc.
            this.io=inputIO;
        end
        
        function run_workflow(this,inputSample)
            if isempty(this.imageProcessor)
                notify(this,'logMessage',logmessage(1,[this.name,'no results, applied an empty workflow on sample.']));
            else
                for j=1:inputSample.nrOfFrames
                    data=this.io.loader.load_data_frame(j);
                    for i=1:numel(this.algorithm)
                        data=this.algorithm{i}.run(data);
                    end
                    inputSample.results.features=vertcat(inputSample.results.features,data.features);
                    inputSample.results.classefication=vertcat(inputSample.results.classefication,data.classificationResults);
                    inputSample.results.thumbnails=vertcat(inputSample.results.thumbnails,data.thumbnails);
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

