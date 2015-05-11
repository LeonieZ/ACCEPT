classdef io < handle
    %the toplevel class that handles the various input and output operations. It
    %allows for easy loading of different sample types
    
    properties
        dataFrame
        sample
        loader
        loaderTypesAvailable={};
        samplePath
        imagePath
        priorPath
        savePath
    end
    
    methods
        function obj = io(samplePath)
            obj.populate_available_input_types();
            
        end
        
        function new_sample(path)
        end
        
        function data = load_data_frame(obj,frameNr)
            data=obj.loader.load_data_frame(frameNr);
            obj.data=data;
        end
        
        function save_data_frame(data)
        end
    end
    methods (Access = private)
        function populate_available_input_types(obj)
            % list of all folders in FilterFunctions:
            temp = what('Loaders');
            flist = temp.m;

            for i=1:numel(flist)
               [~,filename,fileext]=fileparts(flist{i}); % get just the filename
               if exist(filename, 'class') && ismember('loader', superclasses(filename))
                 obj.loaderTypesAvailable{end+1} = @filename ;
               end
             end
        end
        
        function check_sample_type(obj,samplePath)
            for i=1:numel(obj.loaderTypesAvailable)
                eval(obj.loaderTypesAvailable{i})
            end
        end
    end
end
        


