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
    %measurements and classificationResults. Sample specific information
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
    
    properties(Access = public)
        adjacentFrames = [];
        preProcessedImage = [];
        segmentedImage = [];
        features = table();
        classificationResults = table();
        thumbnails=[];
        % mask if we want to remove edge (logicals)
        mask = [];
    end
    
    properties(Dependent)
        labelImage = [];
    end
    
    events
        loadNeigbouringFrames
        logMessage
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
        
        function value = get.labelImage(this)
            %remove doubles at boarder
            sumImage = sum(this.segmentedImage,3); 
            labels = repmat(bwlabel(sumImage,4),1,1,this.nrChannels);
            value = labels.*this.segmentedImage; 
        end
    end
end