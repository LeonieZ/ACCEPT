classdef celltracks < loader
    %CELLSEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rescaleTiffs=true;
        pixelSize=0.64;
        imageFileNames
        tiffHeaders
        channelNames={'DNA','CK','Empty','CD45'};
        
    end
   
    events
        logMessage
    end
    
    
    methods
        function self = celltracks(samplePath)
            self.loaderType='celltracks';
            if nargin == 1
            self.imagePath = self.find_dir(samplePath,'tif',100);
            self.priorPath = self.find_dir(samplePath,'xml',1);
            self.preload_tiff_headers();
            end
        end
        
        function load_sample(self)
        end
        
        function dataFrame=load_data_frame(self,frameNr)
            dataFrame=dataframe(self.sample,frameNr,...
                self.does_frame_have_edge(frameNr),...
                self.read_im_and_scale(frameNr),...
                self.prior_locations_in_frame(frameNr));
            addlistener(dataFrame,'loadNeigbouringFrames',@self.load_neigbouring_frames);
        end
        
         
    end
    methods(Access=private)
        function Dir_out = find_dir(self,Dir_in,fileExtension,numberOfFiles)
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
                if numel(dir([CurrentDir filesep '*.' fileExtension])) >= numberOfFiles
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
        
        function preload_tiff_headers(self)
            tempImageFileNames = dir([self.imagePath filesep '*.tif']);
            for i=1:numel(tempImageFileNames)
             self.imageFileNames{i} = [self.imagePath filesep tempImageFileNames(i).name];  
            end
            %function to fill the dataP.temp.imageinfos variable

            for i=1:numel(self.imageFileNames)
                self.tiffHeaders{i}=imfinfo(self.imageFileNames{i});
            end

            %Have to add a check for the 2^15 offset.
            %dataP.temp.imagesHaveOffset=false;
            self.imageSize=[self.tiffHeaders{1}(1).Height self.tiffHeaders{1}(1).Width numel(self.tiffHeaders{1})];
            self.nrOfFrames=numel(self.imageFileNames);
            self.nrOfChannels=numel(self.tiffHeaders{1});
        end
        
        function rawImage=read_im_and_scale(self,imageNr)
            % use the previously gathered imageinfo and read all images in a multipage
            % tiff. read only one channel if a channel is specified. Rescale and
            % stretch values and rescale to approx old values if the image is a
            % celltracks tiff: scales IMMC images back to 0..4095 scale. Otherwise a
            % normal tiff is returned.
            rawImage = zeros(self.imageSize);
            for i=1:self.nrOfChannels;
                try
                    imagetemp = imread(self.imageFileNames{imageNr},i, 'info',self.tiffHeaders{imageNr});
                catch
                    notify(self,'logMessage',logmessage(2,['Tiff from channel ' num2str(ch) ' is not readable!'])) ;
                    return
                end
                if  self.rescaleTiffs 
                    
                    UnknownTags = self.tiffHeaders{imageNr}(channel).UnknownTags;

                    LowValue  =  UnknownTags(2).Value;
                    HighValue =  UnknownTags(3).Value;


                    % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
                    rawImage(:,:,i) = LowValue + imagetemp * ((HighValue-LowValue)/max(imagetemp(:)));
                else
                    rawImage(:,:,i)=imagetemp;
                end
            end
        end

        function hasEdge=does_frame_have_edge(self,frameNr)
        hasEdge=false;
        end
        
        function locations=prior_location_inFrame(self,frameNr)
        locations=[];
        end
        
        function load_neighbouring_frames(self,sourceFrame,~)
        neigbouring_frames=self.calculate_neighbouring_frames();
        
        end
    end
    methods(Static)
        function bool = can_load_this_folder(self,path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            bool=true;
%                         %check if image is CellTracks image
%             try tags=dataP.temp.imageinfos{1}(1).UnknownTags;
%                 for i=1:numel(tags)
%                     if tags(i).ID==754
%                         dataP.temp.imagesAreFromCT=true;
%                     end
%                 end
%             catch dataP.temp.imagesAreFromCT=false;
%             end
        end
 
    end
end

