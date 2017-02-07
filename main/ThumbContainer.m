classdef ThumbContainer < handle
    %class for use in gui's it contains the overviewimage, tumbnails and
    %segmentation and the logic to load them. For the logic a link to the
    %asociated sample is needed. 
    
    properties
        currentSample = Sample();
        nrOfEvents = []; 
        thumbnails = {};
        segmentation = {};
        labelFullImage = {};
        labelThumbImage = {};
        thumbnailLoaded = [];
        overviewImage = [];
        overviewMask = [];
    end
    
    methods
        function this = ThumbContainer(inputSample)
            if isa(inputSample,'Sample')
                this.currentSample = inputSample ;
                this.nrOfEvents = size(inputSample.results.thumbnails,1);
                if this.nrOfEvents >= 1
                    this.thumbnails = cell(this.nrOfEvents,1);
                    this.segmentation = cell(this.nrOfEvents,1);
                    this.thumbnailLoaded = false(this.nrOfEvents,1);
                end
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
        
        function  outputImage = get.overviewMask(this)
            if isempty(this.overviewImage)
                this.overviewImage = IO.load_overview_mask(this.currentSample);
            end
            outputImage = this.overviewMask;
        end
         
        function load_thumbs(this,thumbNr)
            frames=[];
            if ~exist('thumbNr','var')
                frames=unique(this.currentSample.results.thumbnails.frameNr(~this.thumbnailLoaded));
            elseif exist('thumbNr','var') && isnumeric(thumbNr)
                if  ~this.thumbnailLoaded(thumbNr)
                    frames=this.currentSample.results.thumbnails.frameNr(thumbNr);
                end
            end
            if ~isempty(frames)    
                for i = 1 : numel(frames)
                    rawIm = IO.load_raw_image(this.currentSample,frames(i));
                    rawSeg = IO.load_segmented_image(this.currentSample,frames(i));
                    sumImage = sum(rawSeg,3);
                    labels = repmat(bwlabel(sumImage,4),1,1,size(rawSeg,3));
                    rawLabelImage = labels.*double(rawSeg);

                    feature_loc = find(this.currentSample.results.thumbnails.frameNr == frames(i));
                    for j = 1:size(feature_loc,1)
                        curr_loc = feature_loc(j);
                        this.thumbnails{curr_loc} = rawIm(this.currentSample.results.thumbnails.yBottomLeft(curr_loc):this.currentSample.results.thumbnails.yTopRight(curr_loc),...
                                this.currentSample.results.thumbnails.xBottomLeft(curr_loc):this.currentSample.results.thumbnails.xTopRight(curr_loc),:);
                        this.segmentation{curr_loc} = logical(rawSeg(this.currentSample.results.thumbnails.yBottomLeft(curr_loc):this.currentSample.results.thumbnails.yTopRight(curr_loc),...
                                this.currentSample.results.thumbnails.xBottomLeft(curr_loc):this.currentSample.results.thumbnails.xTopRight(curr_loc),:));   
                        this.labelFullImage{curr_loc} = rawLabelImage(this.currentSample.results.thumbnails.yBottomLeft(curr_loc):this.currentSample.results.thumbnails.yTopRight(curr_loc),...
                                this.currentSample.results.thumbnails.xBottomLeft(curr_loc):this.currentSample.results.thumbnails.xTopRight(curr_loc),:);
                        sumImageSmall = sum(this.segmentation{curr_loc},3);
                        labelsSmall = repmat(bwlabel(sumImageSmall,4),1,1,size(this.segmentation{curr_loc},3));
                        this.labelThumbImage{curr_loc} = labelsSmall.*double(this.segmentation{curr_loc});
                    end
                    this.thumbnailLoaded(feature_loc)=true;
                end
            end
        end
     
        
        function varargout = subsref(obj,s)
            %subrefs implementation from template \g see code patterns for 
            %subsref and subsagn method in matlab documentation 
            switch s(1).type
                case '.'
                 if length(s) == 1 
                    % Implement obj.thumbnails
                    prop=s(1).subs;
                    if (strcmp(prop,'thumbnails') || strcmp(prop,'segmentation') || strcmp(prop,'labelFullImage') || strcmp(prop,'labelThumbImage'))
                        obj.load_thumbs();
                    elseif strcmp(prop,'labelThumbImage')
                        obj.load_thumb_label();
                    end
                    
                    varargout = {obj.(prop)};
                 elseif length(s) == 2 && strcmp(s(2).type,'{}') && (strcmp(s(1).subs,'thumbnails') || strcmp(s(1).subs,'segmentation') ||...
                         strcmp(s(1).subs,'labelFullImage') || strcmp(s(1).subs,'labelThumbImage'))
                    % Implement obj.PropertyName(indices)
                    prop=s(1).subs;
                    index=s(2).subs;
                    if numel(index)==1
                      obj.load_thumbs(index{1});
                    else
                        error('Not a supported indexing expression')
                    end
                    if numel(s(2).subs{1})==1
                        varargout = obj.(prop)(s(2).subs{1});
                    else
                        varargout = {obj.(prop)(s(2).subs{1})};    
                    end
                 else
                    varargout = {builtin('subsref',obj,s)};
                 end
              case '()'
                    % Use built-in for any other expression
                    varargout = {builtin('subsref',obj,s)};
              case '{}'
                    % Use built-in for any other expression
                    varargout = {builtin('subsref',obj,s)};
               otherwise
                 error('Not a valid indexing expression')
            end
        end
    end
    
end