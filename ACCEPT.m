%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 
function [uiHandle,base]=ACCEPT(varargin)
    %% Automated CTC Classification Enumeration and PhenoTyping algorithm
    % main function to run the image analysis algorithm for the detection
    % of circulating tumor cells. If given input arguments it will run in
    % cli mode. Without any arguments the GUI will start.
    % The function 
    % accepts the following input arguments: ..... 

    %% Clear command window, close all figures and clear global struct used to
    % pass information between functions. 
    clc;
    close all
    
    %% Add subdirectories to path
    file = which('ACCEPT.m');
    installDir = fileparts(file);
    addpath(genpath_exclude(installDir));
    
    %% start the base class
    base = Base();
    
    %% Create input parser, check the number of arguments in and launch the appropriate script.
    parser = gen_input_parser(base);
    parse(parser,varargin{:});
    if parser.Results.noGui==false
        uiHandle = gui_main(base,installDir);
    elseif parser.Results.noGui==true && ~isempty(parser.Results.inputFolder) && ~isempty(parser.Results.outputFolder)
        if strfind(parser.Results.inputFolder,'ACCEPT') == 1
            path = strsplit(parser.Results.inputFolder,'ACCEPT');
            base.sampleList.inputPath = [installDir path{2}];
        else
            base.sampleList.inputPath = parser.Results.inputFolder;
        end
        if strfind(parser.Results.outputFolder,'ACCEPT') == 1
            path = strsplit(parser.Results.outputFolder,'ACCEPT');
            base.sampleList.resultPath = [installDir path{2}];
        else
            base.sampleList.resultPath = parser.Results.outputFolder;
        end
        if isempty(parser.Results.sampleName)
            base.sampleList.toBeProcessed = ~base.sampleList.isProcessed;
        else
            base.sampleList.toBeProcessed = strcmp(base.sampleList.sampleNames,parser.Results.sampleName);
        end
        if ~isempty(parser.Results.customFunction)
            name = strsplit(parser.Results.customFunction,'.');
            fh = str2func(name{1});
            fh(base)
        end
        if ~isempty(parser.Results.sampleProcessor)
            base.run();
        end
    end
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

function parser = gen_input_parser(base)
    % Construct the inputParster object to check varargin
    parser=inputParser;
    parser.FunctionName='batchmode input parser';
    parser.addOptional('noGui',false,@(x)islogical(x));
    %Additional options can be added here
    parser.addOptional('sampleProcessor',[],@(a) any(validatestring(a,base.availableSampleProcessors)));
    %Optional: io atributes, defaults set to io defaults.
    parser.addOptional('inputFolder',[],@(x) isdir(x));
    parser.addOptional('outputFolder',[],@(x) isdir(x));
    parser.addOptional('sampleName',[],@(x) isstr(x));
    parser.addOptional('customFunction',[],@(x) (exist(x,'file')==2))
end