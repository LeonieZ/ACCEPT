classdef IcyPluginData < handle
    %Class for loading of the xls files created by the icy plugin.
    
    properties
     
    end
    
    methods
        function locations=prior_locations_in_sample(this,samplePath)
            locations=[];
            [sample.priorPath,bool]=this.find_dir(samplePath,'xls',1);
            thumbSize=[50,50];
            if bool==1 
                try [~,~,raw]=xlsread([sample.priorPath,filesep,'result.xls'],1);
                    for i=1:(size(raw,1)-1)
                        eventNr(i)=i;
                        frameNr(i)=str2num(raw{i+1,6})+1;
                        xBottomLeft(i)=str2num(raw{i+1,3})-thumbSize(1)/2;
                        yBottomLeft(i)=str2num(raw{i+1,4})-thumbSize(2)/2;
                        xTopRight(i)=str2num(raw{i+1,3})+thumbSize(1)/2;
                        yTopRight(i)=str2num(raw{i+1,4})+thumbSize(2)/2;
                    end
                    locations=table(eventNr,frameNr,xBottomLeft,yBottomLeft,xTopRight,yTopRight);
                catch
                    %add logging
                end
            else
                %add logging
            end
        end
    end
end