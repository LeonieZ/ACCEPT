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
classdef Dataframe < handle
    %dataframe holds frame specific data together with pointers to
    %additional information. This class has all the information that is
    %needed to be passed to the different steps of the analysis algoritm.
    %
    %The dataframe class is a handle subclass to avoid unneeded memory
    %duplication as it is passed to functions. Input variables are set at
    %creation and cannot be overwritten. These are: the sample and io
    %classes, frameNr, frameHasEdge, rawImage and priorLocations. Algorithm
    %output variables that can be set are : preProcessedImage, LabelImage,
    %features and classificationResults. Sample specific information
    %such as the names of the different channels are available in the
    %linked sample class. Use the linked io class for actions such as the
    %loading of an adjacent frame or the saving of a labeled image.
    
    %Raw image dimensions:[x-axis,y-axis,fluophore]
    %the channel order should be discussed as a starting point the
    %following convention is used:
    %The first channel = exclusion marker
    %second channel = DNA marker
    %third channel = inclusion marker
    %additional channels = extra markers
    
    properties(SetAccess = private)
        frameNr = NaN;
        frameHasEdge = false;
        rawImage = [];
        nrChannels = [];
        channelEdgeRemoval = [];
    end
    
    properties (SetAccess={?Loader})
        pixelSize = 1;
    end
    
    properties(Access = public)
        adjacentFrames = [];
        preProcessedImage = [];
        segmentedImage = [];
        labelImage = [];
        features = table();
        classificationResults = table();
        thumbnails=[];
        %mask if we want to remove edge (logicals)
        mask = [];
    end
    
%     properties(Dependent)
%         labelImage = [];
%     end
    
    events
        loadNeigbouringFrames
        saveSegmentation
    end
          
    methods
        function this = Dataframe(frameNr,frameHasEdge,channelEdgeRemoval,rawImage)
                this.frameNr=frameNr;
                this.frameHasEdge=frameHasEdge;
                this.channelEdgeRemoval = channelEdgeRemoval;
                this.rawImage=rawImage;
                this.nrChannels = size(this.rawImage,3);
        end
        
    end
end