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
                    ind = ((1:inputSample.nrOfChannels) - 1)*9 + 2;
                    thumbnail_coords = table();
                    c = [];
                    if ~isempty(dataFrame.features)
                    for j1 = 1:size(ind,2)
                        if ~iscell(dataFrame.features(:,ind(j1)))
                            C = cell(size(dataFrame.features,1),1);
                            nameC = dataFrame.features.Properties.VariableNames{ind(j1)};
                            Ctab = cell2table(C,'VariableNames',{nameC});
                            for j2 = 1:size(C,1)
                                Ctab{j2,1} = {dataFrame.features{j2,ind(j1)}};
                            end
                            dataFrame.features(:,ind(j1)) = [];
                            dataFrame.features = [dataFrame.features(:,1:ind(j1)-1) Ctab dataFrame.features(:,ind(j1):end)];
                        end
                    end
                    coords = table2array(dataFrame.features(:,ind));
                        for k = 1:size(coords,1)
                            for l = 1:inputSample.nrOfChannels
                                if ~isempty(coords{k,l}{1})
                                    c(k,l,2) = max(round(coords{k,l}{1}(2) - 0.5 * coords{k,l}{1}(4)),1);
                                    c(k,l,1) = max(round(coords{k,l}{1}(1) - 0.5 * coords{k,l}{1}(3)),1);
                                    c(k,l,4) = min(round(coords{k,l}{1}(2) + 1.5 * coords{k,l}{1}(4)),size(dataFrame.rawImage,1));
                                    c(k,l,3) = min(round(coords{k,l}{1}(1) + 1.5 * coords{k,l}{1}(3)),size(dataFrame.rawImage,2));
                                end
                            end 
                        end
                    c(c(:,:,1:2) == 0) = inf;
                    c(find(c(:,:,:) == 0)) = -inf;
                    thumbs = zeros(size(c,1),6);
                    thumbs(:,3:6) = [min(c(:,:,1),[],2) min(c(:,:,2),[],2) max(c(:,:,3),[],2) max(c(:,:,4),[],2)];
                    thumbs(:,2) = dataFrame.frameNr;
                    thumbs(:,1) = linspace(size(inputSample.results.thumbnails,1)+1,size(inputSample.results.thumbnails,1)+size(thumbs,1),size(thumbs,1));
                    thumbnail_coords = array2table(thumbs,'VariableNames',{'eventNr','frameNr','xBottomLeft','yBottomLeft', 'xTopRight','yTopRight'});
                    dataFrame.features(:,ind) = [];
                    end
                    currentSize = size(returnSample.results.segmentation,2);
                    for j = 1 : size(dataFrame.features,1)
                        returnSample.results.segmentation{currentSize+j} = dataFrame.segmentedImage(thumbs(j,4):thumbs(j,6),thumbs(j,3):thumbs(j,5),:);
                    end
                    inputSample.results.features=vertcat(inputSample.results.features, dataFrame.features);
                    inputSample.results.thumbnails = vertcat(inputSample.results.thumbnails,thumbnail_coords);
                end
            elseif this.use_thumbs == 1
                ind = ((1:inputSample.nrOfChannels) - 1)*9 + 2;
                for i = 1:size(inputSample.priorLocations,1)
                    thumbFrame = this.io.load_thumbnail_frame(inputSample,i,'prior'); 
                    this.dataProcessor.run(thumbFrame);
                    thumbNr = array2table(i*(ones(size(thumbFrame.features,1),1)),'VariableNames',{'ThumbNr'});
                    if size(thumbFrame.features,1) > 0
                        thumbFrame.features(:,ind) = [];
                        thumbFrame.features = [thumbNr thumbFrame.features];
                        returnSample.results.features=vertcat(returnSample.results.features, thumbFrame.features);
                    end
                    returnSample.results.segmentation{i} = thumbFrame.segmentedImage;
                    %delete later!?
                    returnSample.results.thumbnail_images{i} = thumbFrame.rawImage;
                end
                returnSample.results.thumbnails = returnSample.priorLocations;
            end
        end
        
    end
    
end

