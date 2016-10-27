classdef IcyPluginData < handle
    %Class for loading of the xls files created by the icy plugin.
    
    properties
     
    end
    
    methods
        function locations=prior_locations_in_sample(this,samplePath)
            locations=table();
            [sample.priorPath,bool]=this.find_dir(samplePath,'xls',1);
            xlsfiles=dir([sample.priorPath,'*.xls']);
            thumbSize=[76,76];
            if bool==1 
                if ispc
                    try [~,~,raw]=xlsread([sample.priorPath,filesep,xlsfiles(1).name],1);
                        for i=1:(size(raw,1)-1)
                            eventNr=i;
                            frameNr=str2num(raw{i+1,6})+1;
                            xBottomLeft=round(str2num(raw{i+1,4}))+10-(thumbSize(1)/2);
                            yBottomLeft=round(str2num(raw{i+1,3}))+10-(thumbSize(2)/2);
                            xTopRight=round(str2num(raw{i+1,4}))+9+(thumbSize(1)/2);
                            yTopRight=round(str2num(raw{i+1,3}))+9+(thumbSize(2)/2);
                            location=table(eventNr,frameNr,xBottomLeft,yBottomLeft,xTopRight,yTopRight);
                            locations(i,:)=location;
                        end
                    catch
                        %add logging
                    end
                else 
                    try T=readtable([sample.priorPath,filesep,'result.xls']);
                        for i=1:(size(T,1)-1)
                            eventNr=i;
                            frameNr=str2num(T{i+1,5}{1})+1;
                            xBottomLeft=round(str2num(T{i+1,3}{1}))+10-(thumbSize(1)/2);
                            yBottomLeft=round(str2num(T{i+1,2}{1}))+10-(thumbSize(2)/2);
                            xTopRight=round(str2num(T{i+1,3}{1}))+9+(thumbSize(1)/2);
                            yTopRight=round(str2num(T{i+1,2}{1}))+9+(thumbSize(2)/2);
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