function [ ] = load_file(~,~)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
global i gui name score score_res

[input_name, input_path] = uigetfile('.mat','Choose input file.');
file = load([input_path filesep input_name]);
input = file.thumbs;

gui.thumbs = input.thumbs;

gui.mini = input.mini;
gui.maxi = input.maxi;
gui.bit = input.bit;
gui.imNr = 1;
score = cell(1,size(gui.thumbs,2));
i = 1;

pos = get(gui.waitbar,'position');  
pos(3) = 0.0001; 
set(gui.waitbar,'position',pos,'string','','FontSize',20) 

refresh_gui(gui,score,1);

%create new results file
score_res = scoring_output(cell(size(gui.thumbs,2)), name);
% score_res = scoring_output(cell(size(gui.thumbs,2)), name, id);
save_res(score_res);

end

