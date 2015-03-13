function actc(varargin)
%% Automated CTC image analysis algorithm
% main function to run the image analysis algorithm for the detection of
%circulating tumor cells. If given input arguments it will run in batch
%mode. The function accepts the following input arguments:
%.....
%Developed for the european CANCER-ID project by Leonie Zeune, Guus
%van Dalum, Christoph Brune and Leon Terstappen. 


%% Clear command window, close all figures and clear global struct used to
% pass information between functions. 
clc;
close all
clear global ACTC

global ACTC
%% store some kind of version label
ACTC.ProgP.version='0.1';

%% Display some kind of message about the program
% printmessage();
% Some kind of logging might also be a good idea. 
% add2log(0,['>>>> ',datestr(now,31), ' Session started'],1,1);

%% Add subdirectories to path
file = which('ACTC.m');
ACTC.ProgP.install_dir = fileparts(file);
addpath(genpath(ACTC.ProgP.install_dir));

%% Load default algoritm and data parameters

set_default_parameteters;

%% Check the number of arguments in and launch the appropriate script.
if nargin > 0
    %Batch Mode
    ACTC.ProgP.batch_mode = 1;
    ACTC_batchanalysis(varargin{:});

else
    %GUI mode
    ACTC.PropP.batch_mode = 0;
    %display_logo;
    ACTC_gui;
    
end
end