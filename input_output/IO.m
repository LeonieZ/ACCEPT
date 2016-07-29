classdef IO < handle
    %the toplevel class that handles the various input and output operations. It
    %allows for easy loading of different sample types
    
    properties
        overwriteResults=false;
    end
    
    properties(SetAccess=private)
        loaderTypesAvailable={CellTracks(),MCBP(),ThumbnailLoader(),Default()}; % beware of the order, the first loader type that can load a dir will be used.
    end
    
    events
        logMessage
    end
    
    methods
        function outputList = create_sample_list(this,inputPath,resultPath,sampleProcessor)
            if nargin==4
                [sampleNames,loaderUsed]=this.available_samples(inputPath);
                %[isProc,isToBeProc]=this.processed_samples(resultPath,sampleProcessor.id(),sampleNames);
                [isProc]=this.processed_samples(resultPath,sampleProcessor.id(),sampleNames);
                outputList=SampleList(sampleProcessor.id(),inputPath,resultPath,sampleNames,isProc,loaderUsed);
            else
                outputList=SampleList();
            end
            addlistener(outputList,'updatedProcessorId',@this.updated_sample_processor);
            addlistener(outputList,'updatedInputPath',@this.updated_input_path);
            addlistener(outputList,'updatedResultPath',@this.updated_result_path);
        end
        
        function update_sample_list(this,sampleList)
                sampleList.isProcessed=this.processed_samples(sampleList.resultPath,sampleList.sampleProcessorId,sampleList.sampleNames);
        end
        
        function outputSample=load_sample(this,sampleList,sampleNr)
            if exist(this.saved_sample_path(sampleList,sampleNr),'file');
                load(this.saved_sample_path(sampleList,sampleNr));
                outputSample=currentSample;
            else
                loader=sampleList.loaderToBeUsed{sampleNr};
                loader.new_sample_path([sampleList.inputPath filesep sampleList.sampleNames{sampleNr}]);
                outputSample=loader.sample;
                outputSample.savePath=sampleList.save_path();
            end
        end
        
        function outputFrame=load_data_frame(this,sample,frameNr)
            if exist(this.saved_data_frame_path(sample,frameNr),'file')
                load(this.saved_data_frame_path(sample,frameNr));
                outputFrame=currentDataFrame;
            else
                loader=sample.loader(sample);
                outputFrame=loader.load_data_frame(frameNr);
            end
        end
        
        function outputFrame=load_thumbnail_frame(this,sample,thumbNr,option,rescaled)
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
                boundingBox = {[sample.results.thumbnails.xBottomLeft(thumbNr) sample.results.thumbnails.xTopRight(thumbNr)],...
                    [sample.results.thumbnails.yBottomLeft(thumbNr) sample.results.thumbnails.yTopRight(thumbNr)]};
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
                    
