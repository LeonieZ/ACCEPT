classdef sample < handle
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
    
    
    properties (SetAccess=private)
        loaderHandle;
        type='Default'; % this can be replaced with a specific data type such as CellSearch. 
        removeEdges = false; % do we need to removeEdges using this datatype (for example CellSearch )

        % We will have to discuss our naming convention. I think we should keep
        % track of both the flouphore and its target, but it gets confusing \G.
        channelNames={'CD45','DNA','CK','Empty'};
        numChannels = 4;
        channelEdgeRemoval=4;
        numberOfFrames;
        measurements=table();
        classificationResults=table();
    end

    methods
        function self=sample(loaderHandle,type,removeEdges,channelNames,channelEdgeRemoval)
            self.loaderHandle=loaderHandle;
            self.type=type;
            self.removeEdges=removeEdges;
            self.channelNames=channelNames;
            self.numChannels=numel(channelNames);
            self.channelEdgeRemoval=channelEdgeRemoval;
        end
        function add_measurements(self,frameNr,measurements)
            self.measurements=cat(self.measurements,measurements);
        end
        function add_classification_results(self,frameNr,classificationResults)
            self.classificationResults=cat(self.classificationResults,classificationResults);
        end
    end
end
