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
            [isProc,isToBeProc]=this.processed_samples(resultPath,sampleProcessor.id(),sampleNames);
            outputList=SampleList(sampleProcessor.id(),inputPath,resultPath,sampleNames,isProc,isToBeProc,loaderUsed);
            addlistener(outputList,'updatedProcessorId',@this.updated_sample_processor);
            addlistener(outputList,'updatedInputPath',@this.updated_input_path);
            addlistener(outputList,'updatedResultPath',@this.updated_result_path);
        end
        
        function outputSample=load_sample(this,sampleList,sampleNr)
            loader=sampleList.loaderToBeUsed{sampleNr};
            loader.new_sample_path([sampleList.inputPath filesep sampleList.sampleNames{sampleNr}]);
            outputSample=loader.sample;
        end
        
        function outputFrame=load_data_frame(this,sample,frameNr)
            loader=sample.loader(sample);
            outputFrame=loader.load_data_frame(frameNr);
        end
        
        function outputFrame=load_thumbnail_frame(this,sample,thumbNr)
            loader=sample.loader(sample);
            outputFrame=loader.load_thumb_frame(thumbNr);
        end

        
        function save_work_flow(this,workFlow)
            save([this.resultsPath,filesep,'workflow.mat'],'workFlow');
        end
        
        function save_sample(this,currentSample)
            save([this.resultsPath,filesep,'output',filesep,currentSample.name,'.mat'],'currentSample');
        end
        
        function save_results(this,currentSample)
            save([this.resultsPath,filesep,'output',filesep,currentSample.name,'.mat'],'currentSample.results','-append');        
        end
        
        function save_data_frame(this,currentSample,currentDataFrame)
            if ~exist([this.resultsPath,filesep,'frames',filesep,currentSample.name],'dir')
                mkdir([this.resultsPath,filesep,'frames',filesep,currentSample.name]);
            end
            save([this.resultsPath,filesep,'frames',filesep,currentSample.name,filesep,num2str(currentDataFrame.frameNr),'.mat'],'currentDataFrame');            
    
        end
        
        function save_data_frame_segmentation(this,currentSample,currentDataFrame)
            if ~exist([this.resultsPath,filesep,'frames',filesep,currentSample.name],'dir')
                mkdir([this.resultsPath,filesep,'frames',filesep,currentSample.name]);
            end
            t=Tiff([this.resultsPath,filesep,'frames',filesep,currentSample.name,filesep,num2str(currentDataFrame.frameNr),'_seg.tif'],'w');
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
                                                sampleLsit.sampleNames);
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
        
        function [isProc,isToBeProc]=processed_samples(this,resultsPath,sampleProcessorId,sampleNames);
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
                isToBeProc=true(1,numel(sampleNames));
            else
                %Check in results dir if any samples are already processed.
                try load([savepath filesep 'processed.mat'],'samplesProcessed')
                catch 
                    %appears to be no list (?) so lets create an empty sampleProccesed variable
                    samplesProcessed={};
                end
                [~,index]=setdiff(sampleNames,samplesProcessed);
                if this.overwriteResults==false
                    isToBeProc(index)=true;
                    isProc(index)=false;
                else
                    isToBeProc=true(1,numel(sampleNames));
                    isProc(index)=false;
                end
            end
        end
    end
end
        


