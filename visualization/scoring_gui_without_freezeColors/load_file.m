function [ ] = load_file(~,~)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
global i sc_gui name score score_res

[input_name, input_path] = uigetfile('.mat','Choose input file.');
    file = load([input_path filesep input_name]);
    if isa(file.currentSample,'Sample')
        input = file.currentSample;
    else
        error('Load input file of type Sample')
    end

for i = 1:size(input.results.thumbnail_images,2)
    rawImage = input.results.thumbnail_images{i};
    sc_gui.thumbs{i}(:,:,1) = rawImage(:,:,find(~cellfun(@isempty,strfind(input.channelNames,'DNA'))));
    sc_gui.thumbs{i}(:,:,2) = rawImage(:,:,find(~cellfun(@isempty,strfind(input.channelNames,'CK'))));
    sc_gui.thumbs{i}(:,:,3) = rawImage(:,:,find(~cellfun(@isempty,strfind(input.channelNames,'CD45'))));    
end
% change sc_gui.mini and sc_gui.maxi to min to max of whole sample instead of possible min and max value for this class?!
if ~isempty(input.histogram)
    [row,~] = find(input.histogram ~= 0);
    sc_gui.mini = min(row);
    sc_gui.maxi = max(row);
elseif strcmp(input.dataTypeOriginalImage,'uint8')
    sc_gui.mini = 0;
    sc_gui.maxi = 255;
elseif strcmp(input.dataTypeOriginalImage,'uint12')
    sc_gui.mini = 0;
    sc_gui.maxi = 4095;
else
    sc_gui.mini = 0;
    sc_gui.maxi = 65535;
end
sc_gui.imNr = 1;

if sc_gui.maxi == 65535 && max(cellfun(@(x)max(max(max(x))),sc_gui.thumbs(1,:))) <= 4095
    sc_gui.maxi = 4095;
end

score = cell(1,size(sc_gui.thumbs,2));
i = 1;

pos = get(sc_gui.waitbar,'position');  
pos(3) = 0.0001; 
set(sc_gui.waitbar,'position',pos,'string','','FontUnits', 'normalized','FontSize',0.7) 

refresh_sc_gui(sc_gui,score,1);

% %create new results file
% score_res = scoring_output(cell(size(gui.thumbs,2)), name);
% % score_res = scoring_output(cell(size(gui.thumbs,2)), name, id);
% save_res(score_res);

end



