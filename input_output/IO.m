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
        
        function t = export_samplelist_results_summary(sampleList,selectedCellsInTable,file)
            n = size(selectedCellsInTable,2);
            classifications = cell(1,n);
            id = cell(1,n);
            names={'sampleID'};
            for j=1:n
                i = selectedCellsInTable(j);
                if sampleList.isProcessed(i) == 1
                    try
                        currentSample = IO.load_sample(sampleList,i);
                        id{j} = currentSample.id;
                        classifications{j} = currentSample.results.classification;
                        classifiers = classifications{j}.Properties.VariableNames;
                        if ~isempty(classifiers)
                            names=cat(2,names,classifiers);
                        end
                    catch
                    end
                end
            end
            empty = cellfun(@isempty, classifications);
            classifications = classifications(~empty);
            id = id(~empty);
            n = size(classifications,2);
            names = unique(names,'stable');
            t = id';
            for i = 1:n
                for j = 2:numel(names)
                    if any(strcmp(classifications{i}.Properties.VariableNames,names(j)))
                        t{i,j}=sum(eval(['classifications{i}.', names{j}]));
                    else
                        t{i,j}=NaN;
                    end
                end
            end
            if ~isempty(t)
                summary = array2table(t,'VariableNames',unique(names,'stable'));
                delete(file);
                writetable(summary,file);
            end
        end
        
        function attach_results_summary(currentSample)
            names={'sampleID'};
            id=currentSample.id;
            classifications=currentSample.results.classification;
            classifiers=classifications.Properties.VariableNames;
            if ~isempty(classifiers)
                names=cat(2,names,classifiers);
            end
            if exist([currentSample.savePath(),'summaryTable.xlsx'],'file') == 2
                currExcel = readtable([currentSample.savePath(),'summaryTable.xlsx']);
                exist_names = currExcel.Properties.VariableNames; 
                new_names = setdiff(names,exist_names);
                T_new = array2table(nan(size(currExcel,1),size(new_names,2)),'VariableNames',new_names);
                currExcel = [currExcel, T_new];
            else 
                start = [];
                start{1,1} = id;
                for j = 2:size(names,2)
                    start{1,j} = NaN;
                end
                currExcel = cell2table(start,'VariableNames',names);
            end
            
            pos_name = find(strcmp(currExcel{:,1},id));
            if isempty(pos_name)
                column_ind = size(currExcel,1)+1;
                start = [];
                start{1,1} = id;
                for j = 2:size(names,2)
                    start{1,j} = NaN;
                end
                currExcel = [currExcel;cell2table(start,'VariableNames',names)];
            else
                column_ind = pos_name;
            end
            for i = 2:size(currExcel,2)
                pos = find(strcmp(currExcel.Properties.VariableNames{i},classifiers));
                if ~isempty(pos)
                    currExcel{column_ind,i} = sum(eval(['classifications.', classifiers{pos}]));
                else
                    currExcel{column_ind,i} = NaN;
                end
            end
            delete([currentSample.savePath(),'summaryTable.xlsx']);
            writetable(currExcel,[currentSample.savePath(),'summaryTable.xlsx']);
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
        
        function outputSample = load_sample(sampleList,sampleNr,tiff_update)
            % loads a sample from a sampleList. First checks if this sample
            % has been saved before. If not we look up the loader handle
            % and construct the sample. 
            if nargin < 3
                tiff_update = true;
            end
            
            if exist(IO.saved_sample_path(sampleList,sampleNr),'file')
                load(IO.saved_sample_path(sampleList,sampleNr));
                if tiff_update
                    loader = currentSample.loader();
                    loader.update_prior_infos(currentSample,[sampleList.inputPath filesep sampleList.sampleNames{sampleNr}]);
                    currentSample.savePath = sampleList.save_path;
                    IO.preload_segmentation_tiffs(currentSample);
                else
                    currentSample.savePath = sampleList.save_path;
                end
                
                
                outputSample = currentSample;
            else
                outputSample = load_sample_path(sampleList,sampleNr)
            end
            % Check if this is sample still contains thumbnails...
        end
        
        function outputSample = load_sample_path(sampleList,sampleNr)
                loader = sampleList.loaderToBeUsed{sampleNr};
                loader.new_sample_path([sampleList.inputPath filesep sampleList.sampleNames{sampleNr}]);
                outputSample = loader.sample;
                outputSample.savePath = sampleList.save_path();
        end
        
        
        function save_sample(currentSample)
            % Function to save the sample in a .mat file for later reuse.
            % and mark the sample sample as processed. 
            % Check if for oldstyle sample and save segmentation if needed
            IO.check_sample_for_thumbnails(currentSample)
            % Remove tiff headers from sample
            currentSample.tiffHeaders=[];
            currentSample.segmentationHeaders=[];
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
        
        function preload_segmentation_tiffs(currentSample)
            for i = 1:currentSample.nrOfFrames
                currentSample.segmentationFileNames{i} = [currentSample.savePath,'frames',filesep,currentSample.id,filesep,num2str(i,'%03.0f'),'_seg.tif'];
                if exist(currentSample.segmentationFileNames{i},'file')
                    currentSample.segmentationHeaders{i}=imfinfo(currentSample.segmentationFileNames{i});
                end
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
            if ~exist([currentSample.savePath,'frames',filesep],'dir')
                mkdir([currentSample.savePath,'frames',filesep]);
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
              
        function outputImage = load_segmented_image(sample,frameNr)
            if exist(sample.segmentationFileNames{frameNr},'file');
               outputImage=imread(sample.segmentationFileNames{frameNr},'info',sample.segmentationHeaders{frameNr});
            else
               outputImage=[];
            end
        end
        
        function load_thumbs_to_results(sample)
            %special function that allows for a specific loader.
           loader=sample.loader(sample);
           if isa(loader,'ThumbnailLoader')
               loader.load_thumbs_to_results();
           end
        end
        
