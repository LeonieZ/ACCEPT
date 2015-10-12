classdef DetermineMask < DataframeProcessorObject
    %DETERMINE_MASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channelEdgeRemoval = []
    end
    
    methods
        function this = DetermineMask(varargin)
            if nargin > 0
                this.channelEdgeRemoval = varargin{1};
            end
        end
        
        function returnFrame = run(this,inputFrame)
            if isa(inputFrame,'Dataframe')
                returnFrame = inputFrame;
                returnFrame.mask = false(size(inputFrame.rawImage,1),size(inputFrame.rawImage,2));
                se = strel('disk',50);
                
                if isempty(this.channelEdgeRemoval)
                    this.channelEdgeRemoval = inputFrame.channelEdgeRemoval;
                end
                
                openImg = imopen(inputFrame.rawImage(:,:,this.channelEdgeRemoval),se);
                ac = ActiveContourSegmentation(10000, 50, 1);
                binImg = ac.run(openImg);
                [r,c] = find(binImg == 1);

                % adapt for corner images;
                returnFrame.mask(min(r):max(r),min(c):max(c)) = true;
                returnFrame.mask = bwmorph(returnFrame.mask,'thicken',100);
            elseif isa(inputFrame,'double')
                returnFrame = false(size(inputFrame,1),size(inputFrame,2));
                se = strel('disk',50);
                
                if isempty(this.channelEdgeRemoval)
                    this.channelEdgeRemoval = 1;
                end
                
                openImg = imopen(inputFrame(:,:,this.channelEdgeRemoval),se);
                ac = ActiveContourSegmentation(10000, 50, 1);
                binImg = ac.run(openImg);
                [r,c] = find(binImg == 1);

                % adapt for corner images;
                returnFrame(min(r):max(r),min(c):max(c)) = true;
                returnFrame = bwmorph(returnFrame,'thicken',100);
            else
                error('Determine Mask can only be used on dataframes or double images.')
            end
        end
    end
    
end

