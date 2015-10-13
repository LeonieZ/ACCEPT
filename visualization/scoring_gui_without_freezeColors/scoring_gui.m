function scoring_gui(varargin)

clear -global sc_gui score i
global i score sc_gui name score_res

if nargin == 1 && isa(varargin{1},'Sample')
    input = varargin{1};    
else
    [input_name, input_path] = uigetfile('.mat','Choose input file.');
    file = load([input_path filesep input_name]);
    if isa(file.currentSample,'Sample')
        input = file.currentSample;
    else
        error('Load input file of type Sample')
    end
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

% %create results file
% score_res = scoring_output(score, name);
% % score_res = scoring_output(score, name, id);
% save_res(score_res);

%define colorbars
sc_gui.map_blue = zeros(64,3);sc_gui.map_blue(:,3) = linspace(0,1,64);
sc_gui.map_red = zeros(64,3);sc_gui.map_red(:,1) = linspace(0,1,64);
sc_gui.map_green = zeros(64,3);sc_gui.map_green(:,2) = linspace(0,1,64);


%Menu
screensize = get( 0, 'Screensize' );

%window
posx = 0.15; posy = 0.2; width = 0.7; height = 0.7;
sc_gui_color = [1 1 1];
sc_gui.fig_main = figure('Units','normalized','Position',[posx posy width height],'Name','Scoring Tool for CTCs','KeyPressFcn', @keypress_input,...
    'MenuBar','none','NumberTitle','off','Color', sc_gui_color,'Visible', 'off');
%specify toolbar
sc_gui.menu.menu_1  = uimenu(sc_gui.fig_main,'Label','File');
sc_gui.menu.menu_1a = uimenu(sc_gui.menu.menu_1,'Label','Open...','Accelerator','O','Callback',@load_file); 

sc_gui.menu.menu_1  = uimenu(sc_gui.fig_main,'Label','Help');
sc_gui.menu.menu_1a = uimenu(sc_gui.menu.menu_1,'Label','Open Explanation...','Accelerator','E','Callback',@explanation); 

sc_gui.framex = 0.2; sc_gui.boundaryx = 0.005; sc_gui.spacex = (1 - 2* sc_gui.boundaryx - 4 * sc_gui.framex)/5; 
sc_gui.framey = (width * sc_gui.framex * screensize(3))/(height * screensize(4)); sc_gui.boundaryy = 0.2; sc_gui.spacey = (1 - sc_gui.boundaryy - 2 * sc_gui.framey)/3; 

%frames for each image plus axis with initial images
sc_gui.frame = uipanel('Units','normalized','Title','Overlay','FontUnits', 'normalized', 'FontSize',0.05,'Position',[(sc_gui.spacex+sc_gui.boundaryx) (sc_gui.spacey+sc_gui.boundaryy) sc_gui.framex sc_gui.framey],'BackgroundColor',sc_gui_color);
sc_gui.im1_ax = axes('Units','normalized','parent',sc_gui.frame,'visible','off','Position',[0,0,1,1]);
if sc_gui.maxi == 255
        sc_gui.im1 = imagesc(flip(uint8(sc_gui.thumbs{i}),3)); 
    else
        sc_gui.im1 = imagesc(flip((single(sc_gui.thumbs{i})/single(sc_gui.maxi)),3)); 
end


sc_gui.frame = uipanel('Units','normalized','Title','DNA Marker','FontUnits', 'normalized', 'FontSize',0.05,'Position',[(sc_gui.framex+2*sc_gui.spacex+sc_gui.boundaryx) (sc_gui.spacey+sc_gui.boundaryy) sc_gui.framex sc_gui.framey],'BackgroundColor',sc_gui_color);
sc_gui.im2_ax = axes('Units','normalized','parent',sc_gui.frame,'visible','off','Position',[0,0,1,1]);
sc_gui.im2 = imagesc(cat(3,zeros(size(sc_gui.thumbs{i}(:,:,1))),zeros(size(sc_gui.thumbs{i}(:,:,1))),single(sc_gui.thumbs{i}(:,:,1))/single(sc_gui.maxi))); axis off;%colormap(sc_gui.im2_ax, sc_gui.map_blue); set(sc_gui.im2_ax,'visible','off','CLim',[sc_gui.mini, sc_gui.maxi]); %freezeColors;

