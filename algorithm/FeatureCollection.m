classdef FeatureCollection < SampleProcessorObject
    %FEATURECOLLECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       dataProcessor = DataframeProcessor();
       use_thumbs = 0;
       io
    end
    
    methods
        function this = FeatureCollection(inputDataframeProcessor,io,varargin)
            this.dataProcessor = inputDataframeProcessor;
            this.io = io;
            if nargin > 1
                this.use_thumbs = varargin{1};
            end
        end
        
        function returnSample = run(this, inputSample)
            returnSample = inputSample;
            
            if this.use_thumbs == 0
                for i = 1:inputSample.nrOfFrames
                    dataFrame = this.io.load_data_frame(inputSample,i);
                    this.dataProcessor.run(dataFrame);
                    inputSample.results.features=vertcat(inputSample.results.features, dataFrame.features);
                    %thumbnails,frameNr,coordinates,... missing
                end
            elseif this.use_thumbs == 1
                for i = 1:size(inputSample.priorLocations,1)
                    thumbFrame = this.io.load_thumbnail_frame(inputSample,i,'prior'); 
                    this.dataProcessor.run(thumbFrame);
                    thumbNr = array2table(i*(ones(size(thumbFrame.features,1),1)),'VariableNames',{'ThumbNr'});
                    thumbFrame.features = [thumbNr thumbFrame.features];
                    width(returnSample.results.features)
                    width(thumbFrame.features)
                    returnSample.results.features=vertcat(returnSample.results.features, thumbFrame.features);
                    returnSample.results.thumbnails=vertcat(returnSample.priorLocations);
                    returnSample.results.segmentation{i} = thumbFrame.segmentedImage;
                end
            end
        end
        
    end
    
end

