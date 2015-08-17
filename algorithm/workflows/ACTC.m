classdef ACTC
    %ACTC This workflow replicates the ACTC algorithm originally developed by Sjoerd Ligthart
    %   Use run_workflow to apply it on a cartridge.
    %   This is still a work in progress \G
    
    properties
    end
    
    methods
        function this=ACTC()
        
        end
        
        function run_workflow(this,currentSample)
        %modified run function due to the implementation of a global
        %threshold. 
        
            if isempty(this.algorithm)
                notify(this,'logMessage',logmessage(1,[this.name,'no results applied an empty workflow on sample.']));
            else
                hist=[];
                for j=1:currentSample.nrOfFrames
                    data=this.io.loader.load_data_frame(j);
                    tempHist=this.algorithm{1}.create_global_hist(data);
                    hist=hist+tempHist;
                end
                for j=1:currentSample.nrOfFrames
                    data=IO.loader.load_data_frame(j);
                    for i=2:numel(this.algorithm)
                        data=this.algorithm{i}.run(data);
                    end
                    currentSample.results.features=vertcat(currentSample.results.features,data.features);
                    currentSample.results.classefication=vertcat(currentSample.results.classefication,data.classificationResults);
                    currentSample.results.thumbnails=vertcat(currentSample.results.thumbnails,data.thumbnails);
                end
            end
        end
    end
    
end

