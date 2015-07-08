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
        channelRemapping=[2,4,3,1,5,6];
        channelEdgeRemoval=2;
        xmlData
    end
   

    
    
    methods
        function self = celltracks(samplePath)
            self.loaderType='celltracks';
            splitPath=regexp(samplePath, filesep, 'split');
            if isempty(splitPath{end})
                self.sampleId=splitPath{end-1};
            else
                self.sampleId=splitPath{end};
            end
            if nargin == 1
                self.imagePath = self.find_dir(samplePath,'tif',100);
                self.priorPath = self.find_dir(samplePath,'xml',1);
            end
        end
        
        function load_sample(self)
            self.preload_tiff_headers();
            self.processXML();
            self.sample=sample(self.sampleId,...
                'celltracks',...
                self.pixelSize,...
                self.hasEdges,...
                self.channelNames(self.channelRemapping([1:self.nrOfChannels])),...
                self.channelEdgeRemoval,...
                self.nrOfFrames);
        end
        
        function dataFrame=load_data_frame(self,frameNr)
            if isempty(self.sample)
                self.load_sample();
            end
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
                    
                    UnknownTags = self.tiffHeaders{imageNr}(i).UnknownTags;

                    LowValue  =  UnknownTags(2).Value;
                    HighValue =  UnknownTags(3).Value;


                    % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
                    rawImage(:,:,self.channelRemapping(i)) = LowValue + imagetemp * ((HighValue-LowValue)/max(imagetemp(:)));
                else
                    rawImage(:,:,self.channelRemapping(i))=imagetemp;
                end
            end
        end

        function hasEdge=does_frame_have_edge(self,frameNr)
            hasEdge=false;
        end
        
        function locations=prior_locations_in_frame(self,frameNr)
            locations=[];
%             if NoXML==0 && size(res.Msr,1) > 0
%             %     Msr = [res.Msr array2table(zeros(size(res.Msr,1),1),'VariableNames',{'CellSearchID'})];
%                 CellSearchID{size(res.Msr,1),1} = '--';
%                 Msr = [res.Msr cell2table(CellSearchID, 'VariableNames',{'CellSearchID'})];
% 
% 
%                 for jj = 1:size(res.Msr,1)
% 
%                     xdim = res.Msr.BoundingBox(jj,4);
%                     ydim = res.Msr.BoundingBox(jj,5);
%                     lower_x = res.Msr.BoundingBox(jj,1);
%                     lower_y = res.Msr.BoundingBox(jj,2);
%                     higher_x = lower_x+xdim;
%                     higher_y = lower_y+ydim;
% 
%                     minloc=pixelsToCoordinates([lower_x, lower_y], res.Msr.ImgNum(jj), xml.columns, xml.camXSize, xml.camYSize);
%                     maxloc=pixelsToCoordinates([higher_x, higher_y], res.Msr.ImgNum(jj), xml.columns, xml.camXSize, xml.camYSize);
% 
%                     overlaps = 0;
%                     overlap=[];
%                     for i=1:size(locations,1)
%                         if ~(locations(i,1)>maxloc(1)||locations(i,2)>maxloc(2)||locations(i,3)<minloc(1)||locations(i,4)<minloc(2))
%                             overlaps = 1;
%                             overlap(i)=(min(locations(i,3),maxloc(1))-max(locations(i,1),minloc(1)))*(min(locations(i,4),maxloc(2))-max(locations(i,2),minloc(2)))/((maxloc(1)-minloc(1))*(maxloc(2)-minloc(2)));
%                         end
%                     end
%                     if overlaps
%                         [a,kk]=max(overlap);
%                         Msr.CellSearchID(jj)=num2cell(xml.CellSearchIds(kk));
%                         Msr.CellSearchIDOverlap(jj)=a;
%                     else
%                         Msr.CellSearchID(jj)=cellstr('--');
%                         Msr.CellSearchIDOverlap(jj)=0;
% 
%                     end
%                 end
%             end
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
                if isfield(self.xmlData,'archive')
                    self.xmlData.num_events = size(self.xmlData.archive{2}.events.record,2);
                    self.xmlData.CellSearchIds = zeros(self.xmlData.num_events,1);
                    locations = zeros(self.xmlData.num_events,4);
                    for i=1:self.xmlData.num_events
                        self.xmlData.CellSearchIds(i)=str2num(self.xmlData.archive{2}.events.record{i}.eventnum.Text); %#ok<*ST2NM>
                        tempstr=self.xmlData.archive{2}.events.record{i}.location.Text;
                        start=strfind(tempstr,'(');
                        finish=strfind(tempstr,')');
                        to=str2num(tempstr(start(1)+1:finish(1)-1));
                        from=str2num(tempstr(start(2)+1:finish(2)-1));
                        locations(i,:)=[from,to];
                    end
                    self.xmlData.columns=str2num(self.xmlData.archive{2}.runs.record.numcols.Text);
                    self.xmlData.rows=str2num(self.xmlData.archive{2}.runs.record.numrows.Text);
                    self.xmlData.camYSize=str2num(self.xmlData.archive{2}.runs.record.camysize.Text);
                    self.xmlData.camXSize=str2num(self.xmlData.archive{2}.runs.record.camxsize.Text);
                elseif isfield(self.xmlData, 'export')
                    self.xmlData.num_events = size(self.xmlData.export{2}.events.record,2);
                    self.xmlData.CellSearchIds = zeros(self.xmlData.num_events,1);
                    locations = zeros(self.xmlData.num_events,4);
                    for i=1:self.xmlData.num_events
                        self.xmlData.CellSearchIds(i)=str2num(self.xmlData.export{2}.events.record{i}.eventnum.Text);
                        tempstr=self.xmlData.export{2}.events.record{i}.location.Text;
                        start=strfind(tempstr,'(');
                        finish=strfind(tempstr,')');
                        to=str2num(tempstr(start(1)+1:finish(1)-1));
                        from=str2num(tempstr(start(2)+1:finish(2)-1));
                        locations(i,:)=[from,to];
                    end
                    self.xmlData.columns=str2num(self.xmlData.export{2}.runs.record.numcols.Text);
                    %     rows=str2num(self.xmlData.export{2}.runs.record.numrows.Text);
                    self.xmlData.camYSize=str2num(self.xmlData.export{2}.runs.record.camysize.Text);
                    self.xmlData.camXSize=str2num(self.xmlData.export{2}.runs.record.camxsize.Text);
                else
                    notify(self,'logMessage',logmessage(2,['unable to read xml']));
                    return
                end
            end
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

