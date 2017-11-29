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
    
classdef CellTracksXp < Loader
    %CELLSEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='CellTracksXp'
        hasEdges=true;
        rescaleTiffs=true;
        pixelSize=0.64;
        channelNames={'DNA','Marker1','CK','CD45','Marker2','Marker3'};
        channelRemapping=[2,4,3,1,5,6;4,1,3,2,5,6];
        channelEdgeRemoval=2;
        dlmData=[];
        sample=Sample();
    end
    
    methods
        function this = CellTracksXp(input) %pass either a sample or a path to the constructor
            if nargin == 1
                validateattributes(input,{'Sample','char'},{'nonempty'},'','input');
                if isa(input,'Sample')
                    if strcmp(input.type,this.name)
                        this.sample=input;
                    else
                    error('tried to use incorrect sampletype with CellTracks Loader');
                    end
                else
                    this=this.new_sample_path(input);
                end
            end
        end
        
        function new_sample_path(this,samplePath)
            this.sample.type = this.name;
            this.sample.loader = @CellTracksXp;
            [this.sample.imagePath,~] = this.find_dir(samplePath,'tif',100); 
            [this.sample.priorPath,~] = this.find_dir(samplePath,'dlm',3); 
            splitPath = regexp(samplePath, filesep, 'split');
            if isempty(splitPath{end})
                this.sample.id=splitPath{end-1};
            else
                this.sample.id=splitPath{end};
            end
            this.preload_tiff_headers();
            this.sample.pixelSize = this.pixelSize;
            this.sample.hasEdges = this.hasEdges;
            this.sample.channelNames = this.channelNames(this.channelRemapping(2,1:this.sample.nrOfChannels));
            this.sample.channelEdgeRemoval = this.channelEdgeRemoval;
            this.processDLM();
            this.sample.priorLocations = this.prior_locations_in_sample();
            this.sample.frameOrder=this.calculate_frame_nr_order();
            this.sample.results = Result();
            this.sample.overviewImage = [];
            this.sample.histogram = [];
            this.sample.mask = [];
        end
        
        function update_prior_infos(this,currentSample,samplePath)
            this.sample = currentSample;
%             if ~exist(currentSample.imagePath,'dir')
                [this.sample.imagePath,~] = this.find_dir(samplePath,'tif',100); 
                [this.sample.priorPath,~] = this.find_dir(samplePath,'xml',1);
                this.preload_tiff_headers();         
%             end
        end
   
        function dataFrame = load_data_frame(this,frameNr,varargin)
            dataFrame = Dataframe(frameNr,...
            this.does_frame_have_edge(frameNr),...
            this.channelEdgeRemoval,...
            this.read_im_and_scale(frameNr,varargin{:}));
            dataFrame.pixelSize = this.sample.pixelSize;
            if ~isempty(this.sample.mask)
                [row, col] = this.frameNr_to_row_col(frameNr);
                [size_x_mask, size_y_mask] = size(this.sample.mask);
                size_x_small = round(size_x_mask / this.sample.rows);
                size_y_small = round(size_y_mask / this.sample.columns);
                mask_extract = this.sample.mask((row - 1)*size_x_small + 1 : row * size_x_small, (col - 1)*size_y_small + 1 : col * size_y_small);
                dataFrame.mask = imresize(mask_extract,[size(dataFrame.rawImage,1),size(dataFrame.rawImage,2)]);
            end
            addlistener(dataFrame,'loadNeigbouringFrames',@this.load_neigbouring_frames);
        end
        
        function rawImage = load_raw_image(this,frameNr)
            rawImage = this.read_im_and_scale(frameNr);
        end
        
        function dataFrame = load_thumb_frame(this,thumbNr,option)
            if exist('option','var')
                if strcmp('prior',option)
                    if isempty(this.sample.priorLocations)
                        error('This sample contains no prior locations')
                    end
                    frameNr = this.sample.priorLocations.frameNr(thumbNr);
