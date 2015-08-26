classdef SampleProcessor < handle
    %SAMPLEPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='Empty'
        version='0.1'
        dataframeProcessor;
        pipeline=cell(0);
        io;
    end
    
    events
        logMessage
    end
    
    methods
%         function this=SampleProcessor(inputIO,inputSampleProcessor)
%             if nargin==2
%                 validateattributes(inputSampleProcessor,{'SampleProcessor'},{'nonempty'},'','inputSampleProcessor');
%                 this=inputSampleProcessor;
%             end
%                         
%             % therefore we need an io handler, e.g. for parallelization,
%             % housekeeping etc.
%             this.io=inputIO;
%         end
        
        function outputStr=id(this)
            outputStr=[this.name,'_',this.version];
        end
      
        
        function run(this,inputSample)
            if isempty(this.dataframeProcessor)
                inputSample.sampleId
                %notify(this,'logMessage',logmessage(1,[this.name,'no results, applied an empty workflow on sample.']));
            else
%                 for j=1:inputSample.nrOfFrames
%                     data=this.io.loader.load_data_frame(j);
%                     for i=1:numel(this.algorithm)
%                         data=this.algorithm{i}.run(data);
%                     end
%                     inputSample.results.features=vertcat(inputSample.results.features,data.features);
%                     inputSample.results.classification=vertcat(inputSample.results.classification,data.classificationResults);
%                     inputSample.results.thumbnails=vertcat(inputSample.results.thumbnails,data.thumbnails);
%                 end
            end
        end
        
        function  set.pipeline(this,value)
            if any(cellfun(@(x) ~isa(x,'SampleProcessorObject'),value))
                error('cannot add non workflow_objects to algorithm')                
            end
            this.pipeline=value;
        end
        
        
     
    end
    
end

