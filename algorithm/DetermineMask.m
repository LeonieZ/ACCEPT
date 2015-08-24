classdef DetermineMask < WorkflowObject
    %DETERMINE_MASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mask = []
    end
    
    methods        
        function returnFrame = run(this,inputFrame)
            returnFrame = inputFrame;
            this.mask = false(size(inputFrame.rawImage,1),size(inputFrame.rawImage,2));
            se = strel('disk',50);
            %neues dataframe objekt erzeugen mit dem image als rawimage und
            %dann active contour verwenden.
            
            openImg = imopen(inputFrame.rawImage(:,:,inputFrame.channelEdgeRemoval),se);
            helperFrame = Dataframe([],false,[],openImg);
            ac = ActiveContourSegmentation(10000, 50, 1);
            helperFrame = ac.run(helperFrame);
            [r,c] = find(helperFrame.segmentedImage == 1);
            
            % adapt for corner images;
            this.mask(min(r):max(r),min(c):max(c)) = true;
            this.mask = bwmorph(this.mask,'thicken',100);
            returnFrame.mask = this.mask;
        end
    end
    
end