%                     boundingBox = {[this.sample.priorLocations.yBottomLeft(thumbNr) this.sample.priorLocations.yTopRight(thumbNr)],...
%                         [this.sample.priorLocations.xBottomLeft(thumbNr) this.sample.priorLocations.xTopRight(thumbNr)]};
                    boundingBox = {[this.sample.priorLocations.xBottomLeft(thumbNr) this.sample.priorLocations.xTopRight(thumbNr)],...
                        [this.sample.priorLocations.yBottomLeft(thumbNr) this.sample.priorLocations.yTopRight(thumbNr)]};
                    dataFrame=Dataframe(thumbNr,false,this.channelEdgeRemoval,this.read_im_and_scale(frameNr,boundingBox));
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
                dataFrame=Dataframe(thumbNr,false,this.channelEdgeRemoval,this.read_im_and_scale(frameNr,boundingBox));
                %some function is needed to load any possible saved
                %dataframes/segmentation.
            end
            
        end
        
        function frameOrder = calculate_frame_nr_order(this)
            frameOrder=zeros(this.sample.rows,this.sample.columns);
            if this.sample.nrOfFrames == 140
                for i=1:this.sample.nrOfFrames
                    row = 4-floor((i-1)/this.sample.columns);
                    cols = this.sample.columns;
                    switch row
                    case {2,4,6} 
                        col = this.sample.nrOfFrames-i+1-(row-1)*cols;
                        frameOrder(row,col)=i;
                    otherwise
                        col=mod(i,cols);
                        if col == 0
                            col = cols;
                        end
                        frameOrder(row,col)=i;
                    end
                end          
            else
                for i=1:this.sample.nrOfFrames
                    row = ceil(i/this.sample.columns);
                    cols = this.sample.columns;
                    switch row
                    case {2,4,6} 
                        col=(1+cols-(i-(row-1)*this.sample.columns));
                        frameOrder(row,col)=i;
                    otherwise
                        col=i-(row-1)*cols;
                        frameOrder(row,col)=i;
                    end
                end 
            end       
        end
    end

    methods(Access=private)        
        function preload_tiff_headers(this)
            this.sample.imageFileNames = [];
            this.sample.tiffHeaders = [];
            tempImageFileNames = dir([this.sample.imagePath filesep '*.tif']); 
            tempImageFileNames_cleared = [];
            for i=1:numel(tempImageFileNames)
                if find(ismember(strfind(tempImageFileNames(i).name,'.'),1))
                    tempImageFileNames_cleared = [tempImageFileNames_cleared i];
                end
            end
            tempImageFileNames(tempImageFileNames_cleared) = [];
            for i=1:numel(tempImageFileNames)
                this.sample.imageFileNames{i} = [this.sample.imagePath filesep tempImageFileNames(i).name];
            end
            %function to fill the dataP.temp.imageinfos variable

            for i=1:numel(this.sample.imageFileNames)
                this.sample.tiffHeaders{i}=imfinfo(this.sample.imageFileNames{i});
            end

            %Have to add a check for the 2^15 offset.
            %dataP.temp.imagesHaveOffset=false;
            this.sample.imageSize=[this.sample.tiffHeaders{1}(1).Height this.sample.tiffHeaders{1}(1).Width numel(this.sample.tiffHeaders{1})];
            this.sample.nrOfFrames=numel(tempImageFileNames);
            this.sample.nrOfChannels=numel(this.sample.tiffHeaders{1});
        end
        
        function rawImage=read_im_and_scale(this,imageNr,boundingBox)
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
                x = boundingBox{1};
                y = boundingBox{2};
                x = min(x,this.sample.imageSize(2));
                x = max(x,1);
                y = min(y,this.sample.imageSize(1));
                y = max(y,1);
                boundingBox = {y,x};
                sizex = boundingBox{2}(2)-boundingBox{2}(1)+1;
                sizey = boundingBox{1}(2)-boundingBox{1}(1)+1;
                rawImage = zeros(sizey,sizex,this.sample.imageSize(3));
            end
            for i=1:this.sample.nrOfChannels
                try
                    imagetemp = double(imread(this.sample.imageFileNames{imageNr},i, 'info',this.sample.tiffHeaders{imageNr}));
                catch
                    notify(this,'logMessage',LogMessage(2,['Tiff', this.sample.imageFileNames{imageNr}, 'from channel ' num2str(i) ' is not readable!'])) ;
                    return
                end
                if  this.rescaleTiffs 
                    
                    UnknownTags = this.sample.tiffHeaders{imageNr}(i).UnknownTags;

                    LowValue  =  UnknownTags(2).Value;
                    HighValue =  UnknownTags(3).Value;


                    % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
                    imagetemp = LowValue + imagetemp * ((HighValue-LowValue)/max(imagetemp(:)));
                    if max(imagetemp) > 32767
                        imagetemp = imagetemp - 32768;
                    end
                    rawImage(:,:,this.channelRemapping(1,i))=imagetemp(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2));
                else
                    if max(imagetemp) > 32767
                        imagetemp = imagetemp - 32768;
                    end
                    rawImage(:,:,this.channelRemapping(1,i))=imagetemp(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2));
                end
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
        
        function locations=prior_locations_in_sample(this)
            if isempty(this.dlmData)
                this.processDLM();
            end
            index=[];
            %index=[1:this.xmlData.num_events];
            if ~isempty(this.dlmData)
                index=find(this.dlmData.score==true);
            end
            if isempty(index)
                locations=[];
            else
                for i=1:numel(index)
                    locations(i,:)=this.dlmData.priorEvents.locations(index(i),:);
                end
            end
        end           
        
        function load_neighbouring_frames(this,sourceFrame,~)
            % to be implemented
            neigbouring_frames=this.calculate_neighbouring_frames(sourceFrame.frameNr);
        
        end
        
        function neigbouring_frames=calculate_neigbouring_frames(this,frameNr)
            % to be implemented
            neigbouring_frames=[1,2,3];
        end
        
        function processDLM(this)
            % Process XML file if available
            % determine in which directory the xml file is located.
            NoDLM=0;
            this.dlmData = [];
            % find directory where xml file is located in
            if isempty(this.sample.priorPath)
                NoDLM=1;
            elseif strcmp(this.sample.priorPath,'No dir found')
                NoDLM=1;
            else
                DLMFile = dir([this.sample.priorPath filesep '*.dlm']);
            end
            
            if size(DLMFile,1) > 5
                test(1)=any(arrayfun(@(x) strcmp(x.name,'autoanalysis.dlm'),DLMFile));
                test(2)=any(arrayfun(@(x) strcmp(x.name,'cells.dlm'),DLMFile));
                test(3)=any(arrayfun(@(x) strcmp(x.name,'expdata.dlm'),DLMFile));
                test(4)=any(arrayfun(@(x) strcmp(x.name,'exper.dlm'),DLMFile));
                test(5)=any(arrayfun(@(x) strcmp(x.name,'frames.dlm'),DLMFile));
                test(6)=any(arrayfun(@(x) strcmp(x.name,'pic.dlm'),DLMFile));
                NoDLM=~all(test);
            else
                %To few DLM files found
                NoDLM=1;
            end
            %setting row and colums based on nrOfImages
            switch this.sample.nrOfFrames
                case 210 % 6*35 images
                    this.sample.columns=35;
                    this.sample.rows=6;
                case 180 % 5*36 images
                    this.sample.columns=36;
                    this.sample.rows=5;
                case 175 % 5*35 images
                    this.sample.columns=35;
                    this.sample.rows=5;
                case 170 % 5*34 images
                    this.sample.columns=34;
                    this.sample.rows=5;
                case 144 % 4*36 images
                    this.sample.columns=36;
                    this.sample.rows=4;
                case 140 % 4*35 images
                    this.sample.columns=35;
                    this.sample.rows=4;
            end
            % Load & process DLM file
            if NoDLM == 0
                this.dlmData=[];
                this.dlmData.CellSearchIds = [];
                this.dlmData.locations = [];
                this.dlmData.score=[];
                this.dlmData.frameNr=[];
                this.dlmData.camYSize=1384;
                this.dlmData.camXSize=1036;

                this.dlmData.frame=this.read_pic_dlm([this.sample.priorPath filesep 'pic.dlm']);
                if ~isempty(this.dlmData.frame.frameNr)
                    this.dlmData.priorEvents=this.read_cells_dlm([this.sample.priorPath filesep 'cells.dlm'],this.dlmData.frame);
                    this.dlmData.num_events = numel(this.dlmData.priorEvents.eventNr);
                    this.dlmData.CellSearchIds = this.dlmData.priorEvents.eventNr;
                    this.dlmData.score=this.dlmData.priorEvents.selected;
                end
                
                    
                %notify(this,'logMessage',logmessage(2,['unable to read xml']));
                
            end
        end
       
        
        function [coordinates]=pixels_to_coordinates(this,pixelCoordinates, imgNr)
            row = ceil(imgNr/this.sample.columns) - 1;
            cols = this.sample.columns;
            switch row
                case {1,3,5} 
                    col=(cols-(imgNr-row*this.sample.columns));
                    coordinates(1)=pixelCoordinates(1)+this.dlmData.camXSize*col;
                    coordinates(2)=pixelCoordinates(2)+this.dlmData.camYSize*row;  
                otherwise
                    col=imgNr-1-row*cols;
                    coordinates(1)=pixelCoordinates(1)+this.dlmData.camXSize*col;
                    coordinates(2)=pixelCoordinates(2)+this.dlmData.camYSize*row; 
            end 
        end

        
        function [row, col]=frameNr_to_row_col(this,imgNr)
            row = ceil(imgNr/this.sample.columns);
            cols = this.sample.columns;
            switch row
                case {1,3,5} 
                    col=imgNr-(row-1)*cols;
