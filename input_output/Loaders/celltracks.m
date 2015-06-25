classdef celltracks < loader
    %CELLSEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tiffDir
        xmlDir
        
    end
    
    methods
        function obj = cellsearch(samplePath)
            obj.tiffDir = find_dir(samplePath,'tif',100);
            obj.xmlDir = find_dir(samplePath,'xml',1);
            
        end
        
        function sample=load_sample(obj)
        end
        
        function dataFrame=load_data_frame(obj)
        end
       
        function [curr_image, Error_out]= readImAndScale(dataP, varargin)
            % use the previously gathered imageinfo and read all images in a multipage
            % tiff. read only one channel if a channel is specified. Rescale and
            % stretch values and rescale to approx old values if the image is a
            % celltracks tiff: scales IMMC images back to 0..4095 scale. Otherwise a
            % normal tiff is returned.


            Error_out = '';

            if numel(varargin)==1
                imageNumber=varargin{1};
                allChannels=true;
                channels=numel(dataP.temp.imageinfos{imageNumber});

                curr_image = zeros(dataP.temp.imageinfos{imageNumber}(1).Height,...
                                   dataP.temp.imageinfos{imageNumber}(1).Width,...
                                   channels, 'uint16');
                for i=1:channels
                [curr_image(:,:,i),Error_out] = loadOneChannel(dataP,imageNumber,i);
                end

            elseif numel(varargin)==2
                imageNumber=varargin{1};
                allChannels=false;
                channel=varargin{2};
                [curr_image(:,:),Error_out] = loadOneChannel(dataP,imageNumber,channel);
            else
                curr_image=[];
                Error_out='incorrect number of variables passed to readImAndScale';
                return
            end %function

            end

        function [imageout,Error_out]=loadOneChannel(dataP,imageNumber,channel)
                %check if this preallocation is needed? \G
                imagetemp = zeros(dataP.temp.imageinfos{imageNumber}(channel).Height,...
                                 dataP.temp.imageinfos{imageNumber}(channel).Width,...
                                 1, 'uint8');
                imageout = zeros(dataP.temp.imageinfos{imageNumber}(channel).Height,...
                                 dataP.temp.imageinfos{imageNumber}(channel).Width,...
                                 1, 'uint16');
                Error_out = '';
                try
                    imagetemp = imread(dataP.temp.imageFileNames{imageNumber}, channel, 'info',dataP.temp.imageinfos{imageNumber});
                    imageout  = uint16(imagetemp);
                catch
                    Error_out = ['Tiff from channel ' num2str(ch) ' is not readable!'];
                return
                end
                if dataP.scaleData == true && dataP.temp.imagesAreFromCT == true
                    UnknownTags = dataP.temp.imageinfos{imageNumber}(channel).UnknownTags;

                    LowValue  =  UnknownTags(2).Value;
                    HighValue =  UnknownTags(3).Value;


                    % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
                    imageout = LowValue + imageout * ((HighValue-LowValue)/max(imageout(:)));
                end
        end
            
        function [dataP, Success_out] = get_image_filenames(dataP, input_cartridge)
            % find tiff dir and place file names in dataP.temp Struct.

            path_input_cartridge = fullfile(dataP.input_folder, input_cartridge);

            tiff_dir  = FindTiffDir(path_input_cartridge);

            if strcmp(tiff_dir, 'No Tiff dir found') || strcmp(tiff_dir, 'More than one dir found')
                Success_out = tiff_dir;
                return
            else
                imageFileNames = dir([tiff_dir filesep '*.tif']);
                Success_out='tiff dir found';
            end

            for i=1:numel(imageFileNames)
             dataP.temp.imageFileNames{i} = [tiff_dir filesep imageFileNames(i).name];  
            end
        end
        
        function dataP = get_image_info(dataP)
            %function to fill the dataP.temp.imageinfos variable

            for i=1:numel(dataP.temp.imageFileNames)
                dataP.temp.imageinfos{i}=imfinfo(dataP.temp.imageFileNames{i});
            end

            %check if image is CellTracks image
            try tags=dataP.temp.imageinfos{1}(1).UnknownTags;
                for i=1:numel(tags)
                    if tags(i).ID==754
                        dataP.temp.imagesAreFromCT=true;
                    end
                end
            catch dataP.temp.imagesAreFromCT=false;
            end

            %Have to add a check for the 2^15 offset.
            dataP.temp.imagesHaveOffset=false;
            %have to add a comparison for the number of channels found and provided in
            %dataP.
            dataP.temp.imageSize=[dataP.temp.imageinfos{1}(1).Height dataP.temp.imageinfos{1}(1).Width numel(dataP.temp.imageinfos{1})];
        end   
        
    end
    methods(Static)
        function bool = can_load_this_folder(self,path)
            %function that must be persent in all loader types to test
            %if the current sample can be loaded by this class. 
            bool=true;
        end
 
    end
    methods(Access=Private)
    
    end
end

function Dir_out = find_dir(Dir_in,fileExtension,numberOfFiles)
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

            while it < 10
                it = it + 1;
                if size(dir([CurrentDir filesep '*.' fileExtension]),1) > numberOfFiles
                    Dir_out = CurrentDir;
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