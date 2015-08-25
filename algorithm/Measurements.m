classdef Measurements < DataframeProcessorObject
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nrObjects = [];
        msrTable = table();
    end
    
    methods
        function returnFrame = run(this,inputFrame)
            returnFrame = inputFrame;
            this.nrObjects = max(inputFrame.labelImage(:));

            if this.nrObjects > 0
                for ch = 1:inputFrame.nrChannels
                    imTemp = inputFrame.rawImage(:,:,ch);
                    MsrTemp = regionprops(inputFrame.labelImage(:,:,ch), imTemp - median(imTemp(inputFrame.labelImage(:,:,ch) == 0)),...
                            'MaxIntensity', 'PixelValues', 'MeanIntensity', 'Area', 'Perimeter', 'Eccentricity');
                    
                    %fill structure so tables can be concatenated.
                    MsrTemp=fillStruct(this, MsrTemp);
                    
                    StandardDeviation = arrayfun(@(x) std2(x.PixelValues), MsrTemp);
                    Mass = arrayfun(@(x) sum(x.PixelValues), MsrTemp);
                    P2A = arrayfun(@(x) x.Perimeter^2/(4*pi*x.Area), MsrTemp);
                           
                    MsrTemp=rmfield(MsrTemp,'PixelValues');
                    
                    names = strcat('ch_',num2str(ch),'_',fieldnames(MsrTemp));
                    tmpTable = struct2table(MsrTemp);
                    tmpTable.Properties.VariableNames = names;
                    tmpStandardDeviation = array2table(StandardDeviation,'VariableNames',{strcat('ch_',num2str(ch),'_StandardDeviation')});
                    tmpMass = array2table(Mass,'VariableNames',{strcat('ch_',num2str(ch),'_Mass')});
                    tmpP2A = array2table(P2A,'VariableNames',{strcat('ch_',num2str(ch),'_P2A')});
                    this.msrTable=[this.msrTable tmpTable tmpStandardDeviation tmpMass tmpP2A];
                end
            end
            returnFrame.features = this.msrTable;
        end

        function MsrTemp=fillStruct(this, MsrTemp)
            numObjects = this.nrObjects;
            numMsr=numel(MsrTemp);

            if numMsr ~= numObjects
                if numMsr == 0;
                    MsrTemp(1:numObjects,1)=struct('Area',0,'Eccentricity', 0 ,'Perimeter',0,...
                        'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
                else
                    MsrTemp(numMsr+1:numObjects,1)=struct('Area',0 ,'Eccentricity', 0,...
                        'Perimeter',0, 'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
                end
            end
            idx=arrayfun(@(x) isempty(x.MaxIntensity),MsrTemp);
            MsrTemp(idx)=struct('Area',0 ,'Eccentricity',0,'Perimeter',0,...
            'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
        end
       
        
    end
end
