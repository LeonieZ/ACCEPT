close all;
clear all;

%%% open new Icy session?
% eval('!open /Applications/icy/icy.app');
% pause(6);


%Data specifications
dataP = get_data_parameter;

%Algorithm specifications
algP = get_alg_parameter;


%Load personal data folder preferences
dataP = set_data_parameter(dataP)

%%% Check for image dir
% Check if directory where cartridge directories are located is given.
% Otherwise ask user input.

if isempty(dataP.input_folder)
    dataP.input_folder = uigetdir(pwd, 'Choose path containing cartridge directories...');
end

%%% Check if directory to save files exists, otherwise ask user for input.
if isempty(dataP.output_folder)
    dataP.output_folder = uigetdir(pwd, 'Choose path to safe files...');
end

if algP.save_result == true
    CTC_detection(dataP, algP);
else
    [res, stat, dataP, algP] = CTC_detection(dataP, algP); 
end