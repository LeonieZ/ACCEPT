classdef IO < handle
    %the toplevel class that handles the various input and output operations. It
    %allows for easy loading of different sample types
    
    properties
        samplesPath
        savePath
        overwriteResults=false;
        loader
    end
    
    properties(SetAccess=private)
        loaderTypesAvailable={celltracks(),mcbp(),default()}; % beware of the order, the first loader type that can load a dir will be used.
        sampleList
    end
    properties(Access=private)
        nrOfSamples
        currentSampleNr
    end
    
    events
        logMessage
    end
    
    methods
        function this = io(samplesPath,savePath)
            this.samplesPath=samplesPath;
            this.savePath=savePath;
        end
        
        function set.savePath(this,path)
            if exist(path,'dir')
                this.savePath=path;
            else
                mkdir(path);
                mkdir([path,filesep,'output']);
                mkdir([path,filesep,'frames'])
                this.savePath=path;
            end
            this.create_sample_list;
        end
        
        function set.samplesPath(this,path)
            this.samplesPath=path;
            this.create_sample_list;
        end
        
        function set.overwriteResults(this,bool)
            this.overwriteResults=bool;
            this.create_sample_list;
        end
        
        function sampleOut=load_next_sample(this)
            %Will load the next sample in the sampleList
            if this.currentSampleNr==this.nrOfSamples
                sampleOut=this.loader.sample;
            else
                this.currentSampleNr=this.currentSampleNr+1;
                samplePath=fullfile(this.samplesPath,this.sampleList{this.currentSampleNr});
                this.loader=this.check_sample_type(samplePath);
                sampleOut=this.loader.load_sample();
            end
        end
        
        function save_work_flow(this,workFlow)
            save([this.savePath,filesep,'workflow.mat'],'workFlow');
        end
        
        function save_sample(this,currentSample)
            save([this.savePath,filesep,'output',filesep,currentSample.name,'.mat'],'currentSample');
        end
        
        function save_results(this,currentSample)
            save([this.savePath,filesep,'output',filesep,currentSample.name,'.mat'],'currentSample.results','-append');        
        end
        
        function save_data_frame(this,currentSample,currentDataFrame)
            if ~exist([this.savePath,filesep,'frames',filesep,currentSample.name],'dir')
                mkdir([this.savePath,filesep,'frames',filesep,currentSample.name]);
            end
            save([this.savePath,filesep,'frames',filesep,currentSample.name,filesep,num2str(currentDataFrame.frameNr),'.mat'],'currentDataFrame');            
    
        end
        
        function save_data_frame_segmentation(this,currentSample,currentDataFrame)
            if ~exist([this.savePath,filesep,'frames',filesep,currentSample.name],'dir')
                mkdir([this.savePath,filesep,'frames',filesep,currentSample.name]);
            end
            t=Tiff([this.savePath,filesep,'frames',filesep,currentSample.name,filesep,num2str(currentDataFrame.frameNr),'_seg.tif'],'w');
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
                try load([this.savePath filesep processed.mat],samplesProccesed)
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
        


