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
var = 0.1;
f_true = imresize(single(IM),[1036 1248]); %randn(200,200,'single'); %1036x1248
clear IM IM2;
f = f_true + var * randn(size(f_true));

% generated segmentation object
lambda   = 5;
inner_it = 5;
breg_it  = 5;
ac = ActiveContourSegmentation(lambda,inner_it,breg_it);
ac.tol = eps;

% run Bregman-CV segmentation
profile on;
tic; result = ac.run(f); toc;
profile off;
profile viewer;

% visualize result
figure; imagesc(result);