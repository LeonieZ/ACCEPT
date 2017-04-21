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
classdef (Abstract) Loader < handle
    %LOADER abstract loading class  
    %   The io class needs input for each data type. The loader class
    %   defines the functions which must be implemented in its subclasses
    %   so that the io class is able to load the appropriate data. 
    
    properties(Abstract)
        name
        hasEdges
        pixelSize
        channelNames
        channelEdgeRemoval
        sample 
    end
    
    events
        logMessage
    end
    
    
    methods(Abstract)
        new_sample_path(this,samplePath)
        update_prior_infos(this,currentSample,samplePath)
        dataFrame = load_data_frame(this,frameNr)
%         dataFrame = load_thumb_frame(this,frameNr,option)
        frameOrder = calculate_frame_nr_order(this)
    end
   
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            bool=false;
        end
        
        function [Dir_out, bool] = find_dir(Dir_in,fileExtension,numberOfFiles)
            % function to verify in which directory the tiff files are located. There
            % are a few combinations present in the immc databases:
            % immc38: dirs with e.g. .1.2 have a dir "processed" in cartridge dir, dirs
            % without "." too "171651.1.2\processed\"
            % immc26: dirs with name of cartridge, nothing else: "172182\mic06122006e7\"
            % imcc26: dirs with e.g. .1.2: "173765.1.1\173765.1.1\processed\"
           

            CurrentDir = Dir_in;

            % count iterations, if more than 10, return with error.
            it = 0;

            % if nothing is found, return error -1
            Dir_out = 'No dir found';
            bool = false;
            
            while it < 10
                it = it + 1;
                if numel(dir([CurrentDir filesep '*.' fileExtension])) >= numberOfFiles
                    Dir_out = CurrentDir;
                    bool = true;
                    break
                else
                    FilesDirs = dir(CurrentDir);
                    if size(FilesDirs,1)> 2
                        DirCount = 0;
                        for ii = 1:size(FilesDirs,1)
                            if FilesDirs(ii).isdir && ~strcmp(FilesDirs(ii).name, '.') && ~strcmp(FilesDirs(ii).name, '..') && ~strcmp(FilesDirs(ii).name, '.DS_Store')
                                DirCount = DirCount + 1;
                                NewDir = FilesDirs(ii).name;
                            end
                        end
                        if DirCount == 1
                            CurrentDir = [CurrentDir filesep NewDir];
                        elseif DirCount == 0
                            break
                        else
                            % if more than 1 directory is found, end search with error
                            Dir_out = 'More than one dir found';
                            break
                        end
                    end
                end
            end
        end
               
    end
end

