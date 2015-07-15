classdef measurements < workflow_object
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nrObjects = [];
        msrTable = [];
    end
    
    methods
        function self = measurements(dataFrame)
            self.nrObjects = max(dataFrame.labelImage(:));
            self.msrTable = make_table(self,dataFrame);
        end
        
        function tbl = make_table(self,dataFrame)
            tbl = table();
            
            if self.nrObjects > 0
                for ch = 1:size(dataFrame.rawImage,3)
                    imTemp = dataFrame.rawImage(:,:,ch);
                    MsrTemp = regionprops(dataFrame.labelImage(:,:,ch), imTemp - median(imTemp(dataFrame.labelImage(:,:,ch) == 0)),...
                            'MaxIntensity', 'PixelValues', 'MeanIntensity', 'Area', 'Perimeter', 'Eccentricity');
                    
                    %fill structure so tables can be concatenated.
                    MsrTemp=fillStruct(self, MsrTemp);
                    
                    StandardDeviation = arrayfun(@(x) std2(x.PixelValues), MsrTemp);
                    Mass = arrayfun(@(x) sum(x.PixelValues), MsrTemp);
                    P2A = arrayfun(@(x) x.Perimeter^2/(4*pi*x.Area), MsrTemp);
                           
                    MsrTemp=rmfield(MsrTemp,'PixelValues');
                    
                    names = strcat(dataFrame.sample.channelNames(ch),'_',fieldnames(MsrTemp));
                    tmpTable = struct2table(MsrTemp);
                    tmpTable.Properties.VariableNames = names;
                    tmpStandardDeviation = array2table(StandardDeviation,'VariableNames',{strcat(dataFrame.sample.channelNames{ch},'_StandardDeviation')});
                    tmpMass = array2table(Mass,'VariableNames',{strcat(dataFrame.sample.channelNames{ch},'_Mass')});
                    tmpP2A = array2table(P2A,'VariableNames',{strcat(dataFrame.sample.channelNames{ch},'_P2A')});
                    tbl=[tbl tmpTable tmpStandardDeviation tmpMass tmpP2A];
                end
            end
        end

        function MsrTemp=fillStruct(self, MsrTemp)
        numObjects = self.nrObjects;
        numMsr=numel(MsrTemp);
        
        if numMsr ~= numObjects
            if numMsr == 0;
                MsrTemp(1:numObjects)=struct('Area',0,'Eccentricity', 0 ,'Perimeter',0,...
                    'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
            else
                MsrTemp(numMsr+1:numObjects)=struct('Area',0 ,'Eccentricity', 0,...
                    'Perimeter',0, 'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
            end
        end
        idx=arrayfun(@(x) isempty(x.MaxIntensity),MsrTemp);
        MsrTemp(idx)=struct('Area',0 ,'Eccentricity',0,'Perimeter',0,...
        'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );

        end
       
        
    end
end
