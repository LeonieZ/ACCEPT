classdef io < handle
    %abstract class for various input classes
    
    properties
        data = dataframe(); % this variable will be filled with the available subclasses
        sample = sample()
    end
    
    methods
        function self = io()
        end
        function new_sample(path)
        end
        function data = load_data_frame(frameNr)
        end
        function save_data_frame(data)
        end
    end
    
end

