function scoring_gui(varargin)

global i score gui name score_res

uni_logo = imread('logo3.png'); [uni_logo_x, uni_logo_y, ~] = size(uni_logo); uni_logo_rel = uni_logo_x / uni_logo_y
cancerid_logo = imread('logo.png'); [cancerid_logo_x, cancerid_logo_y, ~] = size(cancerid_logo); cancerid_logo_rel = cancerid_logo_x / cancerid_logo_y
subtitle = imread('title.png'); [subtitle_x, subtitle_y, ~] = size(subtitle); subtitle_rel = subtitle_x / subtitle_y;

% if nargin == 1
%     input = varargin{1};
%     gui.thumbs = input.thumbs;
%     
%     % change gui.mini and gui.maxi to min to max of whole sample instead of possible min and max value for this class?!
%     gui.mini = input.mini;
%     gui.maxi = input.maxi;
%     gui.bit = input.bit;
%     gui.imNr = 1;
% else
%     [input_name, input_path] = uigetfile('.mat','Choose input file.');
%     file = load([input_path filesep input_name]);
%     input = file.thumbs;
%     gui.thumbs = input.thumbs;
% 
%     gui.mini = input.mini;
%     gui.maxi = input.maxi;
%     gui.bit = input.bit;
%     gui.imNr = 1;
% end


% if gui.bit == 16 && max(cellfun(@(x)max(max(max(x))),gui.thumbs(1,:))) <= 4095
%     gui.maxi = 4095;
% end

%test_input
% score = cell(1,size(gui.thumbs,2));
% i = 1;
% 
% %create results file
% score_res = scoring_output(score, name);
% % score_res = scoring_output(score, name, id);
% save_res(score_res);

% %define colorbars
% gui.map_blue = zeros(64,3);gui.map_blue(:,3) = linspace(0,1,64);
% gui.map_red = zeros(64,3);gui.map_red(:,1) = linspace(0,1,64);
% gui.map_green = zeros(64,3);gui.map_green(:,2) = linspace(0,1,64);

%Menu
screensize = get( 0, 'Screensize' );
rel = (0.5*screensize(3))/(0.75*screensize(4));

%window
posx = 0.25; posy = 0.15; width = 0.5; height = 0.75;
gui_color = [0.82 0.82 0.82];
gui.fig_main = figure('Units','normalized','Position',[posx posy width height],'Name','ACCEPT - Automated CTC Classification Enumeration and PhenoTyping','MenuBar','none',...
    'NumberTitle','off','Color', [1 1 1],'Resize','off');

gui.process_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Process','Units','normalized','Position',[0.22 0.1 0.22 0.05],'FontUnits','normalized', 'FontSize',0.3,'Callback', @process); 
gui.visualize_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Visualize','Units','normalized','Position',[0.56 0.1 0.22 0.05],'FontUnits','normalized', 'FontSize',0.3,'Callback', @visualize);
gui.update_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Update sample list','Units','normalized','Position',[0.75 0.62 0.22 0.05],'FontUnits','normalized', 'FontSize',0.3,'Callback', @update);

gui.titel = uicontrol(gui.fig_main,'Style','text', 'String','ACCEPT','Units','normalized','Position',[0.41 0.83 0.18 0.04],'FontUnits','normalized', 'FontSize',1,'BackgroundColor',[1 1 1],'ForegroundColor',[0.729 0.161 0.208]);

gui.input_path = uicontrol(gui.fig_main,'Style','text', 'String','','Units','normalized','Position',[0.03 0.65 0.6 0.04],'FontUnits','normalized', 'FontSize',0.3);
gui.results_path = uicontrol(gui.fig_main,'Style','text', 'String','','Units','normalized','Position',[0.03 0.6 0.6 0.04],'FontUnits','normalized', 'FontSize',0.3);


gui.uni_logo_axes = axes('Units','normalized','Position',[0.57 0.025 0.4 0.4*uni_logo_rel*rel]);
gui.uni_logo = imagesc(uni_logo);  axis off;

gui.cancerid_logo_axes = axes('Units','normalized','Position',[0.66 0.83 0.3 0.3*cancerid_logo_rel*rel]); 
gui.cancerid_logo = imagesc(cancerid_logo); axis off;

gui.subtitle_axes = axes('Units','normalized','Position',[0.13 0.77 0.74 0.74*subtitle_rel*rel]);
gui.subtitle = imagesc(subtitle);  axis off;



