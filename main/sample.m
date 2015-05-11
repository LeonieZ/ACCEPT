classdef sample < handle
    %sample class contains sample specific information
    %It also contains results for the entire sample. Sample wide results
    %are not directly writable but require the use of class methods. 
    
    
    %Raw image dimensions:[x-axis,y-axis,fluophore]
    %the channel order should be discussed as a starting point the
    %following convention is used:
    %The first channel = exclusion marker
    %second channel = DNA marker
    %third channel = inclusion marker
    %additional channels = extra markers
    
    
    properties (SetAccess=private)
        io;
        type='Default'; % this can be replaced with a specific data type such as CellSearch. 
        removeEdges = false; % do we need to removeEdges using this datatype (for example CellSearch )

        % We will have to discuss our naming convention. I think we should keep
        % track of both the flouphore and its target, but it gets confusing \G.
        channelNames={'CD45','DNA','CK','Empty'};
        numChannels = 4;
        channelEdgeRemoval=4;
        measurements=table();
        classeficationResults=table();
    end

    methods
        function obj=sample(io,type,removeEdges,channelNames,channelEdgeRemoval)
            obj.io=io;
            obj.type=type;
            obj.removeEdges=removeEdges;
            obj.channelNames=channelNames;
            obj.numChannels=numel(channelNames);
            obj.channelEdgeRemoval=channelEdgeRemoval;
        end
        function add_measurements(obj,frameNr,measurements)
            obj.measurements=cat(obj.measurements,measurements);
        end
        function add_classefication_results(obj,frameNr,classeficationResults)
            obj.classeficationResults=cat(obj.classeficationResults,classeficationResults);
        end
    end
end
