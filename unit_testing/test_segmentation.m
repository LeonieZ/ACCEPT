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

%function ac = test_segmentation

% This function contains a unit test for the segmentation algorithm: It
% checks Matlab and the C/openMP version

% Clear command window, close all figures
clc; close all;
% Add subdirectories of main application folder to path
addpath(genpath(fullfile(pwd,'..','..')));

% fix random number generator so we can repeat the experiment
seed_clust = 0; RandStream.setGlobalStream(RandStream('mrg32k3a','Seed',seed_clust));

% load double/single image
balls_var_size;
var = 0.2;
f_true = imresize(single(IM),[1036 1248]); %randn(200,200,'single'); %1036x1248
clear IM IM2;
f = f_true + var * randn(size(f_true));

% generated segmentation object
lambda   = 5;
inner_it = 500;
breg_it  = 1;
ac = ActiveContourSegmentation(lambda,inner_it,breg_it);
ac.tol = 1e-9;

% run Bregman-CV segmentation
profile on;
tic; result = ac.run(f); toc;
profile off;
profile viewer;

% visualize result
%figure; imagesc(result);