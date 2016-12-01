classdef CustomCsv < handle
    %Class for loading of the xls files created by the icy plugin.
    
    properties
     
    end
    
    methods 
        function channelsUsed=look_for_custom_channels(this,samplePath)
            channelsUsed=[];
            [sample.priorPath,bool]=this.find_dir(samplePath,'csv',1);
            if bool==1 
                try t=readtable([sample.priorPath filesep 'customChannels.csv'],'delimiter',';');
                    channelsUsed=t.channelUsed;
                catch
                    %add logging
                end
            else
                %add logging
            end
        end
    end
    methods(Static)
        function create_custom_text(fileName,channelsUsed)
            n=numel(channelsUsed);
            names={'Exclusion Marker','Nucleus','Inclusion Marker', 'Additional Marker 1', 'Additional Marker 2','Additional Marker 3'};
            channelsUsed=[names(1:n);channelsUsed];
            t=table(names(1:n)',channelsUsed','variableNames',{'Type','channelsUsed'});
            writetable(t,'test.csv','delimiter',';')
        end
    end
end