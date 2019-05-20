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
classdef ThumbnailLoader_adapted < Loader
    %CELLSEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='ThumbnailLoader_Adapted';
        sample=Sample();
        hasEdges=false;
        rescaleTiffs=false;
        pixelSize=0.64;
        channelNames={'ExclMarker','NuclMarker','InclMarker','Marker1','Marker2','Marker3'};
        channelRemapping=[1,2,3,4,5,6;1,2,3,4,5,6];
        channelEdgeRemoval=1;   
    end
    
    methods
        function this = ThumbnailLoader_adapted(input) %pass either a sample or a path to the constructor
            if nargin == 1
                validateattributes(input,{'Sample','char'},{'nonempty'},'','input');
                if isa(input,'Sample')
                    if strcmp(input.type,this.name)
                        this.sample=input;
                    else
                    error('Tried to use incorrect sample type with ThumbnailLoader loader.');
                    end
                else
                    this=this.new_sample_path(input);
                end
            end
        end
        
        function new_sample_path(this,samplePath)
            this.sample.type = this.name;
            this.sample.loader = @ThumbnailLoader; 
            splitPath = regexp(samplePath, filesep, 'split');
            if isempty(splitPath{end})
                this.sample.id=splitPath{end-1};
            else
                this.sample.id=splitPath{end};
            end
            this.preload_tiff_headers(samplePath);
            this.sample.priorLocations = this.prior_locations_in_sample(samplePath);
            this.sample.pixelSize = this.pixelSize;
            this.sample.hasEdges = this.hasEdges;
            this.sample.channelNames = this.channelNames(this.channelRemapping(2,1:this.sample.nrOfChannels));
            this.sample.channelEdgeRemoval = this.channelEdgeRemoval;
            this.sample.results = Result();
            this.sample.overviewImage = [];
            this.sample.histogram = [];
            this.sample.mask = [];
        end
        
        function update_prior_infos(this,currentSample,samplePath)
            currentSample.savePath = samplePath;
            this.sample = currentSample;
            
            [this.sample.imagePath,~] = this.find_dir(samplePath,'tif',1);
            if exist(this.sample.imagePath,'dir')
                this.preload_tiff_headers(samplePath);         
            end
            this.sample.priorLocations = this.prior_locations_in_sample(samplePath);
        end
        
        function preload_segmentation_tiffs(this,currentSample,samplePath)
            this.sample = currentSample;
            [this.sample.imagePath,bool] = this.find_dir(samplePath,'tif',1);
            
            if bool == 1
                tempImageFileNames = dir([this.sample.imagePath filesep '*.tif']);
                this.sample.segmentationFileNames = [];
                this.sample.segmentationHeaders = [];
                for i=1:numel(tempImageFileNames)
                    if ~isempty(strfind(tempImageFileNames(i).name,'segm'))
                        this.sample.segmentationFileNames{end+1} = [this.sample.imagePath filesep tempImageFileNames(i).name];  
                    end
                end

                for i=1:numel(this.sample.segmentationFileNames)
                    this.sample.segmentationHeaders{i}=imfinfo(this.sample.segmentationFileNames{i});
                end
            end
        end
            
   
        function dataFrame = load_data_frame(this,frameNr,varargin)
            rawImage = this.read_im(frameNr,varargin{:});
            if size(rawImage,3) < this.sample.nrOfChannels
                for l = size(rawImage,3)+1:this.sample.nrOfChannels
                    rawImage(:,:,l) = zeros(size(rawImage,1),size(rawImage,2));
                end
            end
            dataFrame = Dataframe(frameNr,...
            false,this.channelEdgeRemoval,rawImage);
            name = strsplit(this.sample.imageFileNames{frameNr},'.');
            if exist([strjoin(name(1:end-1),'.') '_segm.tif'], 'file') == 2
                dataFrame.segmentedImage = logical(this.read_segm(frameNr));
                sumImage = sum(dataFrame.segmentedImage,3); 
                labels = repmat(bwlabel(sumImage,4),1,1,size(dataFrame.segmentedImage,3));
                dataFrame.labelImage = labels.*dataFrame.segmentedImage;
            end
            if ~isempty(dataFrame.segmentedImage) && size(dataFrame.segmentedImage,3) < this.sample.nrOfChannels
                for l = size(dataFrame.segmentedImage,3)+1:this.sample.nrOfChannels
                        dataFrame.segmentedImage(:,:,l) = zeros(size(dataFrame.rawImage,1),size(dataFrame.rawImage,2));
                        dataFrame.labelImage(:,:,l) = zeros(size(dataFrame.rawImage,1),size(dataFrame.rawImage,2));
                end
            end
        end
        
        function rawImage = load_raw_image(this,frameNr)
            rawImage = this.read_im(frameNr);
            if size(rawImage,3) < this.sample.nrOfChannels
                for l = size(rawImage,3)+1:this.sample.nrOfChannels
                    rawImage(:,:,l) = zeros(size(rawImage,1),size(rawImage,2));
                end
            end
        end
        
        function locations = prior_locations_in_sample(this,samplePath)
            locations=table();          
            [this.sample.priorPath,~] = this.find_dir(samplePath,'txt',1);           
            for i = 1:this.sample.nrOfFrames
                frameNr = i;
                xBottomLeft = 1;
                yBottomLeft = 1;
                xTopRight = this.sample.tiffHeaders{i}.Width;
                yTopRight = this.sample.tiffHeaders{i}.Height;                  
                location=table(frameNr,xBottomLeft,yBottomLeft,xTopRight,yTopRight);
                locations(i,:)=location;
            end
        end
        
       function frameOrder = calculate_frame_nr_order(this)
       end
       
    end

    methods(Access=private)
        
        function preload_tiff_headers(this,samplePath)
            [this.sample.imagePath, bool] = this.find_dir(samplePath,'tif',1); 
            if bool
                tempImageFileNames = dir([this.sample.imagePath filesep '*.tif']);
                this.sample.imageFileNames = [];
                this.sample.tiffHeaders = [];
                for i=1:numel(tempImageFileNames)
                    if isempty(strfind(tempImageFileNames(i).name,'segm'))
                        this.sample.imageFileNames{end+1} = [this.sample.imagePath filesep tempImageFileNames(i).name];  
                    end
                end
                %function to fill the dataP.temp.imageinfos variable

                for i=1:numel(this.sample.imageFileNames)
                    this.sample.tiffHeaders{i}=imfinfo(this.sample.imageFileNames{i});
                end

                %Have to add a check for the 2^15 offset.
                if this.sample.tiffHeaders{1}(1).BitDepth == 8
                    this.sample.dataTypeOriginalImage = 'uint8';
                else
                    this.sample.dataTypeOriginalImage = 'uint16';
                end
                this.sample.imageSize=[this.sample.tiffHeaders{1}(1).Height this.sample.tiffHeaders{1}(1).Width numel(this.sample.tiffHeaders{1})];
                this.sample.nrOfFrames=numel(this.sample.imageFileNames);