sc_gui.frame = uipanel('Units','normalized','Title','Inclusion Marker','FontUnits', 'normalized', 'FontSize',0.05,'Position',[(2*sc_gui.framex+3*sc_gui.spacex+sc_gui.boundaryx) (sc_gui.spacey+sc_gui.boundaryy) sc_gui.framex sc_gui.framey],'BackgroundColor',sc_gui_color);
sc_gui.im3_ax = axes('Units','normalized','parent',sc_gui.frame,'visible','off','Position',[0,0,1,1]);
sc_gui.im3 = imagesc(cat(3,zeros(size(sc_gui.thumbs{i}(:,:,2))),single(sc_gui.thumbs{i}(:,:,2))/single(sc_gui.maxi),zeros(size(sc_gui.thumbs{i}(:,:,2))))); axis off;%colormap(sc_gui.im3_ax, sc_gui.map_green); set(sc_gui.im3_ax,'visible','off','CLim',[sc_gui.mini, sc_gui.maxi]); %freezeColors;

sc_gui.frame = uipanel('Units','normalized','Title','WBC Exclusion Marker','FontUnits', 'normalized', 'FontSize',0.05,'Position',[(3*sc_gui.framex+4*sc_gui.spacex+sc_gui.boundaryx) (sc_gui.spacey+sc_gui.boundaryy) sc_gui.framex sc_gui.framey],'BackgroundColor',sc_gui_color);
sc_gui.im4_ax = axes('Units','normalized','parent',sc_gui.frame,'visible','off','Position',[0,0,1,1]);
sc_gui.im4 = imagesc(cat(3,single(sc_gui.thumbs{i}(:,:,3))/single(sc_gui.maxi),zeros(size(sc_gui.thumbs{i}(:,:,3))),zeros(size(sc_gui.thumbs{i}(:,:,3))))); axis off;%colormap(sc_gui.im4_ax, sc_gui.map_red); set(sc_gui.im4_ax,'visible','off','CLim',[sc_gui.mini, sc_gui.maxi]); %freezeColors;

sc_gui.frame = uipanel('Units','normalized','Title','Overlay','FontUnits', 'normalized', 'FontSize',0.05,'Position',[(sc_gui.spacex+sc_gui.boundaryx) (sc_gui.framey+2*sc_gui.spacey+sc_gui.boundaryy) sc_gui.framex sc_gui.framey],'BackgroundColor',sc_gui_color);
sc_gui.im5_ax = axes('Units','normalized','parent',sc_gui.frame,'visible','off','Position',[0,0,1,1]);
if sc_gui.maxi == 255
    sc_gui.im5 = imagesc(flip(uint8((sc_gui.thumbs{i}-repmat(min(min(sc_gui.thumbs{i})),size(sc_gui.thumbs{i},1),size(sc_gui.thumbs{i},2),1))*255./repmat(max(max(sc_gui.thumbs{i}-repmat(min(min(sc_gui.thumbs{i})),size(sc_gui.thumbs{i},1),size(sc_gui.thumbs{i},2),1))),size(sc_gui.thumbs{i},1),size(sc_gui.thumbs{i},2),1)),3));
else
    sc_gui.im5 = imagesc(flip(single(sc_gui.thumbs{i}-repmat(min(min(sc_gui.thumbs{i})),size(sc_gui.thumbs{i},1),size(sc_gui.thumbs{i},2),1))./single(repmat(max(max(sc_gui.thumbs{i}-repmat(min(min(sc_gui.thumbs{i})),size(sc_gui.thumbs{i},1),size(sc_gui.thumbs{i},2),1))),size(sc_gui.thumbs{i},1),size(sc_gui.thumbs{i},2),1)),3));
