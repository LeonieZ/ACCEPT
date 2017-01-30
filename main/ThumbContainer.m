classdef ThumbContainer < handle
    %class for use in gui's it contains the overviewimage, tumbnails and
    %segmentation and the logic to load them. For the logic a link to the
    %asociated sample is needed. 
    
    properties
        currentSample = Sample();
        nrOfEvents = []; 
        thumbnails = {};
        segmentation = {};
        overviewImage = [];
        overviewMask = [];
    end
    
    methods
        function this = ThumbContainer(inputSample,thumbNr)
            if isa(inputSample,'Sample') && ~exist('thumbNr','var')
                this.currentSample = inputSample ;
                this.nrOfEvents = size(inputSample.results.thumbnails,1);
                if this.nrOfEvents >= 1
                    this.thumbnails = cell(this.nrOfEvents,1);
                    this.segmentation = cell(this.nrOfEvents,1);
                    this.load_all_thumbs();
                    
                end
                this.overviewImage=IO.load_overview_image(inputSample);
                this.overviewMask=IO.load_overview_mask(inputSample);
            elseif isa(inputSample,'Sample') && exist('thumbNr','var') && isnumeric(thumbNr)
                this.currentSample = inputSample ;
                this.nrOfEvents = size(inputSample.results.thumbnails,1);
                if this.nrOfEvents >= 1
                    this.thumbnails = cell(this.nrOfEvents,1);
                    this.segmentation = cell(this.nrOfEvents,1);
                    this.load_all_thumbs(thumbNr);
                    
                end
                this.overviewImage=IO.load_overview_image(inputSample);
                this.overviewMask=IO.load_overview_mask(inputSample);
            else
                error('Incorrect input type when constructing ThumbContainer. Please provide Sample');
            end
        end
        
        function  outputImage = get.overviewImage(this)
            if isempty(this.overviewImage)
                this.overviewImage = IO.load_overview_image(this.currentSample);
            end
            outputImage = this.overviewImage;
        end
        
        function load_all_thumbs(this,thumbNr)
            if ~exist('thumbNr','var')
                frames=unique(this.currentSample.results.thumbnails.frameNr);
                for i = 1 : numel(frames)
                    rawIm = IO.load_raw_image(this.currentSample,frames(i));
                    rawSeg = IO.load_segmented_image(this.currentSample,frames(i));
                    feature_loc = find(this.currentSample.results.thumbnails.frameNr == frames(i));
                    for j = 1:size(feature_loc,1)
                        curr_loc = feature_loc(j);
                        this.thumbnails{curr_loc} = rawIm(this.currentSample.results.thumbnails.yBottomLeft(curr_loc):this.currentSample.results.thumbnails.yTopRight(curr_loc),...
                        this.currentSample.results.thumbnails.xBottomLeft(curr_loc):this.currentSample.results.thumbnails.xTopRight(curr_loc),:);
                        this.segmentation{curr_loc} = logical(rawSeg(this.currentSample.results.thumbnails.yBottomLeft(curr_loc):this.currentSample.results.thumbnails.yTopRight(curr_loc),...
                        this.currentSample.results.thumbnails.xBottomLeft(curr_loc):this.currentSample.results.thumbnails.xTopRight(curr_loc),:));
                    end
                end
            elseif exist('thumbNr','var') && isnumeric(thumbNr)
                frame = this.currentSample.results.thumbnails.frameNr(thumbNr);
                rawIm = IO.load_raw_image(this.currentSample,frame);
                rawSeg = IO.load_segmented_image(this.currentSample,frame);
                this.thumbnails{1} = rawIm(this.currentSample.results.thumbnails.yBottomLeft(thumbNr):this.currentSample.results.thumbnails.yTopRight(thumbNr),...
                    this.currentSample.results.thumbnails.xBottomLeft(thumbNr):this.currentSample.results.thumbnails.xTopRight(thumbNr),:);
                this.segmentation{1} = logical(rawSeg(this.currentSample.results.thumbnails.yBottomLeft(thumbNr):this.currentSample.results.thumbnails.yTopRight(thumbNr),...
                    this.currentSample.results.thumbnails.xBottomLeft(thumbNr):this.currentSample.results.thumbnails.xTopRight(thumbNr),:));                
            end
                
                
        end
        
    end
    
end