classdef DepArray < Loader & IcyPluginData
    %DEFAULT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='DepArray'
        channelNames='Unknown' 
        channelEdgeRemoval=1;
        hasEdges='false'
        pixelSize=0.64
        sample
    end
    
    methods
        function this=DepArray(input)
            if nargin == 1
                validateattributes(input,{'Sample','char'},{'nonempty'},'','input');
                if isa(input,'Sample')
                    if strcmp(input.type,this.name)
                        this.sample=input;
                    else
                    error('tried to use incorrect sampletype with DepArray Loader');
                    end
                else
                    this=this.new_sample_path(input);
                end
            end
            
        end
        function new_sample_path(this,samplePath)
            this.sample=Sample();
            this.sample.type = this.name;
            this.sample.loader = @DepArray;
            splitPath = regexp(samplePath, filesep, 'split');
            if isempty(splitPath{end})
                this.sample.id=splitPath{end-1};
            else
                this.sample.id=splitPath{end};
            end
            this.sample.pixelSize = this.pixelSize;
            this.sample.hasEdges = this.hasEdges;
            this.sample.channelEdgeRemoval = this.channelEdgeRemoval;
%             customChannelsUsed=this.look_for_custom_channels(samplePath);
%             if ~isempty(customChannelsUsed)
%                 this.channelsUsed=customChannelsUsed;
%             end
            this.load_scan_info(samplePath);
            this.preload_tiff_headers(samplePath);
            this.sample.priorLocations = this.prior_locations_in_sample(samplePath);
            this.calculate_frame_nr_order();
        end
        
        function update_prior_infos(this,currentSample,samplePath)
        end
        
        function dataFrame = load_data_frame(this,frameNr)
        
        end
        
        function rawImage = load_raw_image(this,frameNr)

        end
        
        function dataFrame = load_thumb_frame(this,frameNr,option)
        end
        function frameOrder = calculate_frame_nr_order(this)    
        end
    end
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class.         
            [txtDir,dirFound]=Loader.find_dir(path,'txt',1);
            if dirFound
                tempTxtFileNames = dir([txtDir filesep '*.txt']);
                for i=1:numel(tempTxtFileNames)
                    nameArray{i}=tempTxtFileNames(i).name;
                end
                test=strcmp(nameArray(:),'Parameters.txt');
                bool=any(test);
            else
                bool = false;
            end
                
        end    
    end
end


