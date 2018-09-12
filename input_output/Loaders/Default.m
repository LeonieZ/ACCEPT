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
classdef Default < Loader & IcyPluginData & CustomCsv
    %DEFAULT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='Default'
        hasEdges='false'
        pixelSize=0.64
        channelNames={'APC','DAPI','PE'};
        channelEdgeRemoval=2;
        sample=Sample();
    end
    
    events

    end
    
    methods
        function this = Default(input) %pass either sample or a path to the constructor
            if nargin == 1
                validateattributes(input,{'Sample','char'},{'nonempty'},'','input');
                if isa(input,'Sample')
                    if strcmp(input.type,this.name)
                        this.sample=input;
                    else
                    error('tried to use incorrect sampletype with Default Loader');
                    end
                else
                    this=this.new_sample_path(input);
                end
            end
        end
        
        function new_sample_path(this,samplePath)
            this.sample=Sample();
            this.sample.type = this.name;
            this.sample.loader = @Default;
            splitPath = regexp(samplePath, filesep, 'split');
            if isempty(splitPath{end})
                this.sample.id=splitPath{end-1};
            else
                this.sample.id=splitPath{end};
            end
            customChannelsUsed=this.look_for_custom_channels(samplePath);
            if ~isempty(customChannelsUsed)
                this.channelNames=customChannelsUsed;
            end
            this.sample.channelNames = this.channelNames;
            this.sample.pixelSize = this.pixelSize;
            this.sample.hasEdges = this.hasEdges;
            this.sample.channelEdgeRemoval = this.channelEdgeRemoval;
            this.preload_tiff_headers(samplePath);
            this.guess_scan_info(samplePath);
            this.sample.priorLocations = this.prior_locations_in_sample(samplePath);
            this.calculate_frame_nr_order();

        end
        
        function update_prior_infos(this,currentSample,samplePath)
            this.sample = currentSample;
            [this.sample.imagePath,~] = this.find_dir(samplePath,'tif',10);
            if exist(this.sample.imagePath,'dir')
                %this.load_scan_info(samplePath);
                this.preload_tiff_headers(samplePath);         
            end
            this.sample.priorLocations = this.prior_locations_in_sample(samplePath);
        end
        
        function dataFrame = load_data_frame(this,frameNr,varargin)
            dataFrame = Dataframe(frameNr,...
            this.does_frame_have_edge(frameNr),...
            this.channelEdgeRemoval,...
            this.read_im(frameNr,varargin{:}));
            dataFrame.pixelSize = this.sample.pixelSize;
            if ~isempty(this.sample.mask)
                [row, col] = find(this.sample.frameOrder==frameNr);
                [size_x_mask, size_y_mask] = size(this.sample.mask);
                size_x_small = round(size_x_mask / this.sample.rows);
                size_y_small = round(size_y_mask / this.sample.columns);
                mask_extract = this.sample.mask((row - 1)*size_x_small + 1 : row * size_x_small, (col - 1)*size_y_small + 1 : col * size_y_small);
                dataFrame.mask = imresize(mask_extract,[size(dataFrame.rawImage,1),size(dataFrame.rawImage,2)]);
            end
            dataFrame.adjacentFrames=this.calculate_neigbouring_frames(frameNr);
            addlistener(dataFrame,'loadNeigbouringFrames',@this.load_neigbouring_frames);
        end
        
        function rawImage = load_raw_image(this,frameNr)
            rawImage = this.read_im(frameNr);
        end

        function dataFrame = load_thumb_frame(this,thumbNr,option)
            if exist('option','var')
                if strcmp('prior',option)
                    if isempty(this.sample.priorLocations)
                        error('This sample contains no prior locations')
                    end
                    frameNr = this.sample.priorLocations.frameNr(thumbNr);
                    boundingBox = {[this.sample.priorLocations.yBottomLeft(thumbNr) this.sample.priorLocations.yTopRight(thumbNr)],...
                         [this.sample.priorLocations.xBottomLeft(thumbNr) this.sample.priorLocations.xTopRight(thumbNr)]};
%                    boundingBox = {[this.sample.priorLocations.xBottomLeft(thumbNr) this.sample.priorLocations.xTopRight(thumbNr)],...
%                        [this.sample.priorLocations.yBottomLeft(thumbNr) this.sample.priorLocations.yTopRight(thumbNr)]};
                    dataFrame=Dataframe(thumbNr,false,this.channelEdgeRemoval,this.read_im(frameNr,boundingBox));
                end
            else
                if isempty(this.sample.results.thumbnails)
                    error('This sample contains no thumbnail locations')
                end
                frameNr = this.sample.results.thumbnails.frameNr(thumbNr);
