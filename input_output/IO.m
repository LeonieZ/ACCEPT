classdef IO < handle
    %this class has only static functions that handle the various input and output operations. It
    %allows for easy loading and saving of different sample types
    
    methods (Static, Access = private)
        %% general functions that are reused in IO
        function location=saved_sample_path(sampleList,sampleNr)
            location=[sampleList.save_path(),'output',filesep,sampleList.sampleNames{sampleNr},'.mat'];
        end
    
        function location=saved_data_frame_path(sample,frameNr)
            location=[sample.savePath,'frames',filesep,sample.id,filesep,num2str(frameNr),'.mat'];
        end
                      
    end
    
    methods(Static)
        %% SampleList handeling functions
        function [sampleNames,loaderUsed] = available_samples(sampleList)
            %creates list of samples from input dir. It also checks if
            %these samples are already processed in the output dir when the
            %overwriteResults attribute is set to false. 
            files = dir(sampleList.inputPath);
            if isempty(files)
                %sampleList.logMessage('inputPath is empty; cannot continue',1,1);
                error('inputDir is empty; cannot continue');
            end

            % select only directory entries from the input listing and remove
            % anything that starts with a .*.
            samples = files([files.isdir] & ~strncmpi('.', {files.name}, 1)); 
            for i=1:numel(samples)
                sampleNames{i}=samples(i).name;
                loaderUsed{i}=IO.check_sample_type([sampleList.inputPath,filesep,samples(i).name],sampleList.loaderTypesAvailable);
            end
        end
        
        function save_sample_processor(smplLst,processor)
            save([smplLst.save_path(),'processed.mat'],'processor','-append','-v7.3');
        end
        
        function export_samplelist_results_summary(sampleList)
            n=numel(sampleList.sampleNames);
            classifications={1:n};
            names={'sampleID'};
            for i=1:n
                i
                try
                currentSample=IO.load_sample(sampleList,i);
                id{i}=currentSample.id;
                classifications{i}=currentSample.results.classification;
                classifiers=classifications{i}.Properties.VariableNames;
                if ~isempty(classifiers)
                    names=cat(2,names,classifiers);
                end
                catch
                end
            end
            names=unique(names,'stable');
            t=id';
            for i=1:n
                for j=2:numel(names)
                    if any(strcmp(classifications{i}.Properties.VariableNames,names(j)))
                        t{i,j}=sum(eval(['classifications{i}.', names{j}]));
                    else
                        t{i,j}=NaN;
                    end
                end
            end
            summary=array2table(t,'VariableNames',unique(names,'stable'));
            writetable(summary,[sampleList.save_path(),'summaryTable.xlsx']);
        end

        %% Sample handeling functions
        function loaderHandle = check_sample_type(samplePath,loaderTypesAvailable)
            %Checks which loader types can load the sample path and chooses
            %the first one on the list. 
            loaderFound=false;
            i=0;
            while ~loaderFound && i < size(loaderTypesAvailable,2)
                i=i+1; 
                loaderFound = loaderTypesAvailable{i}.can_load_this_folder(samplePath);
            end
            loaderHandle=loaderTypesAvailable{i};
        end
        
        function outputSample = load_sample(sampleList,sampleNr,forProc)
            % loads a sample from a sampleList. First checks if this sample
            % has been saved before. If not we look up the loader handle
            % and construct the sample. 
            if nargin < 3
                forProc = 1;
            end
            if exist(IO.saved_sample_path(sampleList,sampleNr),'file')
                load(IO.saved_sample_path(sampleList,sampleNr));
                if forProc == 1
                    loader = currentSample.loader();
                    loader.update_prior_infos(currentSample,[sampleList.inputPath filesep sampleList.sampleNames{sampleNr}]);
                end
                currentSample.savePath=sampleList.save_path;
                outputSample = currentSample;
            else
                loader = sampleList.loaderToBeUsed{sampleNr};
                loader.new_sample_path([sampleList.inputPath filesep sampleList.sampleNames{sampleNr}]);
                outputSample = loader.sample;
                outputSample.savePath=sampleList.save_path();
            end
        end
        
        function save_sample(currentSample)
            % Function to save the sample in a .mat file for later reuse.
            % and mark the sample sample as processed. 
            save([currentSample.savePath,'output',filesep,currentSample.id,'.mat'],'currentSample','-v7.3');
            %do we split this in a seperate function? /g
            load([currentSample.savePath,'processed.mat'],'samplesProcessed');
            samplesProcessed=union(samplesProcessed,{currentSample.id});
            save([currentSample.savePath,'processed.mat'],'samplesProcessed','-append');
        end
        
        function clear_results(currentSample)
            currentSample.results = Result();
        end
        
        function save_results_as_xls(currentSample)
            %export results to a xls/csv file. 
             tempTable=horzcat(currentSample.results.classification,currentSample.results.features);
             if size(tempTable,1) > 0
                 writetable(tempTable,[currentSample.savePath,'output',filesep,currentSample.id,'.xlsx']);
             end
        end
        
        %% DataFrame handeling functions
        function outputFrame = load_data_frame(sample,frameNr)
            % Load data frame using loader linked to sample
            if exist(IO.saved_data_frame_path(sample,frameNr),'file')
                load(IO.saved_data_frame_path(sample,frameNr));
                outputFrame = currentDataFrame;
            else
                loader = sample.loader(sample);
                outputFrame = loader.load_data_frame(frameNr);
            end
        end
        
        function rawImage = load_raw_image(sample,frameNr)
            % Load data frame using loader linked to sample
            loader = sample.loader(sample);
            rawImage = loader.load_raw_image(frameNr);      
        end
        
        function save_data_frame(currentSample,currentDataFrame)
            % Save DataFrame 
            % Check why we dont use the savepath function? /G
            if ~exist([currentSample.savePath,'frames',filesep,currentSample.id],'dir')
                mkdir([currentSample.savePath,'frames',filesep,currentSample.id]);
            end
            save([currentSample.savePath,'frames',filesep,currentSample.id,filesep,num2str(currentDataFrame.frameNr),'.mat'],'currentDataFrame','-v7.3');            
        end
        
        %% Thumbnail functions
        function outputFrame=load_thumbnail_frame(sample,thumbNr,option,rescaled)
             % gets loader from sample and looks for a saved thumbnail. If no thumbnail was created before a new one is generated. 
            loader=sample.loader(sample);
            if exist('option','var') && strcmp('prior',option) && exist('rescaled','var')  && rescaled == false
                if isprop(loader,'rescaleTiffs')
                    loader.rescaleTiffs = false;
                end
            end 
            if exist('option','var')
                if strcmp('prior',option)
                    if isempty(sample.priorLocations)
                        error('This sample contains no prior locations')
                    end
                    frameNr = sample.priorLocations.frameNr(thumbNr);