%         function [thumbnail_images,segmentation]=load_thumbnail(inputSample)
%         
%         
%             
%         end
        
        
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
            t.setTag('SamplesPerPixel',currentSample.nrOfChannels);
            t.write(uint8(currentDataFrame.segmentedImage));
            t.close;
        end
        
        function save_thumbnail(currentSample,eventNr,option,rescaled,class,thumbContainer)
           id = currentSample.id;
           
           if ~exist('class','var') || isempty(class)
               class = 0;
           end
           
           if size(class,1) == 1 && class ~= 0 
               class = currentSample.results.classification{:,class};
           end
               
           if exist('option','var') && strcmp('prior',option)
            if ~exist([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs'],'dir')
                mkdir([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs']);
                fid=fopen([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs',filesep,'ACCEPTThumbnails.txt'],'w');
                fclose(fid);
            end
           elseif size(class,1) > 1
            if ~exist([currentSample.savePath,'frames',filesep,id,filesep,'selected_Thumbs'],'dir')
               mkdir([currentSample.savePath,'frames',filesep,id,filesep,'selected_Thumbs']);
               fid=fopen([currentSample.savePath,'frames',filesep,id,filesep,'selected_Thumbs',filesep,'ACCEPTThumbnails.txt'],'w');
               fclose(fid);
            end
           else
            if ~exist([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs'],'dir')
               mkdir([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs']);
               fid=fopen([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,'ACCEPTThumbnails.txt'],'w');
               fclose(fid);
            end
           end
           
           if ~exist('rescaled','var') || isempty(rescaled)
               rescaled = true;
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
                    if exist('thumbContainer','var') && isa(thumbContainer,'ThumbContainer') && thumbContainer.nrOfEvents == size(currentSample.results.thumbnails,1)
                        rawIm = thumbContainer.thumbnails{eventNr};
                        segmIm = thumbContainer.segmentation{eventNr};
                    else
                        thumbContainer = ThumbContainer(currentSample,eventNr);
                        rawIm = thumbContainer.thumbnails{1};
                        segmIm = thumbContainer.segmentation{1};
                    end
                        
                    if ~isempty(rawIm)
                        data = rawIm(:,:,1);
                        t=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(eventNr),'_thumb.tif'],'w');
                        t.setTag('Photometric',t.Photometric.MinIsBlack);
                        t.setTag('Compression',t.Compression.LZW);
                        t.setTag('ImageLength',size(data,1));
                        t.setTag('ImageWidth',size(data,2));
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
                        s.write(segmIm(:,:,1));
                        s.close;
                        for j = 2:currentSample.nrOfChannels
                              imwrite(uint16(rawIm(:,:,j)), [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(eventNr),'_thumb.tif'], 'writemode', 'append');
                              imwrite(segmIm(:,:,j), [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,num2str(eventNr),'_thumb_segm.tif'], 'writemode', 'append');     
                        end
                    end
                else
                    if exist('thumbContainer','var') && isa(thumbContainer,'ThumbContainer') && thumbContainer.nrOfEvents == size(currentSample.results.thumbnails,1)
                        thumbnail_images = thumbContainer.thumbnails;
                        segmentation = thumbContainer.segmentation;
                    else
                        thumbContainer = ThumbContainer(currentSample);
                        thumbnail_images = thumbContainer.thumbnails;
                        segmentation = thumbContainer.segmentation;
                    end
                    for i = 1:size(thumbnail_images,1)
                        if ~isempty(thumbnail_images{i}) && ((size(class,1)== 1&& class == 0) || class(i) == 1)
                            data = thumbnail_images{i}(:,:,1);
                            if (size(class,1)== 1 && class == 0)
                                t=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(i),'_thumb.tif'],'w');
                            else
                                t=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'selected_Thumbs',filesep, num2str(i),...
                                    '_thumb.tif'],'w');
                            end
                            t.setTag('Photometric',t.Photometric.MinIsBlack);
                            t.setTag('Compression',t.Compression.LZW);
                            t.setTag('ImageLength',size(thumbnail_images{i},1));
                            t.setTag('ImageWidth',size(thumbnail_images{i},2));
                            t.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
                            t.setTag('BitsPerSample',16);
                            t.setTag('SamplesPerPixel',1);
                            t.write(uint16(data));
                            t.close;
                            if (size(class,1)== 1 && class == 0)
                                s=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,num2str(i),'_thumb_segm.tif'],'w');
                            else
                                s=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'selected_Thumbs',filesep,num2str(i),...
                                    '_thumb_segm.tif'],'w');
                            end
                            s.setTag('Photometric',t.Photometric.MinIsBlack);
                            s.setTag('Compression',t.Compression.LZW);
                            s.setTag('ImageLength',size(data,1));
                            s.setTag('ImageWidth',size(data,2));
                            s.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
                            s.setTag('BitsPerSample',1);
                            s.setTag('SamplesPerPixel',1);
                            s.write(segmentation{i}(:,:,1));
                            s.close;
                            for j = 2:currentSample.nrOfChannels
                                if (size(class,1)== 1 && class == 0)
                                   imwrite(uint16(thumbnail_images{i}(:,:,j)), ...
                                       [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(i),'_thumb.tif'], 'writemode', 'append');
                                   imwrite(segmentation{i}(:,:,j), ...
                                       [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,num2str(i),'_thumb_segm.tif'], 'writemode', 'append'); 
                                else
                                   imwrite(uint16(thumbnail_images{i}(:,:,j)), ...
                                       [currentSample.savePath,'frames',filesep,id,filesep,'selected_Thumbs' filesep num2str(i)...
                                       '_thumb.tif'],'writemode', 'append');
                                   imwrite(segmentation{i}(:,:,j), ...
                                       [currentSample.savePath,'frames',filesep,id,filesep,'selected_Thumbs',filesep,num2str(i),...
                                    '_thumb_segm.tif'], 'writemode', 'append');
                                end
                            end
                        end
                    end
                end
           end
        end
        
        function outputImage = load_overview_image(sample)
            if exist([sample.savePath,'frames',filesep,sample.id,filesep,'overview_thumbnail.tif'],'file');
               outputImage=imread([sample.savePath,'frames',filesep,sample.id,filesep,'overview_thumbnail.tif']);
            else
               outputImage=[];
            end   
        end
        
        function outputImage = load_overview_mask(sample)
            if exist([sample.savePath,'frames',filesep,sample.id,filesep,'overview_mask.tif'],'file');
               outputImage=logical(imread([sample.savePath,'frames',filesep,sample.id,filesep,'overview_mask.tif']));
            else
               outputImage=[];
            end   
        end
        
        function save_overview_image(currentSample,inputImage)
            if ~exist([currentSample.savePath,'frames',filesep,currentSample.id],'dir')
                mkdir([currentSample.savePath,'frames',filesep,currentSample.id]);
            end
            t=Tiff([currentSample.savePath,'frames',filesep,currentSample.id,filesep,'overview_thumbnail.tif'],'w');
            t.setTag('Photometric',t.Photometric.MinIsBlack);
            t.setTag('Compression',t.Compression.LZW);
            t.setTag('ImageLength',size(inputImage,1));
            t.setTag('ImageWidth',size(inputImage,2));
            t.setTag('PlanarConfiguration',t.PlanarConfiguration.Separate);
            t.setTag('BitsPerSample',16);
            t.setTag('SamplesPerPixel',currentSample.nrOfChannels);
            t.write(inputImage);
            t.close;
        end
       
        function save_overview_mask(currentSample,inputImage)
            if ~exist([currentSample.savePath,'frames',filesep,currentSample.id],'dir')
                mkdir([currentSample.savePath,'frames',filesep,currentSample.id]);
            end
            t=Tiff([currentSample.savePath,'frames',filesep,currentSample.id,filesep,'overview_mask.tif'],'w');
            t.setTag('Photometric',t.Photometric.MinIsBlack);
            t.setTag('Compression',t.Compression.LZW);
            t.setTag('ImageLength',size(inputImage,1));
            t.setTag('ImageWidth',size(inputImage,2));
            t.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
            t.setTag('BitsPerSample',8);
            t.setTag('SamplesPerPixel',1);
            t.write(uint8(inputImage));
            t.close;
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
            x=mean([inputSample.priorLocations.xBottomLeft(priorLocationNr),inputSample.priorLocations.xTopRight(priorLocationNr)]);
            y=mean([inputSample.priorLocations.yBottomLeft(priorLocationNr),inputSample.priorLocations.yTopRight(priorLocationNr)]);
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
            disp('detected old style sample converting to save disk space');
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
         end
        
        function check_sample_for_thumbnails(inputSample)
            if ~isempty(inputSample.results.segmentation)
                IO.convert_thumbnails_in_sample(inputSample);
            end
            if ~isempty(inputSample.overviewImage)
                IO.save_overview_image(inputSample,inputSample.overviewImage);
                inputSample.overviewImage=[];
            end
            if ~isempty(inputSample.mask)
                IO.save_overview_mask(inputSample,inputSample.mask);
                inputSample.mask=[];
            end
        end
    end
end
 

        