%                 boundingBox = {[this.sample.results.thumbnails.yBottomLeft(thumbNr) this.sample.results.thumbnails.yTopRight(thumbNr)],...
%                     [this.sample.results.thumbnails.xBottomLeft(thumbNr) this.sample.results.thumbnails.xTopRight(thumbNr)]};
                boundingBox = {[this.sample.results.thumbnails.xBottomLeft(thumbNr) this.sample.results.thumbnails.xTopRight(thumbNr)],...
                    [this.sample.results.thumbnails.yBottomLeft(thumbNr) this.sample.results.thumbnails.yTopRight(thumbNr)]};
                dataFrame=Dataframe(thumbNr,false,this.channelEdgeRemoval,this.read_im(frameNr,boundingBox));
                %some function is needed to load any possible saved
                %dataframes/segmentation.
            end
        end
        function frameOrder = calculate_frame_nr_order(this)
            frameOrder=zeros(this.sample.rows,this.sample.columns);
            for i=1:this.sample.nrOfFrames
                row = ceil(i/this.sample.columns);
                cols = this.sample.columns;
                col=i-(row-1)*cols;
                frameOrder(row,col)=i;
            end 
            this.sample.frameOrder=frameOrder;
        end
    end
   
    methods(Access=private)
        
        function guess_scan_info(this,samplePath)
            %find text files to extract metadata
               D=[1; unique(cumprod(perms(factor(this.sample.nrOfFrames)),2))];
               this.sample.columns=D(ceil(numel(D)/2));
               this.sample.rows=this.sample.nrOfFrames/this.sample.columns; 

       
                %error
         end
         function preload_tiff_headers(this,samplePath)
            [this.sample.imagePath,bool] = this.find_dir(samplePath,'tif',10);    
            if bool
                for j=1:numel(this.sample.channelNames)
                    tempImageFileNames = dir([this.sample.imagePath filesep '*' this.sample.channelNames{j} '*.tif']);
                    index_to_delete = [];
                    for i=1:numel(tempImageFileNames)
                        if ~contains(tempImageFileNames(i).name,this.sample.channelNames{j})
                            index_to_delete = [index_to_delete, i];
                        end
                    end
                    tempImageFileNames(index_to_delete) = [];
                    for i=1:numel(tempImageFileNames)                        
                            this.sample.imageFileNames{i,j} = [this.sample.imagePath filesep tempImageFileNames(i).name];  
                            this.sample.tiffHeaders{i,j}=imfinfo(this.sample.imageFileNames{i,j});
                    end

                    %function to fill the dataP.temp.imageinfos variable
                end
         %Have to add a check for the 2^15 offset.
                %dataP.temp.imagesHaveOffset=false;
                this.sample.imageSize=[this.sample.tiffHeaders{1,1}(1).Height this.sample.tiffHeaders{1,1}(1).Width  numel(this.sample.channelNames)];
                this.sample.nrOfFrames=numel(tempImageFileNames);
                this.sample.nrOfChannels=numel(this.sample.channelNames);
            else
                %throw error
            end
        end
        
        function rawImage=read_im(this,imageNr,boundingBox)
            % use the previously gathered imageinfo and read all images in a multipage
            % tiff. read only one channel if a channel is specified. Rescale and
            % stretch values and rescale to approx old values if the image is a
            % celltracks tiff: scales IMMC images back to 0..4095 scale. Otherwise a
            % normal tiff is returned.
            if nargin==2
                rawImage = zeros(this.sample.imageSize);
                boundingBox={[1 this.sample.imageSize(1)],[1 this.sample.imageSize(2)]};
            else
                %limit boundingBox to frame
                x = boundingBox{2};
                y = boundingBox{1};
                x = min(x,this.sample.imageSize(2));
                x = max(x,1);
                y = min(y,this.sample.imageSize(1));
                y = max(y,1);
                boundingBox = {x,y};
                sizex = boundingBox{2}(2)-boundingBox{2}(1)+1;
                sizey = boundingBox{1}(2)-boundingBox{1}(1)+1;
                rawImage = zeros(sizey,sizex,this.sample.imageSize(3));
            end
            for i=1:this.sample.nrOfChannels
                try
                    imagetemp = double(imread(this.sample.imageFileNames{imageNr,i},'info',this.sample.tiffHeaders{imageNr,i}));
                catch
                    if imageNr>0
                        notify(this,'logMessage',LogMessage(2,['Tiff', this.sample.imageFileNames{imageNr,i}, 'from channel ' num2str(i) ' is not readable!'])) ;
                        continue
                    else
                        notify(this,'logMessage',LogMessage(2,['Tiff', ' is missing or is not readable!'])) ;
                        return
                    end
                end
                if ~strcmp(this.sample.dataTypeOriginalImage,'uint16') && max(imagetemp(:)) > 32767
                    imagetemp = imagetemp - 32768;
                end
                rawImage(:,:,i)=imagetemp(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2));
                
            end
        end
        
        function hasEdge=does_frame_have_edge(this,frameNr)
            row = ceil(frameNr/this.sample.columns) - 1;
            switch row
                case {0,this.sample.rows-1} 
                    hasEdge=true;
                otherwise
                    col=frameNr-row*this.sample.columns;
                    if col==this.sample.columns
                        hasEdge=true;
                    elseif col==1
                        hasEdge=true;
                    else
                        hasEdge=false;
                    end 
            end
        end
        
        function load_neighbouring_frames(this,sourceFrame,~)
            % to be implemented
            neigbouring_frames=this.calculate_neighbouring_frames(sourceFrame.frameNr);
        
        end
        
        function neigbouring_frames=calculate_neigbouring_frames(this,frameNr)
            [x,y]=find(this.sample.frameOrder==frameNr);
            x=[x-1,x,x+1];
            y=[y-1,y,y+1];
            x(x<1)=[];
            x(x>this.sample.rows)=[];
            y(y<1)=[];
            y(y>this.sample.columns)=[];
            neigbouring_frames=this.sample.frameOrder(x,y);
        end
    end
    
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            
            [txtDir,cvsdirFound]=Loader.find_dir(path,'csv',1);
            [tifDir,tifdirFound]=Loader.find_dir(path,'tif',10);
            if cvsdirFound
                tempTxtFileNames = dir([txtDir filesep '*.csv']);
                for i=1:numel(tempTxtFileNames)
                    nameArray{i}=tempTxtFileNames(i).name;
                end
                test=strcmp(nameArray(:),'customChannels.csv');
                bool=any(test);
            elseif tifdirFound
                tempImageFileNames = dir([tifDir filesep '*APC*'  '.tif']);
                bool=50<numel(tempImageFileNames);
            else
                bool = false;
            end    
            
        end
    end
end


