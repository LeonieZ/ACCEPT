function dataP=set_data_parameter(dataP)
% seperate file for individual folder preferences. 
% if we ignore this file after downloading we will not constantly change eachothers defaults. 
dataP.input_folder = '/Users/ZeuneL/Documents/MATLAB/CTC_project/Data/single_data_set'; %path containing cartridge dirs
dataP.output_folder = [pwd filesep 'results']; %directory to save files
