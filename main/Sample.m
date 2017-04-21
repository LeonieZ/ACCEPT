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
classdef Sample < handle
    %sample class contains sample specific information
    %It also contains results for the entire sample. Sample wide results
    %are not directly writable but require the use of class methods. 
    
    
    %Raw image dimensions:[x-axis,y-axis,fluophore]
    %the channel order should be discussed, as a starting point the
    %following convention is used:
    %The first channel = exclusion marker
    %second channel = DNA marker
    %third channel = inclusion marker
    %additional channels = extra markers
    
    
    properties (SetAccess={?Loader,?IO})
        id='Empty' %the sample name or identifier.
        type='Default'; % this can be replaced with a specific data type such as CellSearch. 
        hasEdges = false; % do we need to removeEdges using this datatype (for example CellSearch )

        % We will have to discuss our naming convention. I think we should keep
        % track of both the flouphore and its target, but it gets confusing \G.
        imageSize=[0,0]
        nrOfFrames=0;
        nrOfChannels = 4;
        channelNames={'CD45','DNA','CK','Empty'};
        channelEdgeRemoval=4;
        dataTypeOriginalImage='uint16';
        pixelSize=1;
        priorLocations=[];
    end
    
    properties (SetAccess={?Loader,?IO,?Base})
        results=Result();
    end
    
    properties (SetAccess={?Loader,?IO,?SampleOverviewLoading})
        overviewImage=[];
        histogram = [];
    end 
    
    properties (SetAccess={?Loader,?IO,?SampleOverviewLoading,?MaskDetermination})
        histogram_down = [];
    end
    
    properties (SetAccess={?Loader,?IO,?MaskDetermination})
        mask=[];
    end
    
    properties (Access={?Loader,?IO,?SampleOverviewLoading})
        loader
        savePath
        rows
        columns
        frameOrder
    end
    
    properties (Access={?Loader, ?IO})
        imagePath
        priorPath
        imageFileNames
        tiffHeaders
        segmentationHeaders
        segmentationFileNames
    end
    
    methods
        function this = Sample(name,type,pixelSize,hasEdges,channelNames,channelEdgeRemoval,nrOfFrames,priorLocations)
            if nargin==8
                this.id=name;
                this.type=type;
                this.pixelSize=pixelSize;
                this.hasEdges=hasEdges;
                this.channelNames=channelNames;
                this.nrOfChannels=numel(channelNames);
                this.channelEdgeRemoval=channelEdgeRemoval;
                this.nrOfFrames=nrOfFrames;
                this.priorLocations=priorLocations;
            end      
        end
       
    end
end
