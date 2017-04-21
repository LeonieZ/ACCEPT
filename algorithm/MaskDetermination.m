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
classdef MaskDetermination < SampleProcessorObject
    %DETERMINE_MASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channelEdgeRemoval = []
        maxDist = 0.1;
    end
    
    methods
        function this = MaskDetermination(varargin)
            if nargin > 0 && ~isempty(varargin{1})
                this.channelEdgeRemoval = varargin{1};
            end
            if nargin > 1
                this.maxDist = varargin{2};
            end
        end
        
        function returnSample = run(this,inputSample)
                returnSample = inputSample;
%                 mask_small = false(size(inputSample.overviewImage));
                se = strel('disk',50);
                
                if isempty(this.channelEdgeRemoval)
                    this.channelEdgeRemoval = inputSample.channelEdgeRemoval;
                end
                
                openImg = imopen(inputSample.overviewImage(:,:,this.channelEdgeRemoval),se);
                mask_small = regiongrowing(double(openImg)/max(double(openImg(:))), this.maxDist, [round(size(openImg,1)/2),round(size(openImg,2)/2)]);
                returnSample.mask = bwmorph(~mask_small,'open'); 
                inputSample.histogram_down = inputSample.histogram_down - histc(reshape(inputSample.overviewImage(repmat(returnSample.mask,1,1,inputSample.nrOfChannels)),...
                    numel(inputSample.overviewImage(repmat(returnSample.mask,1,1,inputSample.nrOfChannels)))/inputSample.nrOfChannels,inputSample.nrOfChannels),1:1:65535);
        end
    end
    
end
