classdef VyCAP < Loader & IcyPluginData
    %MCBP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='VyCAP'
        hasEdges='false'
        pixelSize=0.64
        channelNames={''}
        channelEdgeRemoval=1;
        sample=Sample();
        channelRemapping=[];
        tiffHeaders
        channelsUsed={'Reflection','DAPI','PE','Reflection','Marker1','Marker2'};
    end
    
    events

    end
    
    methods
        function this = VyCAP(input) %pass either sample or a path to the constructor
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
            this.sample=Sample();
            this.sample.type = this.name;
            this.sample.loader = @VyCAP;
            splitPath = regexp(samplePath, filesep, 'split');
            if isempty(splitPath{end})
                this.sample.id=splitPath{end-1};
            else
                this.sample.id=splitPath{end};
            end
            this.sample.pixelSize = this.pixelSize;
            this.sample.hasEdges = this.hasEdges;
            this.sample.channelEdgeRemoval = this.channelEdgeRemoval;
            this.load_scan_info(samplePath);
            this.preload_tiff_headers(samplePath);
            this.sample.priorLocations = this.prior_locations_in_sample(samplePath);
            this.calculate_frame_nr_order();
            keyboard
        end
        
        function update_prior_infos(this,currentSample,samplePath)
            this.sample = currentSample;
            if ~exist(currentSample.imagePath,'dir')
                this.load_scan_info(samplePath);
                this.preload_tiff_headers(samplePath);         
            end
            this.sample.priorLocations = this.prior_locations_in_sample(samplePath);
        end
        
        function dataFrame = load_data_frame(this,frameNr,varargin)
            dataFrame = Dataframe(frameNr,...
            this.does_frame_have_edge(frameNr),...
            this.channelEdgeRemoval,...
            this.read_im(frameNr,varargin{:}));
            if ~isempty(this.sample.mask)
                [row, col] = this.frameNr_to_row_col(frameNr);
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
        function load_scan_info(this,samplePath)
            %find text files to extract metadata
            txtDir=[samplePath,filesep,'Scan'];
            txtFile=dir([txtDir filesep '*Scan settings.txt']);
            this.sample.priorPath=samplePath;
            if ~isempty(txtFile)
                    fid=fopen(strcat([txtDir,filesep,txtFile(1).name]));
                    tline = fgetl(fid);
                    i=1;
                    while ischar(tline)
                        settings{i}=tline;
                        tline = fgetl(fid);
                        i=i+1;
                    end
                    fclose(fid);
            end
            this.sample.columns=str2num(settings{6}(10:end));
            this.sample.rows=str2num(settings{7}(10:end));
            this.sample.nrOfChannels=str2num(settings{8}(23:end-1));
            if this.sample.nrOfChannels<=2
                %error
                return
            end
            for i=1:this.sample.nrOfChannels
                this.channelNames{i}=settings{5+i*5}(49:end);
            end
            this.channelRemapping=[];
            for i=1:this.sample.nrOfChannels
            this.channelRemapping(strcmp(this.channelNames,this.channelsUsed{i}))=i;
            end
        end
        
        function preload_tiff_headers(this,samplePath)
            this.sample.imagePath=samplePath;
            for j=1:numel(this.channelRemapping)
                tempImageFileNames = dir([this.sample.imagePath filesep this.channelNames{j} '1' filesep '*' this.channelNames{j} '.tif']);
                for i=1:numel(tempImageFileNames)
                    this.sample.imageFileNames{i,this.channelRemapping(j)} = [this.sample.imagePath filesep this.channelNames{j} '1' filesep tempImageFileNames(i).name];  
                    this.sample.tiffHeaders{i,this.channelRemapping(j)}=imfinfo(this.sample.imageFileNames{i,this.channelRemapping(j)});
                end
            end
            this.sample.imageSize=[this.sample.tiffHeaders{1,1}(1).Height this.sample.tiffHeaders{1,1}(1).Width this.sample.nrOfChannels];
            this.sample.nrOfFrames=numel(tempImageFileNames);
            %need to add a check if nrOfFrames matches to nr of row/collums
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
                boundingBox = {y,x};
                sizex = boundingBox{2}(2)-boundingBox{2}(1)+1;
                sizey = boundingBox{1}(2)-boundingBox{1}(1)+1;
                rawImage = zeros(sizey,sizex,this.sample.imageSize(3));
            end
            for i=1:this.sample.nrOfChannels;
                try
                    imagetemp = double(imread(this.sample.imageFileNames{imageNr,i},'info',this.sample.tiffHeaders{imageNr,i}));
                catch
                    if imageNr>0
                        notify(this,'logMessage',LogMessage(2,['Tiff', this.sample.imageFileNames{imageNr,i}, 'from channel ' num2str(i) ' is not readable!'])) ;
                        return
                    else
                        notify(this,'logMessage',LogMessage(2,['Tiff', ' is missing or is not readable!'])) ;
                        return
                    end
                end
                if max(imagetemp) > 32767
                    imagetemp = imagetemp - 32768;
                end
                rawImage(:,:,i)=imagetemp(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2));
                
            end
        end
        
        function hasEdge=does_frame_have_edge(this,frameNr)
            if this.hasEdges==true
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
            else
                hasEdge=false;
            end
        end
        
        function load_neighbouring_frames(this,sourceFrame,~)
            % to be implemented
            neigbouring_frames=this.calculate_neighbouring_frames(sourceFrame.frameNr);
        
        end
        
        function neigbouring_frames=calculate_neigbouring_frames(this,frameNr)
            % to be implemented
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
        function bool = can_load_this_folder(samplePath)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            txtDir=[samplePath,filesep,'Scan'];
            txtFile=dir([txtDir filesep '*Scan settings.txt']);
            if ~isemtpy(txtFile)
                bool=(exist([txtDir,filesep,txtFile(1).name],'file')==2);
            else
                %no txt file found
                bool=false;
            end
        end
    end
end