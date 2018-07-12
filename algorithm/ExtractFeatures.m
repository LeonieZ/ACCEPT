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
classdef ExtractFeatures < DataframeProcessorObject
    %  EXTRACTFEATURES DataFrameProcessorObject to extract features after
    %  segmentation; acting on frame
    
    properties
        nrObjects = [];
    end
    
    methods
        function returnFrame = run(this,inputFrame)
            if isa(inputFrame,'Dataframe')
                % load data and initialize feature table
                returnFrame = inputFrame;
                returnFrame.features = table();
                %number of found objects
                this.nrObjects = max(inputFrame.labelImage(:));

                if this.nrObjects > 0
                    for ch = 1:inputFrame.nrChannels
                        imTemp = inputFrame.rawImage(:,:,ch);
                        % extract features (subtract background median for
                        % intensity measures)
                        if inputFrame.frameHasEdge && ~isempty(inputFrame.mask)
                            MsrTemp = regionprops(inputFrame.labelImage(:,:,ch), imTemp - median(imTemp(inputFrame.labelImage(:,:,ch) == 0 & inputFrame.mask ~= 1)),...
                                    'MaxIntensity', 'PixelValues', 'MeanIntensity', 'Area', 'Perimeter', 'Eccentricity');
                        else
                            MsrTemp = regionprops(inputFrame.labelImage(:,:,ch), imTemp - median(imTemp(inputFrame.labelImage(:,:,ch) == 0 )),...
                                'MaxIntensity', 'PixelValues', 'MeanIntensity', 'Area', 'Perimeter', 'Eccentricity');
                        end

                        %fill structure so tables can be concatenated.
                        MsrTemp=fillStruct(this, MsrTemp);
                        
                        %compute more features 
                        %mean intensity
                        MeanIntensity = arrayfun(@(x) max(0,(x.MeanIntensity)), MsrTemp);
                        %max intensity
                        MaxIntensity = arrayfun(@(x) max(0,(x.MaxIntensity)), MsrTemp);
                        %standard deviation
                        StandardDeviation = arrayfun(@(x) std2(x.PixelValues), MsrTemp);
                        %median intensity
                        MedianIntensity = arrayfun(@(x) max(0,median(x.PixelValues)), MsrTemp);
                        %mass (sum of all pixels)
                        Mass = arrayfun(@(x) max(0,sum(x.PixelValues)), MsrTemp);
                        %perimeter 2 area (roundness measure)
                        P2A = arrayfun(@(x) x.Perimeter^2/(4*pi*x.Area), MsrTemp);
                        %size in micrometer (scaled with pixelsize)
                        Size = arrayfun(@(x) x.Area *(inputFrame.pixelSize)^2 , MsrTemp);
                        MsrTemp=rmfield(MsrTemp,{'PixelValues','Area','MeanIntensity','MaxIntensity'});
                        
                        % create table with all features
                        names = strcat('ch_',num2str(ch),'_',fieldnames(MsrTemp));
                        tmpTable = struct2table(MsrTemp);
                        tmpTable.Properties.VariableNames = names;
                        tmpMeanIntensity = array2table(MeanIntensity,'VariableNames',{strcat('ch_',num2str(ch),'_MeanIntensity')});
                        tmpMaxIntensity = array2table(MaxIntensity,'VariableNames',{strcat('ch_',num2str(ch),'_MaxIntensity')});
                        tmpStandardDeviation = array2table(StandardDeviation,'VariableNames',{strcat('ch_',num2str(ch),'_StandardDeviation')});
                        tmpMedianIntensity = array2table(MedianIntensity,'VariableNames',{strcat('ch_',num2str(ch),'_MedianIntensity')});
                        tmpMass = array2table(Mass,'VariableNames',{strcat('ch_',num2str(ch),'_Mass')});
                        tmpP2A = array2table(P2A,'VariableNames',{strcat('ch_',num2str(ch),'_P2A')});
                        tmpSize = array2table(Size,'VariableNames',{strcat('ch_',num2str(ch),'_Size')});
                        
                        %add to existing feature table
                        returnFrame.features = [returnFrame.features tmpTable tmpMeanIntensity tmpMaxIntensity tmpMedianIntensity tmpSize tmpStandardDeviation tmpMass tmpP2A];
                    end
                              
                    %% VERY TIME CONSUMING DUE TO COMPLEXITY (not needed?)