%                 this.sample.nrOfChannels=max(cellfun(@numel,this.sample.tiffHeaders));
                this.sample.nrOfChannels=3;
            else
                %throw error
            end
        end
        
        function rawImage=read_im(this,imageNr)
            % use the previously gathered imageinfo and read all images in a multipage
            % tiff. read only one channel if a channel is specified.
%             rawImage = zeros(this.sample.tiffHeaders{imageNr}(1).Height,this.sample.tiffHeaders{imageNr}(1).Width, size(this.sample.tiffHeaders{imageNr},1));
%             for i=1:this.sample.nrOfChannels
%                 try
%                     imagetemp = double(imread(this.sample.imageFileNames{imageNr},i, 'info',this.sample.tiffHeaders{imageNr}));
%                 catch
%                     notify(this,'logMessage',LogMessage(2,['Tiff', this.sample.imageFileNames{imageNr}, 'from channel ' num2str(i) ' is not readable!'])) ;
%                     return
%                 end               
%                 rawImage(:,:,this.channelRemapping(1,i))=imagetemp;
%             end
            rawImage = double(imread(this.sample.imageFileNames{imageNr}, 'info',this.sample.tiffHeaders{imageNr}));
        end 
        
        function segmImage=read_segm(this,imageNr)
            % use the previously gathered imageinfo and read all images in a multipage
            % tiff. read only one channel if a channel is specified.
              name = strsplit(this.sample.imageFileNames{imageNr},'.');
%             segmImage = zeros(this.sample.tiffHeaders{imageNr}(1).Height,this.sample.tiffHeaders{imageNr}(1).Width, size(this.sample.tiffHeaders{imageNr},1));
%             for i=1:this.sample.nrOfChannels
%                 try
%                     name = strsplit(this.sample.imageFileNames{imageNr},'.');
%                     imagetemp = imread([strjoin(name(1:end-1),'.') '_segm.tif'], i);
%                 catch
%                     notify(this,'logMessage',LogMessage(2,['Segmentation from Tiff', this.sample.imageFileNames{imageNr}, 'from channel ' num2str(i) ' is not readable!'])) ;
%                     return
%                 end               
%                 segmImage(:,:,this.channelRemapping(1,i))=imagetemp;
%             end
             segmImage = imread([strjoin(name(1:end-1),'.') '_segm.tif']);
        end 
        
    end
        
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            
            [txtDir,dirFound]=Loader.find_dir(path,'txt',1);
            if dirFound
                tempTxtFileNames = dir([txtDir filesep '*.txt']);
                for i=1:numel(tempTxtFileNames)
                    nameArray{i}=tempTxtFileNames(i).name;
                end
                test=strcmp(nameArray(:),'ACCEPTThumbnails.txt');
                bool=any(test);
            else
                bool = false;
            end    
        end
    end
end

