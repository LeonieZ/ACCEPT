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
    end
    
    methods
        function this = ThumbContainer(inputSample)
            if isa(inputSample,'Sample')
                this.currentSample = inputSample ;
                this.nrOfEvents = numel(inputSample.results.thumbnails);
                if this.nrOfEvents >= 1
                    this.thumbnails{1:this.nrOfEvents} = [];
                    this.segmentation{1:this.nrOfEvents} =[];
                    this.load_all_thumbs();
                    
                end
                this.overviewImage=IO.load_overview_image(inputSample);
            else
                error('incorrect input type when constructing Thumb container. Please provide Sample');
            end
        end
        
        function  outputImage = get.overviewImage(this)
            if isempty(this.overviewImage)
                this.overviewImage = IO.load_overview_image(this.currentSample);
            end
            outputImage = this.overviewImage;
        end
        
        function load_all_thumbs(this)
            frames=unique(this.currentSample.results.thumbnails.frameNr);
            for i = 1 : numel(frames)
                rawIm = IO.load_raw_image(this.currentSample,frames(i));
                rawSeg = IO.load_segmented_image(this.currentSample,frames(i));
                feature_loc = find(this.currentSample.results.thumbnails.frameNr == frames(i));
                for j = 1:size(feature_loc,1)
                    curr_loc = feature_loc(j);
                    this.thumbnails{curr_loc} = rawIm(this.currentSample.results.thumbnails.yBottomLeft(curr_loc):this.currentSample.results.thumbnails.yTopRight(curr_loc),...
                    this.currentSample.results.thumbnails.xBottomLeft(curr_loc):this.currentSample.results.thumbnails.xTopRight(curr_loc),:);
                    this.segmentation{curr_loc} = rawSeg(this.currentSample.results.thumbnails.yBottomLeft(curr_loc):this.currentSample.results.thumbnails.yTopRight(curr_loc),...
                    this.currentSample.results.thumbnails.xBottomLeft(curr_loc):this.currentSample.results.thumbnails.xTopRight(curr_loc),:);
                end
            end
        end
        
    end
    
end