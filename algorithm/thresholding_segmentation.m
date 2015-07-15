classdef thresholding_segmentation < workflow_object
    %THRESHOLDING_SEGMENTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        currentFrame = [];
        segmentedFrame = [];
        thresh = [];
    end
    
    methods
        function self = thresholding_segmentation(dataFrame, thresh)
            self.currentFrame = dataFrame.rawImage;
            self.thresh = thresh;
            self.segmentedFrame = false(size(self.currentFrame));
                        
            for i = 1:size(self.currentFrame,3)
                tmp = self.currentFrame(:,:,i) > thresh.thresholds(i);
                if dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask)
                    tmp(dataFrame.mask.mask) = false;
                end
                tmp = bwareaopen(tmp, 6);
                self.segmentedFrame(:,:,i) = tmp;    
            end
        end
    end
    
end

