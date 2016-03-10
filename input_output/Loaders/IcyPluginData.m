classdef IcyPluginData < handle
    %Class for loading of the xls files created by the icy plugin.
    
    properties
     
    end
    
    methods
        function locations=prior_locations_in_sample(this,sample)
        temp=readxls([sample.priorPath,filesep,'results.xls'],1);
        end
    end
end