% %specify toolbar
% gui.menu.menu_1  = uimenu(gui.fig_main,'Label','File');
% gui.menu.menu_1a = uimenu(gui.menu.menu_1,'Label','Open...','Accelerator','O','Callback',@load_file); 
% 
% gui.menu.menu_1  = uimenu(gui.fig_main,'Label','Help');
% gui.menu.menu_1a = uimenu(gui.menu.menu_1,'Label','Open Explanation...','Accelerator','E','Callback',@explanation); 
% 
% gui.framex = 0.2; gui.boundaryx = 0.005; gui.spacex = (1 - 2* gui.boundaryx - 4 * gui.framex)/5; 
% gui.framey = (width * gui.framex * screensize(3))/(height * screensize(4)); gui.boundaryy = 0.2; gui.spacey = (1 - gui.boundaryy - 2 * gui.framey)/3; 
% 
% %frames for each image plus axis with initial images
% gui.frame = uipanel('Units','normalized','Title','Overlay','FontSize',12,'Position',[(gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy) gui.framex gui.framey],'BackgroundColor',gui_color);
% gui.im1_ax = axes('Units','normalized','Position',[(gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy) gui.framex gui.framey]);
% if gui.bit == 8
%         gui.im1 = imagesc(flip(uint8(gui.thumbs{i}),3)); 
%     else
%         gui.im1 = imagesc(flip((single(gui.thumbs{i})/single(gui.maxi)),3)); 
% end
% set(gui.im1_ax,'visible','off'); freezeColors;
% 
% gui.frame = uipanel('Units','normalized','Title','DNA Marker','FontSize',12,'Position',[(gui.framex+2*gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy) gui.framex gui.framey],'BackgroundColor',gui_color);
% gui.im2_ax = axes('Units','normalized','Position',[(gui.framex+2*gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy) gui.framex gui.framey]);
% gui.im2 = imagesc(gui.thumbs{i}(:,:,1)); colormap(gui.im2_ax, gui.map_blue); set(gui.im2_ax,'visible','off','CLim',[gui.mini, gui.maxi]); freezeColors;
% 
% gui.frame = uipanel('Units','normalized','Title','Inclusion Marker','FontSize',12,'Position',[(2*gui.framex+3*gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy) gui.framex gui.framey],'BackgroundColor',gui_color);
% gui.im3_ax = axes('Units','normalized','Position',[(2*gui.framex+3*gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy) gui.framex gui.framey]);
% gui.im3 = imagesc(gui.thumbs{i}(:,:,2)); colormap(gui.im3_ax, gui.map_green); set(gui.im3_ax,'visible','off','CLim',[gui.mini, gui.maxi]); freezeColors;
% 
% gui.frame = uipanel('Units','normalized','Title','WBC Exclusion Marker','FontSize',12,'Position',[(3*gui.framex+4*gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy) gui.framex gui.framey],'BackgroundColor',gui_color);
% gui.im4_ax = axes('Units','normalized','Position',[(3*gui.framex+4*gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy) gui.framex gui.framey]);
% gui.im4 = imagesc(gui.thumbs{i}(:,:,3)); colormap(gui.im4_ax, gui.map_red); set(gui.im4_ax,'visible','off','CLim',[gui.mini, gui.maxi]); freezeColors;
% 
% gui.frame = uipanel('Units','normalized','Title','Overlay','FontSize',12,'Position',[(gui.spacex+gui.boundaryx) (gui.framey+2*gui.spacey+gui.boundaryy) gui.framex gui.framey],'BackgroundColor',gui_color);
% gui.im5_ax = axes('Units','normalized','Position',[(gui.spacex+gui.boundaryx) (gui.framey+2*gui.spacey+gui.boundaryy) gui.framex gui.framey]);
% if gui.bit == 8
%     gui.im5 = imagesc(flip(uint8((gui.thumbs{i}-repmat(min(min(gui.thumbs{i})),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1))*255./repmat(max(max(gui.thumbs{i}-repmat(min(min(gui.thumbs{i})),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1))),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1)),3));
% else
%     gui.im5 = imagesc(flip(single(gui.thumbs{i}-repmat(min(min(gui.thumbs{i})),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1))./single(repmat(max(max(gui.thumbs{i}-repmat(min(min(gui.thumbs{i})),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1))),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1)),3));
% end    
% set(gui.im5_ax,'visible','off'); freezeColors;
%  
% gui.frame = uipanel('Units','normalized','Title','DNA Marker','FontSize',12,'Position',[(gui.framex+2*gui.spacex+gui.boundaryx) (gui.framey+2*gui.spacey+gui.boundaryy) gui.framex gui.framey],'BackgroundColor',gui_color);
% gui.im6_ax = axes('Units','normalized','Position',[(gui.framex+2*gui.spacex+gui.boundaryx) (gui.framey+2*gui.spacey+gui.boundaryy) gui.framex gui.framey]);
% gui.im6 = imagesc(gui.thumbs{i}(:,:,1)); colormap(gui.im6_ax, gui.map_blue); set(gui.im6_ax,'visible','off','CLim',[min(min(gui.thumbs{i}(:,:,1))),max(max(gui.thumbs{i}(:,:,1)))]); freezeColors;
%  
% gui.frame = uipanel('Units','normalized','Title','Inclusion Marker','FontSize',12,'Position',[(2*gui.framex+3*gui.spacex+gui.boundaryx) (gui.framey+2*gui.spacey+gui.boundaryy) gui.framex gui.framey],'BackgroundColor',gui_color);
% gui.im7_ax = axes('Units','normalized','Position',[(2*gui.framex+3*gui.spacex+gui.boundaryx) (gui.framey+2*gui.spacey+gui.boundaryy) gui.framex gui.framey]);
% gui.im7 = imagesc(gui.thumbs{i}(:,:,2)); colormap(gui.im7_ax, gui.map_green); set(gui.im7_ax,'visible','off','CLim',[min(min(gui.thumbs{i}(:,:,2))),max(max(gui.thumbs{i}(:,:,2)))]); freezeColors;
% 
% gui.frame = uipanel('Units','normalized','Title','WBC Exclusion Marker','FontSize',12,'Position',[(3*gui.framex+4*gui.spacex+gui.boundaryx) (gui.framey+2*gui.spacey+gui.boundaryy) gui.framex gui.framey],'BackgroundColor',gui_color);
% gui.im8_ax = axes('Units','normalized','Position',[(3*gui.framex+4*gui.spacex+gui.boundaryx) (gui.framey+2*gui.spacey+gui.boundaryy) gui.framex gui.framey]);
% gui.im8 = imagesc(gui.thumbs{i}(:,:,3)); colormap(gui.im8_ax, gui.map_red); set(gui.im8_ax,'visible','off','CLim',[min(min(gui.thumbs{i}(:,:,3))),max(max(gui.thumbs{i}(:,:,3)))]); freezeColors;
% 
% gui.text_title = uicontrol('Units','normalized','Style','text','Position',[(gui.spacex+gui.boundaryx) (gui.framey+gui.spacey+gui.boundaryy) .2 .04],'String','Unscaled Images','HorizontalAlignment','left','FontSize',20,'BackgroundColor',gui_color,'FontWeight','bold');
% gui.text_title = uicontrol('Units','normalized','Style','text','Position',[(gui.spacex+gui.boundaryx) (2*gui.framey+2*gui.spacey+gui.boundaryy) .2 .04],'String','Scaled Image','HorizontalAlignment','left','FontSize',20,'BackgroundColor',gui_color,'FontWeight','bold');
% 
% gui.sld = uicontrol('Units','normalized','Style', 'slider','Min',1,'Max',size(gui.thumbs,2),'Value',1,'Position', [(gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy-0.05) (4*gui.framex+3*gui.spacex) .03],'Callback', @move_slider);
% set(gui.sld, 'SliderStep', [1, 1] / (size(gui.thumbs,2) - 1));
% 
% gui.thumbs_number_text  = uicontrol('Units','normalized','Style','text','Position',[0.2 (gui.spacey+gui.boundaryy-0.12) .2 .045],'String','Cell Number:','HorizontalAlignment','center','FontSize',25,'BackgroundColor',gui_color);
% gui.thumbs_number = uicontrol('Units','normalized','Style','edit','Position', [0.4 (gui.spacey+gui.boundaryy-0.12) .045 .045], 'String',num2str(gui.imNr),'Callback', @write_nr,'HorizontalAlignment','center','FontSize',25);
% 
% gui.score_text  = uicontrol('Units','normalized','Style','text','Position',[0.45 (gui.spacey+gui.boundaryy-0.12) .2 .045],'String','Cell Score:','HorizontalAlignment','center','FontSize',25,'BackgroundColor',gui_color);
% gui.score  = uicontrol('Units','normalized','Style','text','Position',[0.65 (gui.spacey+gui.boundaryy-0.12) .045 .045],'String','--','HorizontalAlignment','center','FontSize',25); 
% 
% 
% gui.waitbar_background = uicontrol('style','text', 'units','normalized', 'position',[(gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy-0.2) (4*gui.framex+3*gui.spacex) .03],'String', 'Progress Bar','HorizontalAlignment','center','FontSize',20, 'BackgroundColor','white','foregroundcolor',[.5 .5 .5]); 
% gui.waitbar = uicontrol('style','text', 'units','normalized', 'position',[(gui.spacex+gui.boundaryx) (gui.spacey+gui.boundaryy-0.2) 0.0001 .03], 'backgroundcolor',[.5 .5 .5], 'foregroundcolor','white'); 

end
function process(~,~)
    a = 5
end

function update(~,~)
end

function visualize(~,~)
end


