%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 
classdef FeatureCollection < SampleProcessorObject
    %  FEATURECOLLECTION sampleprocessprobject that calls the
    %  dataframeprocessor for each frame to extract all events
    
    properties
       dataProcessor = DataframeProcessor();
       use_thumbs = 0;
       priorLocations = [];
    end
    
    methods
        function this = FeatureCollection(inputDataframeProcessor,varargin)
            %dataframeprocessor determines how to process each frame
            this.dataProcessor = inputDataframeProcessor;
            %use only thumbnails frames?
            if nargin > 1
                this.use_thumbs = varargin{1};
            end
            %specified prior locations or read from xml file?
            if nargin > 2
                this.priorLocations = varargin{2};
            end
        end
        
        function returnSample = run(this, inputSample)
            returnSample = inputSample;
            
            if this.use_thumbs == 0 %process full image
                featureTables = cell(inputSample.nrOfFrames,1);
                thumbnails = cell(inputSample.nrOfFrames,1);
                %parallelized across frames
                parfor i = 1:inputSample.nrOfFrames
                    %load frame
                    dataFrame = IO.load_data_frame(inputSample,i);
                    %run dataframe processor to extract objects and
                    %features
                    this.dataProcessor.run(dataFrame); 
                    objectsfoundearlier = size(inputSample.results.features,1);
                    objectsfound = size(dataFrame.features,1);
                    %save segmentation of frame
                    IO.save_data_frame_segmentation(inputSample,dataFrame);
                    % add features to table
                    if objectsfound > 0
                        thumbNr = array2table(linspace(objectsfoundearlier+1,objectsfoundearlier+size(dataFrame.features,1),...
                            size(dataFrame.features,1))','VariableNames',{'ThumbNr'});
                        %add a unique thumbNr
                        featureTable = [thumbNr dataFrame.features]; %maybe change like below?!
                        %determine box surrounding event found
                        bb = struct2cell(regionprops(dataFrame.labelImage,'BoundingBox'));
                        yBottomLeft = cellfun(@(x) min(max(floor(x(2)) - round(0.2*x(0.5*size(bb{1},2)+2)),1),size(dataFrame.rawImage,1)),bb);
                        xBottomLeft = cellfun(@(x) min(max(floor(x(1)) - round(0.2*x(0.5*size(bb{1},2)+1)),1),size(dataFrame.rawImage,2)),bb);
                        yTopRight = cellfun(@(x) min(floor(x(2)) + round(1.2*x(0.5*size(bb{1},2)+2)),size(dataFrame.rawImage,1)),bb);
                        yTopRight = max(yTopRight,yBottomLeft+4);
                        xTopRight = cellfun(@(x) min(floor(x(1)) + round(1.2*x(0.5*size(bb{1},2)+1)),size(dataFrame.rawImage,2)),bb);
                        xTopRight = max(xTopRight,xBottomLeft+4);
                        label = [1:1:objectsfound]';
                        ind1 = find(xTopRight>size(dataFrame.rawImage,2));
                        ind2 = find(yTopRight>size(dataFrame.rawImage,1));
                        if ~isempty(ind1)|| ~isempty(ind2)
                            ind = unique([ind1, ind2]);
                            xBottomLeft(ind) = [];
                            yBottomLeft(ind) = [];
                            xTopRight(ind) = [];
                            yTopRight(ind) = [];
                            featureTable(ind,:) = [];
                            label(ind) = [];
                        end 
                        featureTables{i} = featureTable;
                        % store coordinates for thumbnail
                        try
                            thumbnails{i} = table(dataFrame.frameNr * ones(size(xBottomLeft,2),1),...
                                    label,xBottomLeft',yBottomLeft',xTopRight',yTopRight','VariableNames',{'frameNr' 'label' 'xBottomLeft' 'yBottomLeft' 'xTopRight' 'yTopRight'});
                        catch
                            disp('error in thumbnail coordinates assignment');
                        end
                        
                    end
                end
                    
                for k = 1:inputSample.nrOfFrames
                        % add extracted features and thumbnail coordinates to current sample result
                        if ~isempty(thumbnails{k})
                            returnSample.results.thumbnails = vertcat(returnSample.results.thumbnails, thumbnails{k});
                            returnSample.results.features = vertcat(returnSample.results.features,featureTables{k});
                        end
                 end
                         
            elseif this.use_thumbs == 1 && isempty(this.priorLocations)
                %use thumbnail frames exported from xml/xls file of sample
                %or thumbnail loader
                if strcmp(inputSample.type,'ThumbnailLoader')
                    nPriorLoc = inputSample.nrOfFrames;
                else 
                    nPriorLoc = size(inputSample.priorLocations,1)
                end
                featureTables = cell(nPriorLoc,1);
                thumbnails = cell(nPriorLoc,1);
                segmentation = cell(nPriorLoc,1);
                % parallelized    
                    parfor i = 1:nPriorLoc
                        %load data
                        if strcmp(inputSample.type,'ThumbnailLoader')
                            thumbFrame = IO.load_data_frame(inputSample,i);
                        else
                            thumbFrame = IO.load_thumbnail_frame(inputSample,i,'prior');  
                        end
                        %run dataframeprocessor
                        this.dataProcessor.run(thumbFrame);
                        % for the parallel version we need an explicit update
                        % of the i-th dataFrame called thumbFrames{i}
                        objectsfound = size(thumbFrame.features,1);
                        if objectsfound > 0
                            thumbNr = array2table(i*ones(objectsfound,1),'VariableNames',{'ThumbNr'});
                            % add unique thumbnumber
                            featureTables{i} = [thumbNr thumbFrame.features];
                 
                            frameNr = inputSample.priorLocations.frameNr(i)* ones(objectsfound,1);
                            label = [1:1:objectsfound]';
                            % surrounding box
                            xBottomLeft = inputSample.priorLocations.xBottomLeft(i)* ones(objectsfound,1);
                            yBottomLeft = inputSample.priorLocations.yBottomLeft(i)* ones(objectsfound,1);
                            xTopRight = inputSample.priorLocations.xTopRight(i) * ones(objectsfound,1);
                            yTopRight = inputSample.priorLocations.yTopRight(i)* ones(objectsfound,1);
                            thumbnails{i}= table(frameNr ,label, xBottomLeft, yBottomLeft, xTopRight, yTopRight);
                            if ismember('CellSearchIDs', inputSample.priorLocations.Properties.VariableNames)
                                CellSearchIDs = cell(objectsfound,1);
                                CellSearchIDs(:) =  inputSample.priorLocations.CellSearchIDs(i);
                                thumbnails{i} = [thumbnails{i} cell2table(CellSearchIDs)];
                            end
                            segmentation{i}=thumbFrame.segmentedImage;
                        end
                       
                    end
                                      
                    for k = 1:nPriorLoc
                        % add extracted features to current sample result
                        if ~isempty(thumbnails{k})
                            returnSample.results.thumbnails = vertcat(returnSample.results.thumbnails, thumbnails{k});
                            returnSample.results.features = vertcat(returnSample.results.features,featureTables{k});
                            for j=1:size(thumbnails{k},1)
                                returnSample.results.segmentation{end+1} = segmentation{k};
                            end
                        end
                    end
                
            %------------------
            elseif this.use_thumbs == 1 && ~isempty(this.priorLocations)
                %still needs to be adapted to parfor
                %use thumbnail frames for input prior locations
                for i = 1:size(this.priorLocations,1)
                    %load data
                    thumbFrame = IO.load_thumbnail_frame(inputSample,i,this.priorLocations); 
                    %run dataframeprocessor
                    this.dataProcessor.run(thumbFrame);
                    objectsfound = size(thumbFrame.features,1);
                    if objectsfound > 0
                        thumbNr = array2table(i*(ones(objectsfound,1)),'VariableNames',{'ThumbNr'});
                        %add unique thumbNr
                        thumbFrame.features = [thumbNr thumbFrame.features];
                        returnSample.results.features=vertcat(returnSample.results.features, thumbFrame.features);
                        
                        frameNr = inputSample.priorLocations.frameNr(i)* ones(objectsfound,1);
                        label = [1:1:objectsfound]';
                        %surrounding box
                        xBottomLeft = inputSample.priorLocations.xBottomLeft(i)* ones(objectsfound,1);
                        yBottomLeft = inputSample.priorLocations.yBottomLeft(i)* ones(objectsfound,1);
                        xTopRight = inputSample.priorLocations.xTopRight(i) * ones(objectsfound,1);
                        yTopRight = inputSample.priorLocations.yTopRight(i)* ones(objectsfound,1);
                        thumbnails= table(frameNr ,label, xBottomLeft, yBottomLeft, xTopRight, yTopRight); 
                        returnSample.results.thumbnails=vertcat(returnSample.results.thumbnails,thumbnails);
                        for j=1:objectsfound
                            %store segmentation
                            returnSample.results.segmentation{end+1} = thumbFrame.segmentedImage;
                        end
                    end
                end
            end
            if this.use_thumbs == 0 && ~isempty(inputSample.priorLocations) && ~isempty(returnSample.results.thumbnails)
                %try to connect found events to prescored CTCs stored in
                %xml/xls sheet of sample
                returnSample.results.classification = [returnSample.results.classification table(zeros(size(returnSample.results.features,1),1),'VariableNames',{'Prior_Scores'})];
                for i = 1:size(inputSample.priorLocations,1)  
                    % find all events in the right frame
                    selection = find(returnSample.results.thumbnails.frameNr == inputSample.priorLocations.frameNr(i));
                    % reduce to all events in the closer surrounding
                    % (compare middlepoints of boxes)
                    selection = selection(abs((returnSample.results.thumbnails.xBottomLeft(selection)+0.5*(returnSample.results.thumbnails.xTopRight(selection)...
                        - returnSample.results.thumbnails.xBottomLeft(selection)))...
                        - (inputSample.priorLocations.xBottomLeft(i)+ 0.5*(inputSample.priorLocations.xTopRight(i)-inputSample.priorLocations.xBottomLeft(i)))) < 30);
                    selection = selection(abs((returnSample.results.thumbnails.yBottomLeft(selection)+0.5*(returnSample.results.thumbnails.yTopRight(selection)...
                        - returnSample.results.thumbnails.yBottomLeft(selection)))...
                        - (inputSample.priorLocations.yBottomLeft(i)+ 0.5*(inputSample.priorLocations.yTopRight(i)-inputSample.priorLocations.yBottomLeft(i)))) < 30);
                    %compute overlap of boxes
                    if ~isempty(selection)
                        xTopRight_overlap = min(returnSample.results.thumbnails.xTopRight(selection),inputSample.priorLocations.xTopRight(i));
                        yTopRight_overlap = min(returnSample.results.thumbnails.yTopRight(selection),inputSample.priorLocations.yTopRight(i));
                        xBottomLeft_overlap = max(returnSample.results.thumbnails.xBottomLeft(selection),inputSample.priorLocations.xBottomLeft(i));
                        yBottomLeft_overlap = max(returnSample.results.thumbnails.yBottomLeft(selection),inputSample.priorLocations.yBottomLeft(i));
                        overlap = (xTopRight_overlap-xBottomLeft_overlap).*(yTopRight_overlap-yBottomLeft_overlap);
                        %choose box with highest overlap
                        [~,index] = max(overlap);
                        %check if overlap is large enough
                        candidate = selection(index);
                        size_candidate = (returnSample.results.thumbnails.xTopRight(candidate)-returnSample.results.thumbnails.xBottomLeft(candidate)).*...
                            (returnSample.results.thumbnails.yTopRight(candidate)-returnSample.results.thumbnails.yBottomLeft(candidate));
                        size_prior = (returnSample.priorLocations.xTopRight(i)-returnSample.priorLocations.xBottomLeft(i)).*...
                            (returnSample.priorLocations.yTopRight(i)-returnSample.priorLocations.yBottomLeft(i));
                        overlap_scaled1 = overlap(index)/size_candidate;
                        overlap_scaled2 = overlap(index)/size_prior;
                        if overlap_scaled1 > 0.75 || overlap_scaled2 > 0.75
                            %add prior classification
                            returnSample.results.classification.Prior_Scores(candidate) = 1;
                        end
                    end
                end             
            end
        end
        
    end
    
end

