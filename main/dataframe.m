classdef dataframe < handle
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
        sample;
        io;
        frameNr=NaN;
        frameHasEdge=false;
        adjacentFrameNrs=[];
        rawImage=[];
        priorLocations=[];
        % need class (uint8, uint12,...), private or public?
%         class = [];

    end
    properties(Access = public)
        preProcessedImage=[];
        labelImage=[];
        measurements=table();
        classificationResults=table();        
        % mask if we want to remove edge (logicals)
        mask = [];
        % need class (uint8, uint12,...), private or public?
        class = [];
    end
      
    methods
        function self = dataframe(Sample,io,frameNr,frameHasEdge,rawImage,priorLocations)
                self.sample=Sample;
                self.io=io;
                self.frameNr=frameNr;
                self.frameHasEdge=frameHasEdge;
                self.rawImage=rawImage;
                self.priorLocations=priorLocations;
         end
    end
end