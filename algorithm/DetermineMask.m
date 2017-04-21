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
                ac = ActiveContourSegmentation(1, 50, 1);
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
                ac = ActiveContourSegmentation(1, 50, 1);
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

