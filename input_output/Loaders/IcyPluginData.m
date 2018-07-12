%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 
classdef IcyPluginData < handle
    %Class for loading of the xls files created by the icy plugin.
    
    properties
     
    end
    
    methods
        function locations=prior_locations_in_sample(this,samplePath)
            locations=table();
            [sample.priorPath,bool]=this.find_dir(samplePath,'xls',1);
            xlsfiles=dir([sample.priorPath,filesep,'*.xls']);
            thumbSize=[100,100];

            if bool==1 
                if ispc
                    try [~,~,raw]=xlsread([sample.priorPath,filesep,xlsfiles(1).name],1);
                        index_name = ismember(raw(1,:),'Name');
                        offset = find(ismember(raw(:,index_name),'detectedROI'),1)-1;
                        startLoc = find(ismember(raw(1,:),'Position X'));
                        for i=1:(size(raw,1)-offset)
                            eventNr=i;
                            markersize = round(str2num(raw{offset+1,startLoc+5})/2);
                            frameNr=str2num(raw{i+offset,startLoc+3})+1;
                            yBottomLeft=max(1,round(str2num(raw{i+offset,startLoc+1}))+markersize-(thumbSize(1)/2));
                            xBottomLeft=max(1,round(str2num(raw{i+offset,startLoc}))+markersize-(thumbSize(2)/2));
                            yTopRight=round(str2num(raw{i+offset,startLoc+1}))+markersize+(thumbSize(1)/2);
                            xTopRight=round(str2num(raw{i+offset,startLoc}))+markersize+(thumbSize(2)/2);
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
                            markersize = round(str2num(T{1+offset,startLoc+5}{1})/2);
                            frameNr=str2num(T{i+offset,startLoc+3}{1})+1;
                            yBottomLeft=max(1,round(str2num(T{i+offset,startLoc+1}{1}))+markersize-(thumbSize(1)/2));
                            xBottomLeft=max(1,round(str2num(T{i+offset,startLoc}{1}))+markersize-(thumbSize(2)/2));
                            yTopRight=round(str2num(T{i+offset,startLoc+1}{1}))+markersize+(thumbSize(1)/2);
                            xTopRight=round(str2num(T{i+offset,startLoc}{1}))+markersize+(thumbSize(2)/2);
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