end    
set(sc_gui.im5_ax,'visible','off'); %freezeColors;
 
sc_gui.frame = uipanel('Units','normalized','Title','DNA Marker','FontUnits', 'normalized', 'FontSize',0.05,'Position',[(sc_gui.framex+2*sc_gui.spacex+sc_gui.boundaryx) (sc_gui.framey+2*sc_gui.spacey+sc_gui.boundaryy) sc_gui.framex sc_gui.framey],'BackgroundColor',sc_gui_color);
sc_gui.im6_ax = axes('Units','normalized','parent',sc_gui.frame,'visible','off','Position',[0,0,1,1]);
sc_gui.im6 = imagesc(cat(3,zeros(size(sc_gui.thumbs{i}(:,:,1))),zeros(size(sc_gui.thumbs{i}(:,:,1))),single(sc_gui.thumbs{i}(:,:,1)-min(min(sc_gui.thumbs{i}(:,:,1))))/single(max(max(sc_gui.thumbs{i}(:,:,1)))))); axis off;%colormap(sc_gui.im6_ax, sc_gui.map_blue); set(sc_gui.im6_ax,'visible','off','CLim',[min(min(sc_gui.thumbs{i}(:,:,1))),max(max(sc_gui.thumbs{i}(:,:,1)))]); %freezeColors;
 
sc_gui.frame = uipanel('Units','normalized','Title','Inclusion Marker','FontUnits', 'normalized', 'FontSize',0.05,'Position',[(2*sc_gui.framex+3*sc_gui.spacex+sc_gui.boundaryx) (sc_gui.framey+2*sc_gui.spacey+sc_gui.boundaryy) sc_gui.framex sc_gui.framey],'BackgroundColor',sc_gui_color);
sc_gui.im7_ax = axes('Units','normalized','parent',sc_gui.frame,'visible','off','Position',[0,0,1,1]);
sc_gui.im7 = imagesc(cat(3,zeros(size(sc_gui.thumbs{i}(:,:,2))),single(sc_gui.thumbs{i}(:,:,2)-min(min(sc_gui.thumbs{i}(:,:,2))))/single(max(max(sc_gui.thumbs{i}(:,:,2)))),zeros(size(sc_gui.thumbs{i}(:,:,2))))); axis off; %colormap(sc_gui.im7_ax, sc_gui.map_green); set(sc_gui.im7_ax,'visible','off','CLim',[min(min(sc_gui.thumbs{i}(:,:,2))),max(max(sc_gui.thumbs{i}(:,:,2)))]); %freezeColors;

sc_gui.frame = uipanel('Units','normalized','Title','WBC Exclusion Marker','FontUnits', 'normalized', 'FontSize',0.05,'Position',[(3*sc_gui.framex+4*sc_gui.spacex+sc_gui.boundaryx) (sc_gui.framey+2*sc_gui.spacey+sc_gui.boundaryy) sc_gui.framex sc_gui.framey],'BackgroundColor',sc_gui_color);
sc_gui.im8_ax = axes('Units','normalized','parent',sc_gui.frame,'visible','off','Position',[0,0,1,1]);
sc_gui.im8 = imagesc(cat(3,single(sc_gui.thumbs{i}(:,:,3)-min(min(sc_gui.thumbs{i}(:,:,3))))/single(max(max(sc_gui.thumbs{i}(:,:,3)))),zeros(size(sc_gui.thumbs{i}(:,:,3))),zeros(size(sc_gui.thumbs{i}(:,:,3))))); axis off; %colormap(sc_gui.im8_ax, sc_gui.map_red); set(sc_gui.im8_ax,'visible','off','CLim',[min(min(sc_gui.thumbs{i}(:,:,3))),max(max(sc_gui.thumbs{i}(:,:,3)))]); %freezeColors;