%                 end
            end
        end
        
       function load_thumbs_to_results(this,sample)
           loader=sample.loader(sample);
           if isa(loader,'ThumbnailLoader')
               loader.load_thumbs_to_results();
           end
       end
        
        function save_sample_processor(this,smplLst,processor)
            save([smplLst.save_path(),'processed.mat'],'processor','-append','-v7.3');
        end
        
        function save_sample(this,currentSample)
            save([currentSample.savePath,filesep,'output',filesep,currentSample.id,'.mat'],'currentSample','-v7.3');
            load([currentSample.savePath,filesep,'processed.mat'],'samplesProcessed');
            samplesProcessed=union(samplesProcessed,{currentSample.id});
            save([currentSample.savePath,filesep,'processed.mat'],'samplesProcessed','-append');
        end
        
        function save_data_frame(this,currentSample,currentDataFrame)
            if ~exist([currentSample.savePath,filesep,'frames',filesep,currentSample.id],'dir')
                mkdir([currentSample.savePath,filesep,'frames',filesep,currentSample.id]);
            end
            save([currentSample.savePath,filesep,'frames',filesep,currentSample.id,filesep,num2str(currentDataFrame.frameNr),'.mat'],'currentDataFrame','-v7.3');            
        end
        
        function save_data_frame_segmentation(this,currentSample,currentDataFrame)
            if ~exist([currentSample.savePath,filesep,'frames',filesep,currentSample.id],'dir')
                mkdir([currentSample.savePath,filesep,'frames',filesep,currentSample.id]);
            end
            t=Tiff([currentSample.savePath,filesep,'frames',filesep,currentSample.id,filesep,num2str(currentDataFrame.frameNr),'_seg.tif'],'w');
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
        
        function save_thumbnail(this,currentSample,eventNr,option,rescaled)
           [id,~] = strtok(currentSample.id,'.');
           if exist('option','var') && strcmp('prior',option)
            if ~exist([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs'],'dir')
                mkdir([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs']);
                fid=fopen([currentSample.savePath,'frames',filesep,id,filesep,'priorThumbs',filesep,'ACCEPTThumbnails.txt'],'w');
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

           if exist('option','var')
                if strcmp('prior',option)
                    if exist('eventNr','var') && ~isempty(eventNr)
                        currentDataFrame=this.load_thumbnail_frame(currentSample,eventNr,'prior',rescaled);
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
                            currentDataFrame=this.load_thumbnail_frame(currentSample,i,'prior',rescaled);
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
                end
           else
                if exist('eventNr','var')
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
                        if ~isempty(currentSample.results.thumbnail_images{i})
                            data = currentSample.results.thumbnail_images{i}(:,:,1);
                            t=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(i),'_thumb.tif'],'w');
                            t.setTag('Photometric',t.Photometric.MinIsBlack);
                            t.setTag('Compression',t.Compression.LZW);
                            t.setTag('ImageLength',size(currentSample.results.thumbnail_images{i},1));
                            t.setTag('ImageWidth',size(currentSample.results.thumbnail_images{i},2));
                            t.setTag('PlanarConfiguration',t.PlanarConfiguration.Chunky);
                            t.setTag('BitsPerSample',16);
                            t.setTag('SamplesPerPixel',1);
                            t.write(uint16(data));
                            t.close;
                            s=Tiff([currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,num2str(i),'_thumb_segm.tif'],'w');
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
                              imwrite(uint16(currentSample.results.thumbnail_images{i}(:,:,j)), [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep, num2str(i),'_thumb.tif'], 'writemode', 'append');
                              imwrite(currentSample.results.segmentation{i}(:,:,j), [currentSample.savePath,'frames',filesep,id,filesep,'Thumbs',filesep,num2str(i),'_thumb_segm.tif'], 'writemode', 'append'); 
                            end
                        end
                    end
                end
           end
        end
                                   
        function save_results_as_xls(this,currentSample)
            tempTable=horzcat(currentSample.results.classification,currentSample.results.features);
            if isempty(tempTable)
                tempTable.events='no events in sample';
            end
            if ispc
                writetable(tempTable,[currentSample.savePath,'output',filesep,currentSample.id,'.xls']);
            else
                writetable(tempTable,[currentSample.savePath,'output',filesep,currentSample.id,'.csv']);
            end
        end
        
        function update_results(this,sampleList)
            this.updated_results_path(sampleList);
        end
        
        function clear_results(this,currentSample)
            currentSample.results = Result();
        end
         
    end
    
    
    methods (Access = private)
        function populate_available_input_types(this)
            % populate available inputs 
            % Function not used atm /g
            temp = what('Loaders');
            flist = temp.m;

            for i=1:numel(flist)
               [~,filename,filetext]=fileparts(flist{i}); % get just the filename
               if exist(filename, 'class') && ismember('loader', superclasses(filename))
                 this.loaderTypesAvailable{end+1} = filename();
               end
             end
        end
        
        function updated_sample_processor(this,sampleList,~)
            if all([~isempty(sampleList.resultPath),...
                    ~strcmp(sampleList.sampleProcessorId,'empty'),...
                    isempty(sampleList.sampleNames)]);
                this.updated_input(sampleList);
            end
            if and(~isempty(sampleList.inputPath),~isempty(sampleList.resultPath))
                [isProc]=this.processed_samples(sampleList.resultPath,...
                                                    sampleList.sampleProcessorId,...
                                                    sampleList.sampleNames);
                sampleList.isProcessed=isProc;
            end
        end
        
        function updated_result_path(this,sampleList,~)
            if all([~isempty(sampleList.inputPath),...
                    ~strcmp(sampleList.sampleProcessorId,'empty'),...
                    isempty(sampleList.sampleNames)]);
                this.updated_input(sampleList);
            end
            if and(~isempty(sampleList.resultPath),...
                    ~strcmp(sampleList.sampleProcessorId,'empty'));
                [isProc]=this.processed_samples(sampleList.resultPath,...
                                                sampleList.sampleProcessorId,...
                                                sampleList.sampleNames);
                sampleList.isProcessed=isProc;
             end
        end
        
        function updated_input_path(this,sampleList,~)
            [sampleNames,loaderUsed]=this.available_samples(sampleList.inputPath);
            sampleList.sampleNames=sampleNames;
            sampleList.loaderToBeUsed=loaderUsed;
            if and(~isempty(sampleList.resultPath),...
                ~strcmp(sampleList.sampleProcessorId,'empty'));
                [isProc]=this.processed_samples(sampleList.resultPath,...
                                        sampleList.sampleProcessorId,...
                                        sampleNames);
                sampleList.isProcessed=isProc;
            end
        end
       
        function loaderHandle=check_sample_type(this,samplePath)
            %Checks which loader types can load the sample path and chooses
            %the first one on the list. 
            loaderFound=false;
            i=0;
            while ~loaderFound
                i=i+1; 
                loaderFound = this.loaderTypesAvailable{i}.can_load_this_folder(samplePath);
            end
            loaderHandle=this.loaderTypesAvailable{i};
        end
        
        function [sampleNames,loaderUsed]=available_samples(this,inputPath)
            %creates list of samples from input dir. It also checks if
            %these samples are already processed in the output dir when the
            %overwriteResults attribute is set to false. 
            files = dir(inputPath);
            if isempty(files)
                this.log.entry('inputPath is empty; cannot continue',1,1);
                error('inputDir is empty; cannot continue');
            end

            % select only directory entries from the input listing and remove
            % anything that starts with a .*.
            samples = files([files.isdir] & ~strncmpi('.', {files.name}, 1)); 
            for i=1:numel(samples)
                sampleNames{i}=samples(i).name;
                loaderUsed{i}=this.check_sample_type([inputPath,filesep,samples(i).name]);
            end

        end
        
        function [isProc]=processed_samples(this,resultsPath,sampleProcessorId,sampleNames)
            savepath=[resultsPath,filesep,sampleProcessorId];
            isProc=true(1,numel(sampleNames));
            isToBeProc=false(1,numel(sampleNames));
            if ~exist(savepath,'dir')
                mkdir(savepath);
                mkdir([savepath,filesep,'output']);
                mkdir([savepath,filesep,'frames']);
                samplesProcessed={};
                save([savepath filesep 'processed.mat'],'samplesProcessed','-v7.3');
                isProc=false(1,numel(sampleNames));
                %isToBeProc=true(1,numel(sampleNames));
            else
                %Check in results dir if any samples are already processed.
                try load([savepath filesep 'processed.mat'],'samplesProcessed')
                catch 
                    %appears to be no list (?) so lets create an empty sampleProccesed variable
                    samplesProcessed={};
                end
                [~,index]=setdiff(sampleNames,samplesProcessed);
                if this.overwriteResults==false
                    %isToBeProc(index)=true;
                    isProc(index)=false;
                else
                    %isToBeProc=true(1,numel(sampleNames));
                    isProc(index)=false;
                end
            end
        end
          
    end
    
    methods (Static, Access = private)
        function location=saved_sample_path(sampleList,sampleNr)
            location=[sampleList.save_path(),'output',filesep,sampleList.sampleNames{sampleNr},'.mat'];
        end
    
        function location=saved_data_frame_path(sample,frameNr)
            location=[sample.savePath,'frames',filesep,sample.id,filesep,num2str(frameNr),'.mat'];
        end
                      
    end
end
 

        



