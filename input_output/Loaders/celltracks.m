classdef celltracks < loader
    %CELLSEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        hasEdges=true;
        rescaleTiffs=true;
        pixelSize=0.64;
        imageFileNames
        tiffHeaders
        channelNames={'DNA','Marker1','CK','CD45','Marker2','Marker3'};
        channelRemapping=[2,4,3,1,5,6;4,1,3,2,5,6];
        channelEdgeRemoval=2;
        xmlData
    end
    
    methods
        function self = celltracks(samplePath)
            self.loaderType='celltracks';
            if nargin == 1
                self=self.new_sample_path(samplePath);
            end
        end
        
        function self=new_sample_path(self,samplePath)
            self.imagePath = self.find_dir(samplePath,'tif',100);
            self.priorPath = self.find_dir(samplePath,'xml',1);
            splitPath=regexp(samplePath, filesep, 'split');
            if isempty(splitPath{end})
                self.sampleId=splitPath{end-1};
            else
                self.sampleId=splitPath{end};
            end
        end
        
        function Sample=load_sample(self)
            self.preload_tiff_headers();
            self.processXML();
            self.sample=sample(self.sampleId,...
                'celltracks',...
                self.pixelSize,...
                self.hasEdges,...
                self.channelNames(self.channelRemapping(2,1:self.nrOfChannels)),...
                self.channelEdgeRemoval,...
                self.nrOfFrames,...
                self.prior_locations_in_sample);
            Sample=self.sample;
        end
        
        function dataFrame=load_data_frame(self,frameNr)
            if isempty(self.sample)
                self.load_sample();
            end
            dataFrame=dataframe(self.sample,frameNr,...
            self.does_frame_have_edge(frameNr),...
            self.read_im_and_scale(frameNr));
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
                    imagetemp = double(imread(self.imageFileNames{imageNr},i, 'info',self.tiffHeaders{imageNr}));
                catch
                    notify(self,'logMessage',logmessage(2,['Tiff from channel ' num2str(ch) ' is not readable!'])) ;
                    return
                end
                if  self.rescaleTiffs 
                    
                    UnknownTags = self.tiffHeaders{imageNr}(i).UnknownTags;

                    LowValue  =  UnknownTags(2).Value;
                    HighValue =  UnknownTags(3).Value;


                    % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
                    rawImage(:,:,self.channelRemapping(1,i)) = LowValue + imagetemp * ((HighValue-LowValue)/max(imagetemp(:)));
                else
                    rawImage(:,:,self.channelRemapping(1,i))=imagetemp;
                end
            end
        end

        function hasEdge=does_frame_have_edge(self,frameNr)
            row = ceil(frameNr/self.xmlData.columns) - 1;
            switch row
                case {0,self.xmlData.rows} 
                    hasEdge=true;
                otherwise
                    col=frameNr-row*self.xmlData.columns;
                    if col==self.xmlData.columns
                        hasEdge=true;
                    elseif col==1
                        hasEdge=true;
                    else
                        hasEdge=false;
                    end 
            end
        end
        
        function locations=prior_locations_in_sample(self)
            index=find(self.xmlData.score==1);
            if isempty(index)
                locations=[];
            else
                for i=1:numel(index)
                    locations(i,:)=self.event_to_pixels_and_frame(index(i));
                end
            end
        end           
        
        function load_neighbouring_frames(self,sourceFrame,~)
            % to be implemented
            neigbouring_frames=self.calculate_neighbouring_frames(sourceFrame.frameNr);
        
        end
        
        function neigbouring_frames=calculate_neigbouring_frames(self,frameNr)
            % to be implemented
            neigbouring_frames=[1,2,3];
        end
        
        function processXML(self)
            % Process XML file if available
            % determine in which directory the xml file is located.
            NoXML=0;
            self.xmlData = [];
            
            % find directory where xml file is located in
            if isempty(self.priorPath)
                NoXML=1;
            else
                XMLFile = dir([self.priorPath filesep '*.xml']);
            end
                
            % Load & process XML file
            if NoXML == 0
                self.xmlData=xml2struct([self.priorPath filesep XMLFile.name]);
                self.xmlData.num_events = [];
                self.xmlData.CellSearchIds = [];
                self.xmlData.locations = [];
                self.xmlData.score=[];
                self.xmlData.frameNr=[];
                self.xmlData.camYSize=1384
                self.xmlData.camXSize=1036;
                if isfield(self.xmlData,'archive')
                    self.xmlData.num_events = size(self.xmlData.archive{2}.events.record,2);
                    self.xmlData.CellSearchIds = zeros(self.xmlData.num_events,1);
                    self.xmlData.locations = zeros(self.xmlData.num_events,4);
                    self.xmlData.score=zeros(self.xmlData.num_events,1);
                    self.xmlData.frameNr=zeros(self.xmlData.num_events,1);
                    for i=1:self.xmlData.num_events
                        self.xmlData.CellSearchIds(i)=str2num(self.xmlData.archive{2}.events.record{i}.eventnum.Text); %#ok<*ST2NM>
                        self.xmlData.score(i)=str2num(self.xmlData.archive{2}.events.record{i}.numselected.Text);                    
                        self.xmlData.frameNr(i)=str2num(self.xmlData.archive{2}.events.record{i}.framenum.Text);
                        tempstr=self.xmlData.archive{2}.events.record{i}.location.Text;
                        start=strfind(tempstr,'(');
                        finish=strfind(tempstr,')');
                        to=str2num(tempstr(start(1)+1:finish(1)-1));
                        from=str2num(tempstr(start(2)+1:finish(2)-1));
                        self.xmlData.locations(i,:)=[from,to];
                    end
                    self.xmlData.columns=str2num(self.xmlData.archive{2}.runs.record.numcols.Text);
                    self.xmlData.rows=str2num(self.xmlData.archive{2}.runs.record.numrows.Text);
                    self.xmlData.camYSize=str2num(self.xmlData.archive{2}.runs.record.camysize.Text);
                    self.xmlData.camXSize=str2num(self.xmlData.archive{2}.runs.record.camxsize.Text);
           
                    
                elseif isfield(self.xmlData, 'export')
                    self.xmlData.num_events = size(self.xmlData.export{2}.events.record,2);
                    self.xmlData.CellSearchIds = zeros(self.xmlData.num_events,1);
                    self.xmlData.locations = zeros(self.xmlData.num_events,4);
                    self.xmlData.score=zeros(self.xmlData.num_events,1);
                    self.xmlData.frameNr=zeros(self.xmlData.num_events,1);
                    for i=1:self.xmlData.num_events
                        self.xmlData.CellSearchIds(i)=str2num(self.xmlData.export{2}.events.record{i}.eventnum.Text);
                        self.xmlData.score(i)=str2num(self.xmlData.export{2}.events.record{i}.numselected.Text);                    
                        self.xmlData.frameNr(i)=str2num(self.xmlData.export{2}.events.record{i}.framenum.Text);
                        tempstr=self.xmlData.export{2}.events.record{i}.location.Text;
                        start=strfind(tempstr,'(');
                        finish=strfind(tempstr,')');
                        to=str2num(tempstr(start(1)+1:finish(1)-1));
                        from=str2num(tempstr(start(2)+1:finish(2)-1));
                        self.xmlData.locations(i,:)=[from,to];
                    end
                    self.xmlData.columns=str2num(self.xmlData.export{2}.runs.record.numcols.Text);
                    self.xmlData.rows=str2num(self.xmlData.export{2}.runs.record.numrows.Text);
                    self.xmlData.camYSize=str2num(self.xmlData.export{2}.runs.record.camysize.Text);
                    self.xmlData.camXSize=str2num(self.xmlData.export{2}.runs.record.camxsize.Text);
                else
                    notify(self,'logMessage',logmessage(2,['unable to read xml']));
                    %setting row and colums based on nrOfImages
                    switch self.nrOfFrames
                        case 210 % 6*35 images
                            self.xmlData.columns=35;
                            self.xmlData.rows=6;
                        case 180 % 5*36 images
                            self.xmlData.columns=36;
                            self.xmlData.rows=5;
                        case 175 % 5*35 images
                            self.xmlData.columns=35;
                            self.xmlData.rows=5;
                        case 170 % 5*34 images
                            self.xmlData.columns=34;
                            self.xmlData.rows=5;
                        case 144 % 4*36 images
                            self.xmlData.columns=36;
                            self.xmlData.rows=4;
                        case 140 % 4*35 images
                            self.xmlData.columns=35;
                            self.xmlData.rows=4;
                    end
                    return
                end
            end
        end
        
        function [coordinates]=pixels_to_coordinates(self,pixelCoordinates, imgNr)
            row = ceil(imgNr/self.xmlData.columns) - 1;
            cols = self.xmlData.columns;
            switch row
                case {1,3,5} 
                    col=(cols-(imgNr-rowself.xmlData.columns));
                    coordinates(1)=pixelCoordinates(1)+self.xmlData.camXSize*col;
                    coordinates(2)=pixelCoordinates(2)+self.xmlData.camYSize*row;  
                otherwise
                    col=imgNr-1-row*cols;
                    coordinates(1)=pixelCoordinates(1)+self.xmlData.camXSize*col;
                    coordinates(2)=pixelCoordinates(2)+self.xmlData.camYSize*row; 
            end
        end

        function [locations]=event_to_pixels_and_frame(self,eventNr)
            frameNr=self.xmlData.frameNr(eventNr);
            row = ceil(frameNr/self.xmlData.columns) - 1;
            cols = self.xmlData.columns;
            switch row
                case {1,3,5} 
                    col=(cols-(frameNr-row*self.xmlData.columns));
                otherwise
                    col=frameNr-1-row*self.xmlData.columns;
            end
            xTopLeft=self.xmlData.locations(eventNr,1)-self.xmlData.camXSize*col;
            yTopLeft=self.xmlData.locations(eventNr,2)-self.xmlData.camYSize*row;
            xBottomRight=self.xmlData.locations(eventNr,3)-self.xmlData.camXSize*col;
            yBottomRight=self.xmlData.locations(eventNr,4)-self.xmlData.camYSize*row;
            locations=table(frameNr,xTopLeft,yTopLeft,xBottomRight,yBottomRight);
        end
        
    end
        
    methods(Static)
        function bool = can_load_this_folder(path)
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

