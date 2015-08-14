classdef ACTC
    %ACTC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function self=ACTC()
        
        end
        
        function run_workflow(self,IO,currentSample)
        %modified run function due to the implementation of a global
        %threshold. 
        
            if isempty(self.algorithm)
                notify(self,'logMessage',logmessage(1,[self.name,'no results applied an empty workflow on sample.']));
            else
                hist=[];
                for j=1:currentSample.nrOfFrames
                    data=IO.loader.load_data_frame(j);
                    tempHist=self.algorithm{1}.create_global_hist(data);
                    hist=hist+tempHist;
                end
                for j=1:currentSample.nrOfFrames
                    data=IO.loader.load_data_frame(j);
                    for i=2:numel(self.algorithm)
                        data=self.algorithm{i}.run(data);
                    end
                    currentSample.results.features=vertcat(currentSample.results.features,data.features);
                    currentSample.results.classefication=vertcat(currentSample.results.classefication,data.classificationResults);
                    currentSample.results.thumbnails=vertcat(currentSample.results.thumbnails,data.thumbnails);
                end
            end
        end
    end
    
end