%                     boundingBox = {[sample.priorLocations.yBottomLeft(thumbNr) sample.priorLocations.yTopRight(thumbNr)],...
%                         [sample.priorLocations.xBottomLeft(thumbNr) sample.priorLocations.xTopRight(thumbNr)]};
                    boundingBox = {[sample.priorLocations.xBottomLeft(thumbNr) sample.priorLocations.xTopRight(thumbNr)],...
                        [sample.priorLocations.yBottomLeft(thumbNr) sample.priorLocations.yTopRight(thumbNr)]};
                    outputFrame=loader.load_data_frame(frameNr,boundingBox);
                end
                if istable(option)
                    frameNr = option.frameNr(thumbNr);
                    boundingBox = {[option.xBottomLeft(thumbNr) option.xTopRight(thumbNr)],...
                        [option.yBottomLeft(thumbNr) option.yTopRight(thumbNr)]};
                    outputFrame=loader.load_data_frame(frameNr,boundingBox);
                end
            else
                if isempty(sample.results.thumbnails)
                    error('This sample contains no thumbnail locations')
                end
                frameNr = sample.results.thumbnails.frameNr(thumbNr);
%                 boundingBox = {[sample.results.thumbnails.yBottomLeft(thumbNr) sample.results.thumbnails.yTopRight(thumbNr)],...
%                     [sample.results.thumbnails.xBottomLeft(thumbNr) sample.results.thumbnails.xTopRight(thumbNr)]};
                boundingBox = {[sample.results.thumbnails.yBottomLeft(thumbNr) sample.results.thumbnails.yTopRight(thumbNr)],...
                    [sample.results.thumbnails.xBottomLeft(thumbNr) sample.results.thumbnails.xTopRight(thumbNr)]};