%                     col=(cols-(imgNr-row*this.sample.columns));  
                otherwise
%                     col=imgNr-1-(row-1)*cols;
                    col=(cols-(imgNr-1-(row-1)*this.sample.columns));
            end
        end
        
        function priorEvents=read_cells_dlm(this,path,frame)
            fileId=fopen(path);
%             temp=textscan(fileId,'%s%s%f%f%f%f%s%s%s%s%s%s%s','delimiter','?');
            temp=textscan(fileId,'%s%s%f%f%f%f%s%s%s%s%s%s%s','delimiter','¦');
            nrOfEvents=numel(temp{1});
            priorEvents.eventNr=zeros(nrOfEvents,1);
            priorEvents.selected=zeros(nrOfEvents,1);
            priorEvents.frameNr=zeros(nrOfEvents,1);
            priorEvents.xBottomLeft=zeros(nrOfEvents,1);
            priorEvents.yBottomLeft=zeros(nrOfEvents,1);
            priorEvents.xTopRight=zeros(nrOfEvents,1);
            priorEvents.yTopRight=zeros(nrOfEvents,1);
            priorEvents.xLocation=zeros(nrOfEvents,1);
            priorEvents.yLocation=zeros(nrOfEvents,1);
            priorEvents.xBottomLeft=temp{3}-temp{5}/2;
            priorEvents.yBottomLeft=temp{4}-temp{6}/2;
            priorEvents.xTopRight=temp{3}+temp{5}/2;
            priorEvents.yTopRight=temp{4}+temp{6}/2;
            for i=1:nrOfEvents
                priorEvents.eventNr(i)=i;
                priorEvents.selected(i)=strcmp(temp{11}(i),'Y');
                priorEvents.frameNr(i)=frame.frameNr(find(strcmp(frame.timeStamp,temp{2}(i))));
                coordinates=this.pixels_to_coordinates([priorEvents.xBottomLeft(i) priorEvents.yBottomLeft(i)],...
                priorEvents.frameNr(i));
                priorEvents.xLocation(i)=coordinates(1);
                priorEvents.yLocation(i)=coordinates(2);
            end
            eventNr=priorEvents.eventNr;
            frameNr=priorEvents.frameNr;
            xBottomLeft=priorEvents.xBottomLeft;
            yBottomLeft=priorEvents.yBottomLeft;
            xTopRight=priorEvents.xTopRight;
            yTopRight=priorEvents.yTopRight;
            xLocation=priorEvents.xLocation;
            yLocation=priorEvents.yLocation;
            priorEvents.locations=table(eventNr,frameNr,...
                xBottomLeft,yBottomLeft,xTopRight,yTopRight,xLocation,yLocation);
            fclose(fileId);
        end       
        
        function frame=read_pic_dlm(~,path)
            fileId=fopen(path);
%             temp=textscan(fileId,'%s%s%s%f%s','delimiter','?');
            temp=textscan(fileId,'%s%s%s%f%s','delimiter','¦');
            frame.timeStamp=temp{1};
            frame.frameNr=temp{4};
            frame.timeStamp=strrep(frame.timeStamp,'"','');
            fclose(fileId);
        end

    end
        
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            [txtDir,dirFound]=Loader.find_dir(path,'dlm',4);
            if dirFound
                tempTxtFileNames = dir([txtDir filesep '*.dlm']);
                for i=1:numel(tempTxtFileNames)
                    nameArray{i}=tempTxtFileNames(i).name;
                end
                test=strcmp(nameArray(:),'pic.dlm');
                bool=any(test);
            else
                bool = false;
            end    

        end
    end
end

