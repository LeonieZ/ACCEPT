classdef io < handle
    %the toplevel class that handles the various input and output operations. It
    %allows for easy loading of different sample types
    
    properties
        loaderTypesAvailable={celltracks(),mcbp(),default()}; % beware of the order, the first loader type that can load a dir will be used.
        samplesPath
        savePath
        sampleList
        nrOfSamples
        currentSample
        overwriteResults=false;
        log
    end
    
    methods
        function self = io(log,samplesPath,savePath)
            self.log=log;
            self.samplesPath=samplesPath;
            self.savePath=savePath;
        end
        
        function sampleOut=load_next_sample(self)
            %Will load the next sample in the sampleList
            self.currentSample=self.currentSample+1;
            samplePath=fullfile(self.samplesPath,self.sampleList{self.currentSample});
            loaderHandle=self.check_sample_type(samplePath);
            sampleOut=loaderHandle.load_sample();
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
            self.currentSample=0;
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
            loaderHandle=self.loaderTypesAvailable{find(canLoad,1)}(samplePath);
        end
    end
end
        