sc_gui.text_title = uicontrol('Units','normalized','Style','text','Position',[(sc_gui.spacex+sc_gui.boundaryx) (sc_gui.framey+sc_gui.spacey+sc_gui.boundaryy) .2 .8*sc_gui.spacey],'String','Unscaled Image','HorizontalAlignment','left','FontUnits', 'normalized', 'FontSize',0.7,'BackgroundColor',sc_gui_color,'FontWeight','bold');
sc_gui.text_title = uicontrol('Units','normalized','Style','text','Position',[(sc_gui.spacex+sc_gui.boundaryx) (2*sc_gui.framey+2*sc_gui.spacey+sc_gui.boundaryy) .2 .8*sc_gui.spacey],'String','Scaled Image','HorizontalAlignment','left','FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',sc_gui_color,'FontWeight','bold');

sc_gui.sld = uicontrol('Units','normalized','Style', 'slider','Min',1,'Max',size(sc_gui.thumbs,2),'Value',1,'Position', [(sc_gui.spacex+sc_gui.boundaryx) (sc_gui.spacey+sc_gui.boundaryy-0.05) (4*sc_gui.framex+3*sc_gui.spacex) .03],'Callback', @move_slider);
set(sc_gui.sld, 'SliderStep', [1, 1] / (size(sc_gui.thumbs,2) - 1));

sc_gui.thumbs_number_text  = uicontrol('Units','normalized','Style','text','Position',[0.2775 (sc_gui.spacey+sc_gui.boundaryy-0.12) .15 .045],'String','Cell Number:','HorizontalAlignment','center','FontUnits', 'normalized','FontSize',0.65,'BackgroundColor',sc_gui_color);
sc_gui.thumbs_number = uicontrol('Units','normalized','Style','edit','Position', [0.4275 (sc_gui.spacey+sc_gui.boundaryy-0.12) .045 .045], 'String',num2str(sc_gui.imNr),'Callback', @write_nr,'HorizontalAlignment','center','FontUnits', 'normalized','FontSize',0.65);

sc_gui.score_text  = uicontrol('Units','normalized','Style','text','Position',[0.5275 (sc_gui.spacey+sc_gui.boundaryy-0.12) .15 .045],'String','Cell Score:','HorizontalAlignment','center','FontUnits', 'normalized','FontSize',0.65,'BackgroundColor',sc_gui_color);
sc_gui.score  = uicontrol('Units','normalized','Style','edit','Position',[0.6775 (sc_gui.spacey+sc_gui.boundaryy-0.12) .045 .045],'String','-','Callback', @write_score,'HorizontalAlignment','center','FontUnits', 'normalized','FontSize',0.65); 


sc_gui.waitbar_background = uicontrol('style','edit','Enable','inactive', 'units','normalized', 'position',[(sc_gui.spacex+sc_gui.boundaryx) (sc_gui.spacey+sc_gui.boundaryy-0.2) (4*sc_gui.framex+3*sc_gui.spacex) .03],'String', 'Progress Bar','HorizontalAlignment','center','FontUnits', 'normalized','FontSize',0.7, 'BackgroundColor',[.82 .82 .82],'foregroundcolor',[.0 .0 .0]); 
sc_gui.waitbar = uicontrol('style','edit','Enable','inactive','units','normalized', 'position',[(sc_gui.spacex+sc_gui.boundaryx) (sc_gui.spacey+sc_gui.boundaryy-0.2) 0.0001 .03], 'backgroundcolor','blue', 'foregroundcolor','white'); 

set(sc_gui.fig_main, 'Visible','on');
end

function write_nr(source,~)

global sc_gui score i

i=str2num(get(source,'String'));
refresh_sc_gui(sc_gui,score,i);

end

function write_score(source,~)

global sc_gui score i

j=str2num(get(source,'String'));
if j == 1 || j == 3 || j == 5 || j == 7|| j == 9
    score{i} = j;
end
refresh_sc_gui(sc_gui,score,i);
end

function move_slider(source,~)

global sc_gui score i

i=round(get(source,'Value'));
refresh_sc_gui(sc_gui,score,i);

end


