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
        function this = IO()

        end
        
        function outputList = create_sample_list(this,inputPath,resultsPath,sampleProcessor)
        
        end
        
        function updated_sample_Processor(this)
            
        end
        
        function updated_results_path(this)

            if exist(path,'dir')
                this.resultsPath=path;
            else
                mkdir(path);
                mkdir([path,filesep,'output']);
                mkdir([path,filesep,'frames'])
                this.resultsPath=path;
            end
            this.create_sample_list;
        end
        
        function updated_input_path(this)
            %update loader list
            %update sampleList
            this.samplesPath=path;
            this.update_sample_list;
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
        
        function loaderHandle=check_sample_type(this,samplePath)
            %Checks which loader types can load the sample path and chooses
            %the first one on the list. 
            for i=1:numel(this.loaderTypesAvailable)
                canLoad(i) = this.loaderTypesAvailable{i}.can_load_this_folder(samplePath);
            end
            loaderHandle=this.loaderTypesAvailable{find(canLoad,1)};
            loaderHandle.new_sample_path(samplePath);
        end
        
        function create_sample_list(this)
            %creates list of samples from input dir. It also checks if
            %these samples are already processed in the output dir when the
            %overwriteResults attribute is set to false. 
            files = dir(this.samplesPath);
            if isempty(files)
                this.log.entry('inputDir is empty; cannot continue',1,1);
                error('inputDir is empty; cannot continue');
            end

            % select only directory entries from the input listing and remove
            % anything that starts with a .*.
            inputList = files([files.isdir] & ~strncmpi('.', {files.name}, 1)); 

            %Check in results dir if any samples are already processed.
            if this.overwriteResults==false
                try load([this.resultsPath filesep processed.mat],samplesProccesed)
                catch 
                    %appears to be no lest (?) so lets create an empty sampleProccesed variable
                    sampleProccessed=['empty'];
                end
                this.sampleList=setdiff({inputList.name},sampleProccessed);
            else
                this.sampleList=inputList;
            end
            this.nrOfSamples=numel(inputList);
            this.currentSampleNr=0;
        end

    end
end
        