%                 if exist(this.saved_frame_path(sample,frameNr),'file');
%                     load(this.saved_frame_path(sample,frameNr));
%                     outputFrame=DataFrame(frameNr,currentDataFrame.frameHasEdge,...
%                         currentDataFrame.channelEdgeRemoval,...
%                         currentDataFrame.rawImage(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:));
%                     outputFrame.adjacentFrames=currentDataFrame.adjacentFrames(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:);
%                     outputFrame.preProcessedImage=currentDataFrame.preProcessedImage(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:);
%                     outputFrame.segmentedImage=currentDataFrame.segmentedImage(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:);
%                     outputFrame.mask=currentDataFrame.mask(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:);
%                 else
                    outputFrame=loader.load_data_frame(frameNr,boundingBox);
                if exist([sample.savePath,'frames',filesep,sample.id,filesep,num2str(frameNr,'%03.0f'),'_seg.tif'],'file');
                   outputFrame.segmentedImage=imread([sample.savePath,'frames',filesep,sample.id,filesep,num2str(frameNr,'%03.0f'),'_seg.tif'],...
                   'PixelRegion',boundingBox);
                end
            end
        end
                
        function load_thumbs_to_results(sample)
            %special function that allows for a specific loader.
           loader=sample.loader(sample);
           if isa(loader,'ThumbnailLoader')
               loader.load_thumbs_to_results();
           end
        end
        
        function [thumbnail_images,segmentation]=load_thumbnail(inputSample)
        loader=sample.loader(sample);
        
            
        end
        
        
        function save_data_frame_segmentation(currentSample,currentDataFrame)
            if ~exist([currentSample.savePath,'frames',filesep,currentSample.id],'dir')
                mkdir([currentSample.savePath,'frames',filesep,currentSample.id]);
            end
            t=Tiff([currentSample.savePath,'frames',filesep,currentSample.id,filesep,num2str(currentDataFrame.frameNr,'%03.0f'),'_seg.tif'],'w');
            t.setTag('Photometric',t.Photometric.MinIsBlack);
            t.setTag('Compression',t.Compression.LZW);
            t.setTag('ImageLength',size(currentDataFrame.segmentedImage,1));
            t.setTag('ImageWidth',size(currentDataFrame.segmentedImage,2));
            t.setTag('PlanarConfiguration',t.PlanarConfiguration.Separate);
            t.setTag('BitsPerSample',8);
            t.setTag('SamplesPerPixel',5);
            t.write(uint8(currentDataFrame.segmentedImage));
            t.close;
        end
        
        function save_thumbnail(currentSample,eventNr,option,rescaled,class)
           [id,~] = strtok(currentSample.id,'.');
           
           if ~exist('class','var')
               class = 0;
           end
           
           if exist('option','var') && strcmp('prior',option)
            if ~exist([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs'],'dir')
                mkdir([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs']);
                fid=fopen([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs',filesep,'ACCEPTThumbnails.txt'],'w');
                fclose(fid);
            end
           elseif class ~= 0
            if ~exist([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs_classified'],'dir')
               mkdir([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs_classified']);
               fid=fopen([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs_classified',filesep,'ACCEPTThumbnails.txt'],'w');
               fclose(fid);
            end
           else
            if ~exist([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs'],'dir')
               mkdir([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs']);
               fid=fopen([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,'ACCEPTThumbnails.txt'],'w');
               fclose(fid);
            end
           end
           
           if ~exist('rescaled','var')
               rescaled = true;
           end
           
           if ~exist('class','var')
               class = 0;
           end

           if exist('option','var') && strcmp('prior',option)
                if exist('eventNr','var') && ~isempty(eventNr)
                    currentDataFrame=IO.load_thumbnail_frame(currentSample,eventNr,'prior',rescaled);
                    t=Tiff([currentSample.savePath,'frames',filesep,id,filesep,filesep,'priorThumbs',num2str(eventNr),'_thumb_prior.tif'],'w');
                    t.setTag('Photometric',t.Photometric.MinIsBlack);
                    t.setTag('Compression',t.Compression.LZW);
                    t.setTag('ImageLength',size(currentDataFrame.rawImage,1));
                    t.setTag('ImageWidth',size(currentDataFrame.rawImage,1));
                    t.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
                    if rescaled == false
                        t.setTag('BitsPerSample',8);
                        t.setTag('SamplesPerPixel',1);
                        t.write(uint8(currentDataFrame.rawImage(:,:,1)));
                    else
                        t.setTag('BitsPerSample',16);
                        t.setTag('SamplesPerPixel',1);
                        t.write(uint16(currentDataFrame.rawImage(:,:,1)));
                    end

                    t.close;
                    for j = 2:currentSample.nrOfChannels
                        if rescaled == false
                            imwrite(uint8(currentDataFrame.rawImage(:,:,j)), [currentSample.savePath,'frames',...
                                filesep,id,filesep,'priorThumbs',filesep,num2str(eventNr),'_thumb_prior.tif'], 'writemode', 'append');
                        else
                            imwrite(uint16(currentDataFrame.rawImage(:,:,j)), [currentSample.savePath,'frames',...
                                filesep,id,filesep,'priorThumbs',filesep,num2str(eventNr),'_thumb_prior.tif'], 'writemode', 'append');
                        end
                    end
                else
                    for i = 1:size(currentSample.priorLocations)
                        currentDataFrame=IO.load_thumbnail_frame(currentSample,i,'prior',rescaled);
                        t=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs',filesep, num2str(i),'_thumb_prior.tif'],'w');
                        t.setTag('Photometric',t.Photometric.MinIsBlack);
                        t.setTag('Compression',t.Compression.LZW);
                        t.setTag('ImageLength',size(currentDataFrame.rawImage,1));
                        t.setTag('ImageWidth',size(currentDataFrame.rawImage,2));
                        t.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
                        if rescaled == false
                            t.setTag('BitsPerSample',8);
                            t.setTag('SamplesPerPixel',1);
                            t.write(uint8(currentDataFrame.rawImage(:,:,1)));
                        else
                            t.setTag('BitsPerSample',16);
                            t.setTag('SamplesPerPixel',1);
                            t.write(uint16(currentDataFrame.rawImage(:,:,1)));
                        end
                        t.close;
                        for j = 2:currentSample.nrOfChannels
                          if rescaled == false
                              imwrite(uint8(currentDataFrame.rawImage(:,:,j)), [currentSample.savePath,'frames',...
                                  filesep,id,filesep,'priorThumbs',filesep,num2str(i),'_thumb_prior.tif'], 'writemode', 'append');
                          else
                              imwrite(uint16(currentDataFrame.rawImage(:,:,j)), [currentSample.savePath,'frames',...
                                  filesep,id,filesep,'priorThumbs',filesep,num2str(i),'_thumb_prior.tif'], 'writemode', 'append');
                          end
                        end                            
                    end
                end
           else
                if exist('eventNr','var') && ~isempty(eventNr)
                    if ~isempty(currentSample.results.thumbnail_images{eventNr})
                        data = currentSample.results.thumbnail_images{eventNr}(:,:,1);
    %                     t=Tiff([currentSample.savePath,'frames',filesep,id,filesep, num2str(eventNr),'_thumb.tif'],'w');
                        t=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(eventNr),'_thumb.tif'],'w');
                        t.setTag('Photometric',t.Photometric.MinIsBlack);
                        t.setTag('Compression',t.Compression.LZW);
                        t.setTag('ImageLength',size(currentSample.results.thumbnail_images{eventNr},1));
                        t.setTag('ImageWidth',size(currentSample.results.thumbnail_images{eventNr},2));
                        t.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
                        t.setTag('BitsPerSample',16);
                        t.setTag('SamplesPerPixel',1);
                        t.write(uint16(data));
                        t.close;
                        s=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,num2str(eventNr),'_thumb_segm.tif'],'w');
                        s.setTag('Photometric',t.Photometric.MinIsBlack);
                        s.setTag('Compression',t.Compression.LZW);
                        s.setTag('ImageLength',size(data,1));
                        s.setTag('ImageWidth',size(data,2));
                        s.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
                        s.setTag('BitsPerSample',1);
                        s.setTag('SamplesPerPixel',1);
                        s.write(currentSample.results.segmentation{eventNr}(:,:,1));
                        s.close;
                        for j = 2:currentSample.nrOfChannels
                              imwrite(uint16(currentSample.results.thumbnail_images{eventNr}(:,:,j)), [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(eventNr),'_thumb.tif'], 'writemode', 'append');
                              imwrite(currentSample.results.segmentation{eventNr}(:,:,j), [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,num2str(eventNr),'_thumb_segm.tif'], 'writemode', 'append');     
                        end
                    end
                else
                    for i = 1:size(currentSample.results.thumbnail_images,2)
                        if ~isempty(currentSample.results.thumbnail_images{i}) && (class == 0 || currentSample.results.classification{i,class} == 1)
                            data = currentSample.results.thumbnail_images{i}(:,:,1);
                            if class == 0
                                t=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(i),'_thumb.tif'],'w');
                            else
                                t=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs_classified',filesep, num2str(i),...
                                    '_thumb_class_' currentSample.results.classification.Properties.VariableNames{class} '.tif'],'w');
                            end
                            t.setTag('Photometric',t.Photometric.MinIsBlack);
                            t.setTag('Compression',t.Compression.LZW);
                            t.setTag('ImageLength',size(currentSample.results.thumbnail_images{i},1));
                            t.setTag('ImageWidth',size(currentSample.results.thumbnail_images{i},2));
                            t.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
                            t.setTag('BitsPerSample',16);
                            t.setTag('SamplesPerPixel',1);
                            t.write(uint16(data));
                            t.close;
                            if class == 0
                                s=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,num2str(i),'_thumb_segm.tif'],'w');
                            else
                                s=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs_classified',filesep,num2str(i),...
                                    '_thumb_class_' currentSample.results.classification.Properties.VariableNames{class} '_segm.tif'],'w');
                            end
                            s.setTag('Photometric',t.Photometric.MinIsBlack);
                            s.setTag('Compression',t.Compression.LZW);
                            s.setTag('ImageLength',size(data,1));
                            s.setTag('ImageWidth',size(data,2));
                            s.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
                            s.setTag('BitsPerSample',1);
                            s.setTag('SamplesPerPixel',1);
                            s.write(currentSample.results.segmentation{i}(:,:,1));
                            s.close;
                            for j = 2:currentSample.nrOfChannels
                                if class == 0 
                                   imwrite(uint16(currentSample.results.thumbnail_images{i}(:,:,j)), ...
                                       [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(i),'_thumb.tif'], 'writemode', 'append');
                                   imwrite(currentSample.results.segmentation{i}(:,:,j), ...
                                       [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,num2str(i),'_thumb_segm.tif'], 'writemode', 'append'); 
                                else
                                   imwrite(uint16(currentSample.results.thumbnail_images{i}(:,:,j)), ...
                                       [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs_classified' filesep num2str(i)...
                                       '_thumb_class_' currentSample.results.classification.Properties.VariableNames{class} '.tif'],'writemode', 'append');
                                   imwrite(currentSample.results.segmentation{i}(:,:,j), ...
                                       [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs_classified',filesep,num2str(i),...
                                    '_thumb_class_' currentSample.results.classification.Properties.VariableNames{class} '_segm.tif'], 'writemode', 'append');
                                end
                            end
                        end
                    end
                end
           end
        end
                              
        
        %% Utility functions        
        function check_save_path(savePath)
            if ~exist(savePath,'dir')
                mkdir(savePath);
                mkdir([savePath,'output']);
                mkdir([savePath,'frames']);
                samplesProcessed={};
                save([savePath filesep 'processed.mat'],'samplesProcessed','-v7.3');
            end
        end
        
        function size=sample_pixel_size(inputSample)
            %calculate total image size to plot locations
            size(1)=inputSample.imagesize(1)*inputSample.rows;
            size(2)=inputSample.imageSize(2)*inputSample.columns;
        end
        
        function location=calculate_overview_location(inputSample,priorLocationNr)
            x=mean([inputSample.priorLocations.xBottomLeft(priorLocationNr),inputSample.priorLocations.xTopRight(priorLocationNr)])
            y=mean([inputSample.priorLocations.yBottomLeft(priorLocationNr),inputSample.priorLocations.yTopRight(priorLocationNr)])
            [rows,columns]=find(inputSample.priorLocations.frameNr(priorLocationNr)==inputSample.frameOrder);
            smallImageSize=ceil(inputSample.imageSize/8);
            location(1)=smallImageSize(1)*(rows-1)+round(y/8);
            location(2)=smallImageSize(2)*(columns-1)+round(x/8);
        end
        
        function location=calculate_location(inputSample,priorLocationNr)
            x=mean([inputSample.priorLocations.xBottomLeft(priorLocationNr),inputSample.priorLocations.xTopRight(priorLocationNr)]);
            y=mean([inputSample.priorLocations.yBottomLeft(priorLocationNr),inputSample.priorLocations.yTopRight(priorLocationNr)]);
            [rows,columns]=find(inputSample.priorLocations.frameNr(priorLocationNr)==inputSample.frameOrder);
            location(1)=(inputSample.imageSize(1)*(rows-1)+y)*0.645;
            location(2)=(inputSample.imageSize(2)*(columns-1)+x)*0.645;
        end
        
        function availableSampleProcessors=check_available_sample_processors()
            tmp = what('sampleProcessors');
            processors=strcat(strrep(tmp.m,'.m',''),'();');
            for i=1:numel(processors)
                availableSampleProcessors{i} = eval(processors{i});
                removeLines(i)=~availableSampleProcessors{i}.showInList;
            end
            availableSampleProcessors(removeLines)=[];
        end
        
        function convert_thumbnails_in_sample(inputSample)
            frames=unique(inputSample.results.thumbnails.frameNr);
            for i=1:numel(frames)
                currentDataFrame=IO.load_data_frame(inputSample,frames(i));
                currentDataFrame.segmentedImage=zeros(size(currentDataFrame.rawImage));
                thumbsInFrame=find(inputSample.results.thumbnails.frameNr==frames(i));
                for j=1:numel(thumbsInFrame)
                    locations=[inputSample.results.thumbnails.yBottomLeft(thumbsInFrame(j)),inputSample.results.thumbnails.yTopRight(thumbsInFrame(j)),...
                        inputSample.results.thumbnails.xBottomLeft(thumbsInFrame(j)),inputSample.results.thumbnails.xTopRight(thumbsInFrame(j))];
                    currentDataFrame.segmentedImage(locations(1):locations(2),locations(3):locations(4),:)=inputSample.results.segmentation{thumbsInFrame(j)}...
                        + currentDataFrame.segmentedImage(locations(1):locations(2),locations(3):locations(4),:);
                end
                IO.save_data_frame_segmentation(inputSample,currentDataFrame);
               
            end
            inputSample.results.thumbnail_images=[];
            inputSample.results.segmentation=[];  
            IO.save_sample(inputSample);
        end
    end
end
 

        



