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
ACTC.Program.version='0.1';

%% Display some kind of message about the program
% printmessage();
% Some kind of logging might also be a good idea. 
% add2log(0,['>>>> ',datestr(now,31), ' Session started'],1,1);

%% Add subdirectories to path
file = which('ACTC.m');
ACTC.Program.installDir = fileparts(file);
addpath(genpath_exclude(ACTC.Program.installDir));

%% Load default algoritm and data parameters
set_global_parameters;

%% Display some kind of message about the program
% Some kind of logging might also be a good idea. 
log_entry(['>>>> Session started <<<< actc version: ', ACTC.Program.version],1,1);

%% start a parpool using default parameters if needed
if ACTC.Program.parallelProcessing && isempty(gcp('nocreate'))
    parpool;
end

%% Check the number of arguments in and launch the appropriate script.
if nargin > 0
    %Batch Mode
    ACTC.Program.batchMode = 1;
    actc_batch_analysis(varargin{:});

else
    %GUI mode
    ACTC.Program.batchMode = 0;
    %display_logo;
    actc_gui;
    
end
log_entry('>>>> Session stopped <<<< ',1,1);
end

%% Helper functions
function p = genpath_exclude(d)
    % extension of the genpath function of matlab, inspired by the
    % genpath_exclude.m written by jhopkin posted on matlab central.  We use
    % a regexp to also exclude .git directories from our path.
    
    files = dir(d);
	if isempty(files)
	  return
	end

	% Add d to the path even if it is empty.
	p = [d pathsep];

	% set logical vector for subdirectory entries in d
	isdir = logical(cat(1,files.isdir));
	%
	% Recursively descend through directories which are neither
	% private nor "class" directories.
	%
	dirs = files(isdir); % select only directory entries from the current listing

	for i=1:length(dirs)
		dirname = dirs(i).name;
		%NOTE: regexp ignores '.', '..', '@.*', and 'private' directories by default. 
		if ~any(regexp(dirname,'^\.$|^\.\.$|^\@*|^\+*|^\.git|^private$|','start'))
		  p = [p genpath_exclude(fullfile(d,dirname))]; % recursive calling of this function.
		end
	end
end