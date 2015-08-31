classdef IO < handle
    %the toplevel class that handles the various input and output operations. It
    %allows for easy loading of different sample types
    
    properties
        overwriteResults=false;
    end
    
    properties(SetAccess=private)
        loaderTypesAvailable={CellTracks(),MCBP(),Default()}; % beware of the order, the first loader type that can load a dir will be used.
    end
    
    events
        logMessage
    end
    
    methods
        function outputList = create_sample_list(this,inputPath,resultPath,sampleProcessor)
            [sampleNames,loaderUsed]=this.available_samples(inputPath);
            %[isProc,isToBeProc]=this.processed_samples(resultPath,sampleProcessor.id(),sampleNames);
            [isProc]=this.processed_samples(resultPath,sampleProcessor.id(),sampleNames);
            outputList=SampleList(sampleProcessor.id(),inputPath,resultPath,sampleNames,isProc,loaderUsed);
            addlistener(outputList,'updatedProcessorId',@this.updated_sample_processor);
            addlistener(outputList,'updatedInputPath',@this.updated_input_path);
            addlistener(outputList,'updatedResultPath',@this.updated_result_path);
        end
        
        function outputSample=load_sample(this,sampleList,sampleNr)
            if exist(this.saved_sample_path(sampleList,sampleNr),'file');
                load(this.saved_sample_path(sampleList,sampleNr))
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
        
        function outputFrame=load_thumbnail_frame(this,sample,thumbNr,option)
            loader=sample.loader(sample);
            if exist('option','var')
                if strcmp('prior',option)
                    if isempty(sample.priorLocations)
                        error('This sample contains no prior locations')
                    end
                    frameNr = sample.priorLocations.frameNr(thumbNr);
                    boundingBox = {[sample.priorLocations.yBottomLeft(thumbNr) sample.priorLocations.yTopRight(thumbNr)],...
                        [sample.priorLocations.xBottomLeft(thumbNr) sample.priorLocations.xTopRight(thumbNr)]};
                    outputFrame=loader.load_data_frame(frameNr,boundingBox);
                end
            else
                if isempty(this.sample.results.thumbnails)
                    error('This sample contains no thumbnail locations')
                end
                frameNr = this.sample.results.thumbnails.frameNr(thumbNr);
                boundingBox = {[this.sample.results.thumbnails.yBottomLeft(thumbNr) this.sample.results.thumbnails.yTopRight(thumbNr)],...
                    [this.sample.results.thumbnails.xBottomLeft(thumbNr) this.sample.results.thumbnails.xTopRight(thumbNr)]};
                if exist(this.saved_frame_path(sample,frameNr),'file');
                    load(this.saved_frame_path(sample,frameNr));
                    outputFrame=DataFrame(frameNr,currentDataFrame.frameHasEdge,...
                        currentDataFrame.channelEdgeRemoval,...
                        currentDataFrame.rawImage(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:));
                    outputFrame.adjacentFrames=currentDataFrame.adjacentFrames(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:);
                    outputFrame.preProcessedImage=currentDataFrame.preProcessedImage(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:);
                    outputFrame.segmentedImage=currentDataFrame.segmentedImage(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:);
                    outputFrame.mask=currentDataFrame.mask(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2),:);
                else
                    outputFrame=loader.load_data_frame(frameNr,boundingBox);
                end
            end
        end
     

        function load_sample_overview(this,sample)
            if isempty(sample.overviewImage)
                loader = sample.loader(sample);
                frameOrder = loader.calculate_frame_nr_order;
                reductionFactor = 1/8;
                reducedSize = [ceil(sample.imageSize(1)*reductionFactor(1)),sample.imageSize(2)*reductionFactor(1),sample.imageSize(3)];
                reducedSize=ceil(reducedSize);
                sample.overviewImage = zeros(reducedSize(1)*sample.rows,reducedSize(2)*sample.columns,reducedSize(3),'uint16');
                for i=1:sample.rows
                    for j=1:sample.columns
                        offset=[reducedSize(1)*(i-1)+1,reducedSize(2)*(j-1)+1];
                        frame=loader.load_data_frame(frameOrder(i,j));
                        tempImage=imresize(frame.rawImage,reductionFactor);
                        sample.overviewImage(offset(1):offset(1)+reducedSize(1)-1,offset(2):offset(2)+reducedSize(2)-1,:)=tempImage;
                    end
                end
            end
        end
        
        function save_sample_processor(this,smplLst,processor)
            save([smplLst.save_path(),'processed.mat'],'processor','-append');
        end
        
        function save_sample(this,currentSample)
            save([currentSample.savePath,filesep,'output',filesep,currentSample.id,'.mat'],'currentSample');
            load([currentSample.savePath,filesep,'processed.mat'],'samplesProcessed');
            samplesProcessed=union(samplesProcessed,{currentSample.id});
            save([currentSample.savePath,filesep,'processed.mat'],'samplesProcessed','-append');
        end
        
        function save_data_frame(this,currentSample,currentDataFrame)
            if ~exist([currentSample.savePath,filesep,'frames',filesep,currentSample.id],'dir')
                mkdir([currentSample.savePath,filesep,'frames',filesep,currentSample.id]);
            end
            save([currentSample.savePath,filesep,'frames',filesep,currentSample.id,filesep,num2str(currentDataFrame.frameNr),'.mat'],'currentDataFrame');            
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
        
        function save_thumbnail(this,currentSample,eventNr)
           %to be implemented 
        end
        
        function update_results(this,sampleList)
            this.updated_results_path(sampleList);
        end
         
    end
    
    
    methods (Access = private)
        function populate_available_input_types(this)
            % populate available inputs 
            % Function not used atm /g
            temp = what('Loaders');
            flist = temp.m;

            for i=1:numel(flist)
               [~,filename,fileext]=fileparts(flist{i}); % get just the filename
               if exist(filename, 'class') && ismember('loader', superclasses(filename))
                 this.loaderTypesAvailable{end+1} = filename();
               end
             end
        end
        
        function updated_sample_processor(this,sampleList,~)
            [isProc,isToBeProc]=this.processed_samples(sampleList.resultPath,...
                                                sampleList.sampleProcessorId,...
                                                sampleList.sampleNames);
            sampleList.isProcessed=isProc;
            sampleList.isToBeProcessed=isToBeProc;
        end
        
        function updated_results_path(this,sampleList,~)
            [isProc,isToBeProc]=this.processed_samples(sampleList.resultPath,...
                                                sampleList.sampleProcessorId,...
                                                sampleList.sampleNames);
            sampleList.isProcessed=isProc;
            sampleList.isToBeProcessed=isToBeProc;
        end
        
        function updated_input_path(this,sampleList,~)
            [sampleNames,loaderUsed]=this.available_samples(inputPath);
            [isProc,isToBeProc]=this.processed_samples(sampleList.resultPath,...
                                        sampleList.sampleProcessorId,...
                                        sampleNames);
            sampleList.sampleNames=smpleNames;
            sampleList.loaderToBeUsed=loaderUsed;
            sampleList.isProcessed=isProc;
            sampleList.isToBeProcessed=isToBeProc;
        end
       
        function loaderHandle=check_sample_type(this,samplePath)
            %Checks which loader types can load the sample path and chooses
            %the first one on the list. 
            for i=1:numel(this.loaderTypesAvailable)
                canLoad(i) = this.loaderTypesAvailable{i}.can_load_this_folder(samplePath);
            end
            loaderHandle=this.loaderTypesAvailable{find(canLoad,1)};
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
                sampleNames{i}=samples(i).name
                loaderUsed{i}=this.check_sample_type([inputPath,filesep,samples(i).name])
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
                save([savepath filesep 'processed.mat'],'samplesProcessed');
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
            location=[sampleList.save_path(),filesep,'output',filesep,sampleList.sampleNames{sampleNr},'.mat'];
        end
    
        function location=saved_data_frame_path(sample,frameNr)
            location=[sample.savePath,filesep,'frames',filesep,sample.id,filesep,num2str(frameNr),'.mat'];
        end
        
    end
end
 

        



