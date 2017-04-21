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
    %FEATURECOLLECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       dataProcessor = DataframeProcessor();
       use_thumbs = 0;
       priorLocations = [];
    end
    
    methods
        function this = FeatureCollection(inputDataframeProcessor,varargin)
            this.dataProcessor = inputDataframeProcessor;
            if nargin > 1
                this.use_thumbs = varargin{1};
            end
            
            if nargin > 2
                this.priorLocations = varargin{2};
            end
        end
        
        function returnSample = run(this, inputSample)
            returnSample = inputSample;
            
            if this.use_thumbs == 0
                featureTables = cell(inputSample.nrOfFrames,1);
                thumbnails = cell(inputSample.nrOfFrames,1);
                parfor i = 1:inputSample.nrOfFrames
                    dataFrame = IO.load_data_frame(inputSample,i);
                    this.dataProcessor.run(dataFrame);
                    objectsfoundearlier = size(inputSample.results.features,1);
                    objectsfound = size(dataFrame.features,1);
                    IO.save_data_frame_segmentation(inputSample,dataFrame);
                    if objectsfound > 0
                        thumbNr = array2table(linspace(objectsfoundearlier+1,objectsfoundearlier+size(dataFrame.features,1),...
                            size(dataFrame.features,1))','VariableNames',{'ThumbNr'});
                        
                        featureTables{i} = [thumbNr dataFrame.features]; %maybe change like below?!
                        bb = struct2cell(regionprops(dataFrame.labelImage,'BoundingBox'));
                        yBottomLeft = cellfun(@(x) min(max(floor(x(2)) - round(0.2*x(5)),1),size(dataFrame.rawImage,1)),bb);
                        xBottomLeft = cellfun(@(x) min(max(floor(x(1)) - round(0.2*x(4)),1),size(dataFrame.rawImage,2)),bb);
                        yTopRight = cellfun(@(x) min(floor(x(2)) + round(1.2*x(5)),size(dataFrame.rawImage,1)),bb);
                        yTopRight = max(yTopRight,yBottomLeft+2);
                        xTopRight = cellfun(@(x) min(floor(x(1)) + round(1.2*x(4)),size(dataFrame.rawImage,2)),bb);
                        xTopRight = max(xTopRight,xBottomLeft+2);
                        ind1 = find(xTopRight>size(dataFrame.rawImage,2));
                        ind2 = find(yTopRight>size(dataFrame.rawImage,1));
                        if ~isempty(ind1)|| ~isempty(ind2)
                            ind = [ind1, ind2];
                            xBottomLeft(ind) = [];
                            yBottomLeft(ind) = [];
                            xTopRight(ind) = [];
                            yTopRight(ind) = [];
                        end  
                        label = [1:1:objectsfound]';
                        thumbnails{i} = table(dataFrame.frameNr * ones(size(xBottomLeft,2),1),...
                            label,xBottomLeft',yBottomLeft',xTopRight',yTopRight','VariableNames',{'frameNr' 'label' 'xBottomLeft' 'yBottomLeft' 'xTopRight' 'yTopRight'});
                    end
                end
                    
                for k = 1:inputSample.nrOfFrames
                        % add extracted features to current sample result
                        if ~isempty(thumbnails{k})
                            returnSample.results.thumbnails = vertcat(returnSample.results.thumbnails, thumbnails{k});
                            returnSample.results.features = vertcat(returnSample.results.features,featureTables{k});
                        end
                 end
                         
            elseif this.use_thumbs == 1 && isempty(this.priorLocations)

                if strcmp(inputSample.type,'ThumbnailLoader')
                    nPriorLoc = inputSample.nrOfFrames
                else 
                    nPriorLoc = size(inputSample.priorLocations,1)
                end
                featureTables = cell(nPriorLoc,1);
                thumbnails = cell(nPriorLoc,1);
                segmentation = cell(nPriorLoc,1);
                % parallelized
                
%                 parfor i = 1:nPriorLoc
%                     if strcmp(inputSample.type,'ThumbnailLoader')
%                         thumbFrame = this.io.load_data_frame(inputSample,i);
%                     else
%                         thumbFrame = this.io.load_thumbnail_frame(inputSample,i,'prior'); 
%                     end
%                     this.dataProcessor.run(thumbFrame);
%                     % for the parallel version we need an explicit update
%                     % of the i-th dataFrame called thumbFrames{i}
%                     thumbFramesProcessed{i} = thumbFrame;
%                     objectsfound = size(thumbFrame.features,1);
%                     if objectsfound > 0
%                         thumbNr = array2table(i*ones(objectsfound,1),'VariableNames',{'ThumbNr'});
%                         featureTables{i} = [thumbNr thumbFrame.features];
%                     end
%                 end
                
                   
                    parfor i = 1:nPriorLoc
                        if strcmp(inputSample.type,'ThumbnailLoader')
                            thumbFrame = IO.load_data_frame(inputSample,i);
                        else
                            thumbFrame = IO.load_thumbnail_frame(inputSample,i,'prior');  
                        end
                        this.dataProcessor.run(thumbFrame);
                        % for the parallel version we need an explicit update
                        % of the i-th dataFrame called thumbFrames{i}
                        objectsfound = size(thumbFrame.features,1);
                        if objectsfound > 0
                            thumbNr = array2table(i*ones(objectsfound,1),'VariableNames',{'ThumbNr'});
                            featureTables{i} = [thumbNr thumbFrame.features];
                            frameNr = inputSample.priorLocations.frameNr(i)* ones(objectsfound,1);
                            label = [1:1:objectsfound]';
                            xBottomLeft = inputSample.priorLocations.xBottomLeft(i)* ones(objectsfound,1);
                            yBottomLeft = inputSample.priorLocations.yBottomLeft(i)* ones(objectsfound,1);
                            xTopRight = inputSample.priorLocations.xTopRight(i) * ones(objectsfound,1);
                            yTopRight = inputSample.priorLocations.yTopRight(i)* ones(objectsfound,1);
                            thumbnails{i}= table(frameNr ,label, xBottomLeft, yBottomLeft, xTopRight, yTopRight); 
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
                size(this.priorLocations,1)
                for i = 1:size(this.priorLocations,1)
                    i
                    thumbFrame = IO.load_thumbnail_frame(inputSample,i,this.priorLocations); 
                    this.dataProcessor.run(thumbFrame);
                    objectsfound = size(thumbFrame.features,1);
                    if objectsfound > 0
                        thumbNr = array2table(i*(ones(objectsfound,1)),'VariableNames',{'ThumbNr'});
                        thumbFrame.features = [thumbNr thumbFrame.features];
                        returnSample.results.features=vertcat(returnSample.results.features, thumbFrame.features);
                        frameNr = inputSample.priorLocations.frameNr(i)* ones(objectsfound,1);
                        label = [1:1:objectsfound]';
                        xBottomLeft = inputSample.priorLocations.xBottomLeft(i)* ones(objectsfound,1);
                        yBottomLeft = inputSample.priorLocations.yBottomLeft(i)* ones(objectsfound,1);
                        xTopRight = inputSample.priorLocations.xTopRight(i) * ones(objectsfound,1);
                        yTopRight = inputSample.priorLocations.yTopRight(i)* ones(objectsfound,1);
                        thumbnails= table(frameNr ,label, xBottomLeft, yBottomLeft, xTopRight, yTopRight); 
                        returnSample.results.thumbnails=vertcat(returnSample.results.thumbnails,thumbnails);
                        for j=1:objectsfound
                            returnSample.results.segmentation{end+1} = thumbFrame.segmentedImage;
                        end
                    end
                end
            end
        end
        
    end
    
end

