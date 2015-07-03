classdef thresholding_segmentation < workflow_object
    %THRESHOLDING_SEGMENTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        currentFrame = [];
        segmentedFrame = [];
    end
    
    methods
        function self = thresholding_segmentation(currentFrame, thresh)
            self.currentFrame = currentFrame.rawImage;
            self.segmentedFrame = false(size(self.currentFrame));
                        
            for i = 1:size(self.currentFrame,3)
                self.segmentedFrame(:,:,i) = self.currentFrame(:,:,i) > thresh.thresholds(i);
            end
            
        end
    end
    
end

