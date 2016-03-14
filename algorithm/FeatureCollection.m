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
            if nargin > 2
                this.use_thumbs = varargin{1};
            end
        end
        
        function returnSample = run(this, inputSample)
            returnSample = inputSample;
            
            if this.use_thumbs == 0
                for i = 1:inputSample.nrOfFrames
                    dataFrame = this.io.load_data_frame(inputSample,i);
                    this.dataProcessor.run(dataFrame);
                    objectsfoundearlier = size(inputSample.results.features,1);
                    objectsfound = size(dataFrame.features,1);
                    if objectsfound > 0
                        thumbNr = array2table(linspace(objectsfoundearlier+1,objectsfoundearlier+size(dataFrame.features,1),...
                            size(dataFrame.features,1))','VariableNames',{'ThumbNr'});
                        dataFrame.features = [thumbNr dataFrame.features]; %maybe change like below?!
                        inputSample.results.features=vertcat(inputSample.results.features, dataFrame.features);
                        bb = struct2cell(regionprops(dataFrame.labelImage,'BoundingBox'));
%                         xBottomLeft = cellfun(@(x) max(floor(x(2)) - round(0.2*x(5)),1),bb);
%                         yBottomLeft = cellfun(@(x) max(floor(x(1)) - round(0.2*x(4)),1),bb);
%                         xTopRight = cellfun(@(x) min(floor(x(2)) + round(1.2*x(5)),size(dataFrame.rawImage,1)),bb);
%                         yTopRight = cellfun(@(x) min(floor(x(1)) + round(1.2*x(4)),size(dataFrame.rawImage,2)),bb);
                        yBottomLeft = cellfun(@(x) min(max(floor(x(2)) - round(0.2*x(5)),1),size(dataFrame.rawImage,1)),bb);
                        xBottomLeft = cellfun(@(x) min(max(floor(x(1)) - round(0.2*x(4)),1),size(dataFrame.rawImage,2)),bb);
                        yTopRight = cellfun(@(x) max(min(floor(x(2)) + round(1.2*x(5)),size(dataFrame.rawImage,1)),yBottomLeft+2),bb);
                        xTopRight = cellfun(@(x) max(min(floor(x(1)) + round(1.2*x(4)),size(dataFrame.rawImage,2)),xBottomLeft+2),bb);
                        returnSample.results.thumbnails = vertcat(returnSample.results.thumbnails, table(dataFrame.frameNr * ones(size(dataFrame.features,1),1),xBottomLeft',...
                            yBottomLeft',xTopRight',yTopRight','VariableNames',{'frameNr' 'xBottomLeft' 'yBottomLeft' 'xTopRight' 'yTopRight'}));
                        thumbnail_images = cell(1,size(dataFrame.features,1));
                        segmentation = cell(1,size(dataFrame.features,1));
                        for n = 1:size(dataFrame.features,1)
%                             thumbnail_images{n} = dataFrame.rawImage(xBottomLeft(n):xTopRight(n),...
%                                 yBottomLeft(n):yTopRight(n),:);
%                             segmentation{n} = dataFrame.segmentedImage(xBottomLeft(n):xTopRight(n),...
%                                 yBottomLeft(n):yTopRight(n),:);
                            thumbnail_images{n} = dataFrame.rawImage(yBottomLeft(n):yTopRight(n),...
                                xBottomLeft(n):xTopRight(n),:);
                            segmentation{n} = dataFrame.segmentedImage(yBottomLeft(n):yTopRight(n),...
                                xBottomLeft(n):xTopRight(n),:);
                        end
                        returnSample.results.thumbnail_images = horzcat(returnSample.results.thumbnail_images, thumbnail_images);
                        returnSample.results.segmentation = horzcat(returnSample.results.segmentation, segmentation);
                    end
                end
            elseif this.use_thumbs == 1
                size(inputSample.priorLocations,1)
                for i = 1:size(inputSample.priorLocations,1)
                    i
                    thumbFrame = this.io.load_thumbnail_frame(inputSample,i,'prior'); 
                    this.dataProcessor.run(thumbFrame);
                    thumbsfoundearlier = size(returnSample.results.thumbnails,1);
                    objectsfound = size(thumbFrame.features,1);
                    if objectsfound > 0
                        thumbNr = array2table((thumbsfoundearlier+1)*ones(objectsfound,1),'VariableNames',{'ThumbNr'});
%                       thumbNr = array2table(i*(ones(size(thumbFrame.features,1),1)),'VariableNames',{'ThumbNr'});
                        thumbFrame.features = [thumbNr thumbFrame.features];
                        if size(thumbFrame.features,1) > 0
                            returnSample.results.features=vertcat(returnSample.results.features, thumbFrame.features);
                            returnSample.results.thumbnails=vertcat(returnSample.results.thumbnails, returnSample.priorLocations(i,:));
                            returnSample.results.segmentation = horzcat(returnSample.results.segmentation, thumbFrame.segmentedImage);
                            %delete later!?
                            returnSample.results.thumbnail_images = horzcat(returnSample.results.thumbnail_images, thumbFrame.rawImage);
                        end
                    end
                end
            end
        end
        
    end
    
end

