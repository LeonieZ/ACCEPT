classdef IcyPluginData < handle
    %Class for loading of the xls files created by the icy plugin.
    
    properties
     
    end
    
    methods
        function locations=prior_locations_in_sample(this,samplePath)
            locations=table();
            [sample.priorPath,bool]=this.find_dir(samplePath,'xls',1);
            xlsfiles=dir([sample.priorPath,filesep,'*.xls']);
            thumbSize=[90,90];

            if bool==1 
                if ispc
                    try [~,~,raw]=xlsread([sample.priorPath,filesep,xlsfiles(1).name],1);
                        offset = find(ismember(raw(:,1),'detectedROI'),1)-1;
                        startLoc = find(ismember(raw(1,:),'Position X'));
                        for i=1:(size(raw,1)-offset)
                            eventNr=i;
                            frameNr=str2num(raw{i+offset,startLoc+3})+1;
                            xBottomLeft=round(str2num(raw{i+offset,startLoc+1}))+10-(thumbSize(1)/2);
                            yBottomLeft=round(str2num(raw{i+offset,startLoc}))+10-(thumbSize(2)/2);
                            xTopRight=round(str2num(raw{i+offset,startLoc+1}))+9+(thumbSize(1)/2);
                            yTopRight=round(str2num(raw{i+offset,startLoc}))+9+(thumbSize(2)/2);
                            location=table(eventNr,frameNr,xBottomLeft,yBottomLeft,xTopRight,yTopRight);
                            locations(i,:)=location;
                        end
                    catch
                        %add logging
                    end
                else 
                    try T=readtable([sample.priorPath,filesep,'result.xls']);
                        offset = find(ismember(raw(:,1),'detectedROI'),1)-1;
                        startLoc = find(ismember(raw(1,:),'Position X'));
                        for i=1:(size(T,1)-offset)
                            eventNr=i;
                            frameNr=str2num(T{i+offset,startLoc+3}{1})+1;
                            xBottomLeft=round(str2num(T{i+offset,startLoc+1}{1}))+10-(thumbSize(1)/2);
                            yBottomLeft=round(str2num(T{i+offset,startLoc}{1}))+10-(thumbSize(2)/2);
                            xTopRight=round(str2num(T{i+offset,startLoc+1}{1}))+9+(thumbSize(1)/2);
                            yTopRight=round(str2num(T{i+offset,startLoc}{1}))+9+(thumbSize(2)/2);
                            location=table(eventNr,frameNr,xBottomLeft,yBottomLeft,xTopRight,yTopRight);
                            locations(i,:)=location;
                        end
                    catch
                        %add logging
                    end
                end
            else
                %add logging
            end
        end
    end
end