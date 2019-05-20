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
classdef ThresholdingSegmentation < DataframeProcessorObject
    % THRESHOLDING_SEGMENTATION 
    % Computes a segmentation of the input frame/image using either Otsu or
    % Triangle method or a fixed threshold.
    
    properties (SetAccess = private)
        thresholds = [];
        maskForChannels = [];
        meth = [];
        range = [];
        offset = [];
    end
    
    properties (Access = public)
        histogram = [];
    end
    
    methods
        function this = ThresholdingSegmentation(meth,range,varargin)
            %specify if otsu, triangle or a fixed treshold 
            validatestring(meth,{'otsu','triangle','manual'});
            this.meth = meth;
            
            %use the global (full sample) or local(frame) histogram
            validatestring(range,{'global','local'});
            this.range = range;
            
            %input custom histogram
            if nargin > 2
                this.histogram = varargin{1};
            end
            
            %determine if a channel mask is used
            if nargin > 3
                this.maskForChannels = varargin{2};  
            end
            
            %determine an offset in each channel (added/subtracted to the
            %automatic threshold)
            if nargin > 4
                this.offset = varargin{3};
            end
            %if manual, determine threshold
            if nargin > 5
                this.thresholds = varargin{4};
            end
            %manual requires a threshold as input
            if strcmp(this.meth,'manual') && isempty(this.thresholds)
                error('Please specify the threshold.')
            end
            
        end
        
        function returnFrame = run(this,inputFrame)
            if isa(inputFrame,'Dataframe')
                %load data
                returnFrame = inputFrame;
                returnFrame.segmentedImage = false(size(inputFrame.rawImage));
                %enough bins for uint16 input data
                bins = 65535;
                
                %fill offset
                if isempty(this.offset)
                    this.offset = zeros(1,inputFrame.nrChannels);
                elseif size(this.offset,2) == 1
                    this.offset = this.offset(1) * ones(1,inputFrame.nrChannels);
                end
                
                %fill mask
                if isempty(this.maskForChannels)
                    this.maskForChannels = 1:1:inputFrame.nrChannels;
                elseif size(this.maskForChannels,2) == 1
                    this.maskForChannels = this.maskForChannels(1) * ones(1,inputFrame.nrChannels);
                end
                
                if size(this.thresholds,2) == 1
                    this.thresholds = this.thresholds(1) * ones(1,inputFrame.nrChannels);
                end
                
                %initialize histogram
                if isempty(this.histogram)
                    this.histogram = zeros(1,bins,inputFrame.nrChannels);
                end

                %create histogram if thresholding is local otherwise we assume
                %this was already done.
                if strcmp(this.range,'local') && ~strcmp(this.meth,'manual')
                    this.create_local_hist(inputFrame);
                end
                
                %calcualte threshold with chosen method (otsu/triangle)
                if ~strcmp(this.meth,'manual')
                    this.calculate_threshold()
                end
                
                %run segmentation for every channel
                for i = 1:inputFrame.nrChannels
                    if any(this.maskForChannels == i)
                        tmp = inputFrame.rawImage(:,:,this.maskForChannels(i)) > this.thresholds(i);
                        if inputFrame.frameHasEdge == true && ~isempty(inputFrame.mask) %set pixels in edge mask to zero
                            tmp(inputFrame.mask) = false;
                        end
                        tmp = bwareaopen(tmp, 3); %remove very small objects
                        returnFrame.segmentedImage(:,:,i) = tmp;  
                    end
                end
                %fill segmentation according to channel mask
                returnFrame.segmentedImage = returnFrame.segmentedImage(:,:,this.maskForChannels);
                %create label image (overlapping object have one label)
                sumImage = sum(returnFrame.segmentedImage,3); 
                labels = repmat(bwlabel(sumImage,4),1,1,returnFrame.nrChannels);
                returnFrame.labelImage = labels.*returnFrame.segmentedImage; 


            elseif isa(inputFrame,'double') || isa(inputFrame,'single') || isa(inputFrame,'uint8') || isa(inputFrame,'uint16')
                % note: 1. in case you are using the TS function on a double/single/... image using a mask is not possible
                % 2. not for images scaled from 0 to 1.
                
                returnFrame = false(size(inputFrame));
                bins = 65535;

                if isempty(this.offset)
                    this.offset = zeros(1,size(inputFrame,3));
                end

                if isempty(this.maskForChannels)
                    this.maskForChannels = 1:1:size(inputFrame,3);
                end
                
                if isempty(this.histogram)
                    this.histogram = zeros(bins,size(inputFrame,3));
                end
                
                if size(this.thresholds,2) == 1
                    this.thresholds = this.thresholds(1) * ones(1,size(inputFrame,3));
                end

                %create histogram if thresholding is local otherwise we assume
                %this was already done.
                if strcmp(this.range,'local') && ~strcmp(this.meth,'manual')
                    this.create_local_hist(inputFrame);
                end
                
                %calcualte threshold with chosen method (otsu/triangle)
                if ~strcmp(this.meth,'manual')
                    this.calculate_threshold()
                end
                
                %run segmentation for every channel
                for i = 1:size(inputFrame,3)
                    tmp = inputFrame(:,:,i) > this.thresholds(i);
                    tmp = bwareaopen(tmp, 10);
                    returnFrame(:,:,i) = tmp;    
                end
            else
                error('Thresholding Segmentation can only be used on dataframe or single/double/uint8/uint16 images.')
            end
        end
        
        function calculate_threshold(this)
            switch this.meth
                case 'otsu'
                    this.thresholds = this.otsu_method() + this.offset;
                case 'triangle'
                    this.thresholds = this.triangle_method() + this.offset;
            end
        end
        
        function create_local_hist(this, inputFrame)
            %create histogram for loaded dataframe
            if isa(inputFrame,'Dataframe')
                for j = 1:inputFrame.nrChannels
                    if any(this.maskForChannels == j)                
                        imTemp = inputFrame.rawImage(:,:,j);

                        if inputFrame.frameHasEdge
                            imTemp = imTemp(~inputFrame.mask);
                        end
                        this.histogram(:,j) = histc(imTemp(:),1:1:numel(this.histogram(:,j)))';
                    end
                end
            elseif isa(inputFrame,'double') || isa(inputFrame,'single') || isa(inputFrame,'uint8') || isa(inputFrame,'uint16')
                for j = 1:size(inputFrame,3)
                    if any(this.maskForChannels == j)                
                        imTemp = inputFrame(:,:,j);
                        this.histogram(:,j) = histc(imTemp(:),1:1:numel(this.histogram(:,j)))';
                    end
                end
            end
        end
            
        
        function thresh = otsu_method(this)
            % Function carried over from Matlab function graythresh.
            hist = this.histogram;
            thresh = zeros(1,size(hist,2));
            
            for i = 1:size(hist,2)
                if any(this.maskForChannels == i)
                    % Variable names are chosen to be similar to the formulas in
                    % the Otsu paper.
                    num_bins = size(hist(:,i),1);
                    p = hist(:,i) / sum(hist(:,i));
                    omega = cumsum(p);
                    mu = cumsum(p .* (1:num_bins)');
                    mu_t = mu(end);

                    sigma_b_squared = (mu_t * omega - mu).^2 ./ (omega .* (1 - omega));

                    % Find the location of the maximum value of sigma_b_squared.
                    % if several bins reach max, average
                    maxval = max(sigma_b_squared);
                    isfinite_maxval = isfinite(maxval);
                    if isfinite_maxval
                      thresh(1,i) = mean(find(sigma_b_squared == maxval));
                    else
                      thresh(1,i) = 1.0;
                    end
                end
            end
            thresh = thresh(this.maskForChannels);
        end
        
        function thresh = triangle_method(this)
            % Function carried over from old ACTC script by Sjoerd Ligthart.
            % partly adapted 
            hist = this.histogram;
            thresh = zeros(1,size(hist,2));
            num_bins = size(hist(:,1),1);
            
            for i = 1:size(hist,2)
                if any(this.maskForChannels == i)
                    % function to determine a threshold value using the "triangle threshold"
                    % method. This method determines the maximum distance of the image
                    % histogram to a line from the maximum count to the maximum bin. 

                    % determine maximum counts and index to derive slope
                    hist_temp=smooth(hist(:,i),10)';
                    maxBin = find(hist_temp, 1, 'last');
                    [maxCounts, index]= max(hist_temp);

                    % if maximum number of pixels are saturated, neglect these pixels in
                    % determining the threshold
                    if index == num_bins
                        hist_temp(end) = 0; 
                        [maxCounts, index]= max(hist_temp);
                    end
                    rcRamp = (hist_temp(maxBin)-maxCounts)/(maxBin-index);

                    % solve linear equation ax+b=-(x-c)/a+d for x
                    % solution: x = (d-b+c/a)/(a+1/a)
                    xCrossing = (hist_temp(index:maxBin)-maxCounts+((index:1:maxBin)-index)/rcRamp)/(rcRamp+1/rcRamp);
                    yCrossing = rcRamp*xCrossing + maxCounts;

                    distToRamp = sqrt((xCrossing-(index:1:maxBin)).^2+(yCrossing-hist_temp(index:maxBin)).^2);
                    [~, thresh_temp] = max(distToRamp);
                    
                    if  ~isempty(thresh_temp)
                        thresh(1,i) = thresh_temp+index-1;
                    else
                        thresh(1,i) = 0;
                    end
                end
            end  
            thresh(find(this.maskForChannels ~=0)) = thresh(find(this.maskForChannels ~=0));
        end
        
    end
    
end