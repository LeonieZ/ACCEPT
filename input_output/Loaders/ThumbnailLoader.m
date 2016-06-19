classdef ThumbnailLoader < Loader
    %CELLSEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='ThumbnailLoader';
        sample=Sample();
        hasEdges=false;
        rescaleTiffs=false;
        pixelSize=0.64;
        channelNames={'ExclMarker','NuclMarker','InclMarker','Marker1','Marker2','Marker3'};
        channelRemapping=[1,2,3,4,5,6;1,2,3,4,5,6];
        channelEdgeRemoval=1;      
    end
    
    methods
        function this = ThumbnailLoader(input) %pass either a sample or a path to the constructor
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
            [this.sample.imagePath,~] = this.find_dir(samplePath,'tif',1); 
            [this.sample.priorPath,~] = this.find_dir(samplePath,'txt',1); 
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
            this.sample.results = Result();
            this.sample.overviewImage = [];
            this.sample.histogram = [];
            this.sample.mask = [];
        end
   
        function dataFrame = load_data_frame(this,frameNr,varargin)
            dataFrame = Dataframe(frameNr,...
            false,...
            this.channelEdgeRemoval,...
            this.read_im(frameNr,varargin{:}));
            name = strsplit(this.sample.imageFileNames{frameNr},'.');
            if exist([name{1} '_segm.tif'], 'file') == 2
                dataFrame.segmentedImage = this.read_segm(frameNr);
                sumImage = sum(dataFrame.segmentedImage,3); 
                labels = repmat(bwlabel(sumImage,8),1,1,size(dataFrame.segmentedImage,3));
                dataFrame.labelImage = labels.*dataFrame.segmentedImage;
            end
        end
        
        
       function frameOrder = calculate_frame_nr_order(this)
       end
    end

    methods(Access=private)
        
        function preload_tiff_headers(this)
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
            this.sample.nrOfChannels=numel(this.sample.tiffHeaders{1});
        end
        
        function rawImage=read_im(this,imageNr)
            % use the previously gathered imageinfo and read all images in a multipage
            % tiff. read only one channel if a channel is specified.
            rawImage = zeros(this.sample.tiffHeaders{imageNr}(1).Height,this.sample.tiffHeaders{imageNr}(1).Width, size(this.sample.tiffHeaders{imageNr},1));
            for i=1:this.sample.nrOfChannels;
                try
                    imagetemp = double(imread(this.sample.imageFileNames{imageNr},i, 'info',this.sample.tiffHeaders{imageNr}));
                catch
                    notify(this,'logMessage',LogMessage(2,['Tiff', this.sample.imageFileNames{imageNr}, 'from channel ' num2str(i) ' is not readable!'])) ;
                    return
                end               
                rawImage(:,:,this.channelRemapping(1,i))=imagetemp;
            end
        end 
        
        function segmImage=read_segm(this,imageNr)
            % use the previously gathered imageinfo and read all images in a multipage
            % tiff. read only one channel if a channel is specified.
            segmImage = zeros(this.sample.tiffHeaders{imageNr}(1).Height,this.sample.tiffHeaders{imageNr}(1).Width, size(this.sample.tiffHeaders{imageNr},1));
            for i=1:this.sample.nrOfChannels;
                try
                    name = strsplit(this.sample.imageFileNames{imageNr},'.');
                    imagetemp = imread([name{1} '_segm.tif'], i);
                catch
                    notify(this,'logMessage',LogMessage(2,['Segmentation from Tiff', this.sample.imageFileNames{imageNr}, 'from channel ' num2str(i) ' is not readable!'])) ;
                    return
                end               
                segmImage(:,:,this.channelRemapping(1,i))=imagetemp;
            end
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

