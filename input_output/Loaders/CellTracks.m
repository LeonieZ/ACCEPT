classdef CellTracks < Loader
    %CELLSEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='CellTracks'
        hasEdges=true;
        rescaleTiffs=true;
        pixelSize=0.64;
        tiffHeaders;
        channelNames={'DNA','Marker1','CK','CD45','Marker2','Marker3'};
        channelRemapping=[2,4,3,1,5,6;4,1,3,2,5,6];
        channelEdgeRemoval=2;
        xmlData=[];
        sample=Sample();
    end
    
    methods
        function this = CellTracks(input) %pass either a sample or a path to the constructor
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
            this.sample.loader = @CellTracks;
            [this.sample.imagePath,~] = this.find_dir(samplePath,'tif',100); 
            [this.sample.priorPath,~] = this.find_dir(samplePath,'xml',1); 
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
            this.processXML();
            this.sample.priorLocations = this.prior_locations_in_sample;
            this.sample.frameOrder=this.calculate_frame_nr_order;
            this.sample.results = Result();
            this.sample.overviewImage = [];
            this.sample.histogram = [];
            this.sample.mask = [];
        end
        
        function update_prior_infos(this,currentSample,samplePath)
            this.sample = currentSample;
            if ~exist(currentSample.imagePath,'dir')
                [this.sample.imagePath,~] = this.find_dir(samplePath,'tif',100); 
                [this.sample.priorPath,~] = this.find_dir(samplePath,'xml',1);
                this.preload_tiff_headers();         
            end
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

    methods(Access=private)        
        function preload_tiff_headers(this)
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
            for i=1:this.sample.nrOfChannels;
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
            if isempty(this.xmlData)
                this.processXML();
            end
            index=[];
            %index=[1:this.xmlData.num_events];
            if ~isempty(this.xmlData)
                index=find(this.xmlData.score==1|this.xmlData.score==2);
            end
            if isempty(index)
                locations=[];
            else
                for i=1:numel(index)
                    locations(i,:)=this.event_to_pixels_and_frame(index(i));
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
        
        function processXML(this)
            % Process XML file if available
            % determine in which directory the xml file is located.
            NoXML=0;
            this.xmlData = [];
            % find directory where xml file is located in
            if isempty(this.sample.priorPath)
                NoXML=1;
            elseif strcmp(this.sample.priorPath,'No dir found')
                NoXML=1;
            else
                XMLFile = dir([this.sample.priorPath filesep '*.xml']);
            end
            
            if size(XMLFile,1) > 1
                for i = 1:size(XMLFile,1)
                    if find(ismember(strfind(XMLFile(1).name,'.'),1))
                        XMLFile(i) = [];
                    end
                end
            end
                
            % Load & process XML file
            if NoXML == 0
                this.xmlData=xml2struct([this.sample.priorPath filesep XMLFile.name]);
                this.xmlData.num_events = [];
                this.xmlData.CellSearchIds = [];
                this.xmlData.locations = [];
                this.xmlData.score=[];
                this.xmlData.frameNr=[];
                this.xmlData.camYSize=1384;
                this.xmlData.camXSize=1036;

                this.xmlData.num_events = size(this.xmlData.events.record,1);
                this.xmlData.CellSearchIds = zeros(this.xmlData.num_events,1);
                this.xmlData.locations = zeros(this.xmlData.num_events,4);
                this.xmlData.score=zeros(this.xmlData.num_events,1);
                this.xmlData.frameNr=zeros(this.xmlData.num_events,1);
                for i=1:this.xmlData.num_events
                    this.xmlData.CellSearchIds(i)=str2num(this.xmlData.events.record(i).eventnum); %#ok<*ST2NM>
                    this.xmlData.score(i)=str2num(this.xmlData.events.record(i).numselected);                    
                    this.xmlData.frameNr(i)=str2num(this.xmlData.events.record(i).framenum);
                    tempstr=this.xmlData.events.record(i).location;
                    start=strfind(tempstr,'(');
                    finish=strfind(tempstr,')');
                    to=str2num(tempstr(start(1)+1:finish(1)-1));
                    from=str2num(tempstr(start(2)+1:finish(2)-1));
                    this.xmlData.locations(i,:)=[from,to];
                end
                this.sample.columns=str2num(this.xmlData.runs.record.numcols);
                this.sample.rows=str2num(this.xmlData.runs.record.numrows);
                this.xmlData.camYSize=str2num(this.xmlData.runs.record.camysize);
                this.xmlData.camXSize=str2num(this.xmlData.runs.record.camxsize);
            else
                    %notify(this,'logMessage',logmessage(2,['unable to read xml']));
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
                    
            end
        end
       
        
        function [coordinates]=pixels_to_coordinates(this,pixelCoordinates, imgNr)
            row = ceil(imgNr/this.sample.columns) - 1;
            cols = this.sample.columns;
            switch row
                case {1,3,5} 
                    col=(cols-(imgNr-row*this.sample.columns));
                    coordinates(1)=pixelCoordinates(1)+this.xmlData.camXSize*col;
                    coordinates(2)=pixelCoordinates(2)+this.xmlData.camYSize*row;  
                otherwise
                    col=imgNr-1-row*cols;
                    coordinates(1)=pixelCoordinates(1)+this.xmlData.camXSize*col;
                    coordinates(2)=pixelCoordinates(2)+this.xmlData.camYSize*row; 
            end
        end

        function [locations]=event_to_pixels_and_frame(this,eventNr)
            frameNr=this.xmlData.frameNr(eventNr);
            row = ceil(frameNr/this.sample.columns) - 1;
            cols = this.sample.columns;
            switch row
                case {1,3,5} 
                    col=(cols-(frameNr-row*this.sample.columns));
                otherwise
                    col=frameNr-1-row*this.sample.columns;
            end
            xBottomLeft=max(this.xmlData.locations(eventNr,1)-this.xmlData.camXSize*col-10,1);
            yBottomLeft=max(this.xmlData.locations(eventNr,2)-this.xmlData.camYSize*row-10,1);
            xTopRight=min(this.xmlData.locations(eventNr,3)-this.xmlData.camXSize*col+10,this.xmlData.camXSize);
            yTopRight=min(this.xmlData.locations(eventNr,4)-this.xmlData.camYSize*row+10,this.xmlData.camYSize);
            xLocation=min(this.xmlData.locations(eventNr,3));
            yLocation=min(this.xmlData.locations(eventNr,4));
            locations=table(eventNr,frameNr,xBottomLeft,yBottomLeft,xTopRight,yTopRight,xLocation,yLocation);
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
        
    end
        
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            splitPath = regexp(path, filesep, 'split');
            if isempty(splitPath{end})
                id=splitPath{end-1};
            else
                id=splitPath{end};
            end
            name=strsplit(id,'.');
            test=exist(strcat(path,filesep,name{1},'.xml'),'file');
            bool=(test==2);
        end
    end
end

