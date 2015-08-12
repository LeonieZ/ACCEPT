classdef io < handle
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
        function self = io(samplesPath,savePath)
            self.samplesPath=samplesPath;
            self.savePath=savePath;
        end
        
        function set.savePath(self,path)
            if exist(path,'dir')
                self.savePath=path;
            else
                mkdir(path);
                mkdir([path,filesep,'output']);
                mkdir([path,filesep,'frames'])
                self.savePath=path;
            end
            self.create_sample_list;
        end
        
        function set.samplesPath(self,path)
            self.samplesPath=path;
            self.create_sample_list;
        end
        
        function set.overwriteResults(self,bool)
            self.overwriteResults=bool;
            self.create_sample_list;
        end
        
        function sampleOut=load_next_sample(self)
            %Will load the next sample in the sampleList
            if self.currentSampleNr==self.nrOfSamples
                sampleOut=self.loader.sample;
            else
                self.currentSampleNr=self.currentSampleNr+1;
                samplePath=fullfile(self.samplesPath,self.sampleList{self.currentSampleNr});
                self.loader=self.check_sample_type(samplePath);
                sampleOut=self.loader.load_sample();
            end
        end
        
        function save_work_flow(self,workFlow)
            save([self.savePath,filesep,'workflow.mat'],'workFlow');
        end
        
        function save_sample(self,currentSample)
            save([self.savePath,filesep,'output',filesep,currentSample.name,'.mat'],'currentSample');
        end
        
        function save_results(self,currentSample)
            save([self.savePath,filesep,'output',filesep,currentSample.name,'.mat'],'currentSample.results','-append');        
        end
        
        function save_data_frame(self,currentSample,currentDataFrame)
            if ~exist([self.savePath,filesep,'frames',filesep,currentSample.name],'dir')
                mkdir([self.savePath,filesep,'frames',filesep,currentSample.name]);
            end
            save([self.savePath,filesep,'frames',filesep,currentSample.name,filesep,num2str(currentDataFrame.frameNr),'.mat'],'currentDataFrame');            
    
        end
        
        function save_data_frame_segmentation(self,currentSample,currentDataFrame)
            if ~exist([self.savePath,filesep,'frames',filesep,currentSample.name],'dir')
                mkdir([self.savePath,filesep,'frames',filesep,currentSample.name]);
            end
            t=Tiff([self.savePath,filesep,'frames',filesep,currentSample.name,filesep,num2str(currentDataFrame.frameNr),'_seg.tif'],'w');
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
        
        function save_thumbnail(self,currentSample,eventNr)
            
        end
        
        
         
    end
    
    
    methods (Access = private)
        function populate_available_input_types(self)
            % populate available inputs 
            % Function not used atm /g
            temp = what('Loaders');
            flist = temp.m;

            for i=1:numel(flist)
               [~,filename,fileext]=fileparts(flist{i}); % get just the filename
               if exist(filename, 'class') && ismember('loader', superclasses(filename))
                 self.loaderTypesAvailable{end+1} = filename();
               end
             end
        end
        
        function loaderHandle=check_sample_type(self,samplePath)
            %Checks which loader types can load the sample path and chooses
            %the first one on the list. 
            for i=1:numel(self.loaderTypesAvailable)
                canLoad(i) = self.loaderTypesAvailable{i}.can_load_this_folder(samplePath);
            end
            loaderHandle=self.loaderTypesAvailable{find(canLoad,1)};
            loaderHandle.new_sample_path(samplePath);
        end
        
        function create_sample_list(self)
            %creates list of samples from input dir. It also checks if
            %these samples are already processed in the output dir when the
            %overwriteResults attribute is set to false. 
            files = dir(self.samplesPath);
            if isempty(files)
                self.log.entry('inputDir is empty; cannot continue',1,1);
                error('inputDir is empty; cannot continue');
            end

            % select only directory entries from the input listing and remove
            % anything that starts with a .*.
            inputList = files([files.isdir] & ~strncmpi('.', {files.name}, 1)); 

            %Check in results dir if any samples are already processed.
            if self.overwriteResults==false
                try load([self.savePath filesep processed.mat],samplesProccesed)
                catch 
                    %appears to be no lest (?) so lets create an empty sampleProccesed variable
                    sampleProccessed=['empty'];
                end
                self.sampleList=setdiff({inputList.name},sampleProccessed);
            else
                self.sampleList=inputList;
            end
            self.nrOfSamples=numel(inputList);
            self.currentSampleNr=0;
        end

    end
end
        