%                     for ch_one = 1:inputFrame.nrChannels
%                         for ch_two = 1:ch_one
%                             tmpTbl = table();
%                             for i = 1:this.nrObjects
%                                 tmpImg = returnFrame.labelImage == i;
%                                 tmpTbl = [tmpTbl; array2table(sum(sum(tmpImg(:,:,ch_one) & tmpImg(:,:,ch_two))),...
%                                     'VariableNames',{strcat('Overlay_ch_',num2str(ch_one),'_ch_',num2str(ch_two))})]; 
%                             end
%                             returnFrame.features = [returnFrame.features tmpTbl];
%                         end
%                     end
                    %% smaller variant
                    %compute overlay of nucleus marker channel to all
                    %other ones
                    if inputFrame.nrChannels > 1
                        for ch_two = 1:inputFrame.nrChannels
                            if ch_two ~= 2
                                tmpTbl = table();
                                for i = 1:this.nrObjects
                                    tmpImg = returnFrame.labelImage == i;
                                    tmpTbl = [tmpTbl; array2table(sum(sum(tmpImg(:,:,2) & tmpImg(:,:,ch_two)))/sum(sum(tmpImg(:,:,2))),...
                                        'VariableNames',{strcat('ch_', num2str(2),'_Overlay_ch_',num2str(ch_two))})]; 
                                end
                                %add to features
                                returnFrame.features = [returnFrame.features tmpTbl];
                            end
                        end
                    end
                end
            elseif isa(inputFrame,'double')
                %input is double image with all channels first and all
                %segmentations attached
                if mod(size(inputFrame,3),2) ~= 0 %check if number of frames can mach number of segmentations
                    error('Feature Extraction not possible. Number of image frames and segmented frames is not the same!')
                end
                %extract raw image and segmentation
                rawImage = inputFrame(:,:,1:size(inputFrame,3)/2);
                segImage = inputFrame(:,:,size(inputFrame,3)/2+1:end);
                
                %check if segmentation is binary
                if ~isempty(find(segImage(segImage ~= 1),1))
                    error('Feature Extraction not possible. Segmented Image is not binary.')
                end
                
                % transform segmentation to labeled image
                sumImage = sum(segImage,3); 
                labels = repmat(bwlabel(sumImage,4),1,1,size(segImage,3));
                labelImage = labels.*segImage;
                
                %set output to empty table
                returnFrame = table();
                %determine number of objects
                this.nrObjects = max(labelImage(:));

                if this.nrObjects > 0
                    for ch = 1:size(segImage,3)
                        imTemp = rawImage(:,:,ch);
                        % extract features (subtract background median for
                        % intensity measures)
                        MsrTemp = regionprops(labelImage(:,:,ch), imTemp - median(imTemp(labelImage(:,:,ch) == 0)),...
                                'MaxIntensity', 'PixelValues', 'MeanIntensity', 'Area', 'Perimeter', 'Eccentricity');

                        %fill structure so tables can be concatenated.
                        MsrTemp=fillStruct(this, MsrTemp);
                        %compute more features
                        %standard deviation
                        StandardDeviation = arrayfun(@(x) std2(x.PixelValues), MsrTemp);
                        %mass (sum of pixels)
                        Mass = arrayfun(@(x) sum(x.PixelValues), MsrTemp);
                        %perimeter 2 area (roundness measure)
                        P2A = arrayfun(@(x) x.Perimeter^2/(4*pi*x.Area), MsrTemp);

                        MsrTemp=rmfield(MsrTemp,'PixelValues');
                        
                        %create table with all features
                        names = strcat('ch_',num2str(ch),'_',fieldnames(MsrTemp));
                        tmpTable = struct2table(MsrTemp);
                        tmpTable.Properties.VariableNames = names;
                        tmpStandardDeviation = array2table(StandardDeviation,'VariableNames',{strcat('ch_',num2str(ch),'_StandardDeviation')});
                        tmpMass = array2table(Mass,'VariableNames',{strcat('ch_',num2str(ch),'_Mass')});
                        tmpP2A = array2table(P2A,'VariableNames',{strcat('ch_',num2str(ch),'_P2A')});
                        returnFrame = [returnFrame tmpTable tmpStandardDeviation tmpMass tmpP2A];
                    end
                end
            else
                error('Extract Features can only be used on dataframes or double images combined with a binary segmentation for each channel.');
            end
        end

        function MsrTemp=fillStruct(this, MsrTemp)
            % fill missing information with zeros or NaNs
            numObjects = this.nrObjects;
            numMsr=numel(MsrTemp);

            if numMsr ~= numObjects
                if numMsr == 0;
                    MsrTemp(1:numObjects,1)=struct('Area',0,'Eccentricity', 0 ,'Perimeter',0,...
                        'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
                else
                    MsrTemp(numMsr+1:numObjects,1)=struct('Area',0 ,'Eccentricity', 0,...
                        'Perimeter',0, 'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
                end
            end
            idx=arrayfun(@(x) isempty(x.MaxIntensity),MsrTemp);
            MsrTemp(idx)=struct('Area',0 ,'Eccentricity',0,'Perimeter',0,...
            'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
        end
       
        
    end
end
