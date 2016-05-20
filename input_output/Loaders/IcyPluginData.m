classdef IcyPluginData < handle
    %Class for loading of the xls files created by the icy plugin.
    
    properties
     
    end
    
    methods
        function locations=prior_locations_in_sample(this,samplePath)
            locations=[];
            [sample.priorPath,bool]=this.find_dir(samplePath,'xls',1);
            if bool 
                try temp=xlsread([sample.priorPath,filesep,'results.xls'],1);
                keyboard
                catch
                    %add logging
                end
            else
                %add logging
            end
        end
    end
end