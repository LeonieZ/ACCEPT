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
    
    
    properties (SetAccess={?Loader})
        sampleId='Empty' %the sample name or identifier.
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
        results=Result();
    end
    
    properties (Access={?IO,?Loader})
        loader
    end
    properties (Access={?Loader})
        imagePath
        priorPath
        imageFileNames
        tiffHeaders
        rows
        columns
    end
    
    events
        logMessage
    end
    

    methods
        function this=sample(name,type,pixelSize,hasEdges,channelNames,channelEdgeRemoval,nrOfFrames,priorLocations)
            if nargin==8
                this.name=name;
                this.type=type;
                this.pixelSize=pixelSize;
                this.hasEdges=hasEdges;
                this.channelNames=channelNames;
                this.nrOfChannels=numel(channelNames);
                this.channelEdgeRemoval=channelEdgeRemoval;
                this.nrOfFrames=nrOfFrames;
                this.priorLocations=priorLocations;
            end
            notify(this,'logMessage',logmessage(4,['New sample: ',this.name, ' is constructed.']));
                     
        end
        function add_measurements(this,frameNr,measurements)
            this.measurements=[this.measurements; measurements];
        end
        function add_classification_results(this,frameNr,classificationResults)
            this.classificationResults=[this.classificationResults; classificationResults];
        end
        function save_results(this)
        notify(this,'saveResults');
        end
    end
end
