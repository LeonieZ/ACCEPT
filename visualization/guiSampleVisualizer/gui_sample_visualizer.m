function varargout = gui_sample_visualizer(varargin)
% GUI_SAMPLE_VISUALIZER MATLAB code for gui_sample_visualizer.fig
%      GUI_SAMPLE_VISUALIZER, by itself, creates a new GUI_SAMPLE_VISUALIZER or raises the existing
%      singleton*.
%
%      H = GUI_SAMPLE_VISUALIZER returns the handle to a new GUI_SAMPLE_VISUALIZER or the handle to
%      the existing singleton*.
%
%      GUI_SAMPLE_VISUALIZER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_SAMPLE_VISUALIZER.M with the given input arguments.
%
%      GUI_SAMPLE_VISUALIZER('Property','Value',...) creates a new GUI_SAMPLE_VISUALIZER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_sample_visualizer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_sample_visualizer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui_sample_visualizer

% Last Modified by GUIDE v2.5 01-Sep-2015 14:50:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_sample_visualizer_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_sample_visualizer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before gui_sample_visualizer is made visible.
function gui_sample_visualizer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui_sample_visualizer (see VARARGIN)

handles.base = varargin{1};
handles.currentSample = varargin{2};

% choose default command line output for gui
handles.output = hObject;

% create table with sample properties as overview
rnames = properties(handles.currentSample);
selectedProps = [1,2,3,5,6,8,9,10]; % properties of data sample to be visualized
rnames = rnames(selectedProps); % row titles
cnames = {}; % col titles
dat = cell(numel(rnames),1);
for i = 1:numel(rnames)
   dat{i} = eval(['handles.currentSample.',rnames{i}]); %getfield(handles.currentFrame,rnames{i});
end
tableDetails = uitable('Parent',handles.uipanelSample,'Units','normalized',...
            'Position',[0.03 0.07 0.2 0.85],'Data',dat,...
            'ColumnName',cnames,'RowName',rnames);
% tabExtend = get(tableDetails,'Extent')
% tabPosition = get(tableDetails,'Position');
% tabPosition(3:4) = tabExtend(3:4);
% set(tableDetails,'Position',tabPosition);

% create overview image per channel
axesOverview = axes('Parent',handles.uipanelSample,'Units','normalized',...
            'Position',[0.25 0.07 0.73 0.82]);
defCh = 2; % default channel for overview when starting the sample visualizer
handles.imageOverview = imagesc(handles.currentSample.overviewImage(:,:,defCh));
axis image; axis off;

% create choose button to switch color channel
popupChannel = uicontrol('Style','popup','Units','normalized',...
           'String',handles.currentSample.channelNames,...
           'Position',[0.4 -0.12 0.12 0.85],...
           'FontSize',15,...
           'Callback',@(hObject,eventdata)gui_sample_visualizer('popupChannel_Callback',hObject,eventdata,guidata(hObject)));
set(popupChannel,'Value',defCh);

% create scatter plot axes
uipScatter = handles.uipScatter;
axesScatter = axes('Parent',uipScatter,'Units','normalized',...
            'Position',[0.06 0.06 0.85 0.85]);
% create data for scatter plot
gca;
x = linspace(0,3*pi,200); y = cos(x) + rand(1,200); a = 25;
c = linspace(1,10,length(x));
scatter(x,y,a,c,'filled'); axis image; axis off;

% create axes for thumbnail gallery
axesGallery = axes('Parent',handles.uipGallery,'Units','normalized',...
            'Position',[0.06 0.06 0.85 0.85],'visible','off');

%====================================

% Create thumbnail gallery
    %maxNumFiles = 100;
    %maxNumCols  = 5;
    %set(handles.cancell,'value',0);

%     [files dirName] = uigetfile({'*.tiff ; *.tif ; *.jpg ; *.bmp'},'MultiSelect','on');
%     if ~dirName
%         return;
%     end
%     
%     if ~iscell(files)
%         temp = files;
%         files = cell(1);
%         files{1} = temp;
%     end
%     cd(dirName);
%     % save filenames in appdata of sampleVisualizer
%     setappdata(handles.sampleVisualizer,'files',files);
% 
%     N = size(files,2);
%     % Exception handling: too many dataframes loaded
%     if N > maxNumFiles
%         warndlg(['Maximum number of data frames is ' num2str(maxNumFiles) '!'],'To many data frames');
%         N = maxNumFiles;
%         files = files(1:N);
%     end
    
    nbrAvailableThumbnails = size(handles.currentSample.priorLocations,1)
    nbrVisualizedThumbnails = 5
    nbrChannels = 4; 
    N = nbrVisualizedThumbnails * (nbrChannels+1);
    
    maxNumCols  = 5; % design decision, % maxNumCols = 1 (overlay) + nbrChannels
    
    % create relative dimensions of the grid
    if N > maxNumCols^2
        cols = maxNumCols;
        rows = ceil(N/cols);
        ratio = rows/cols;
        height = ratio*0.95;
        pos = [0 -(height-0.95) 0.95 height];
        %set(handles.uipGallery,'position',pos);
        set(handles.slider1,'enable','on','value',1); % enable and upper position
    else
        cols = ceil( sqrt(N) );    % number of columns
        rows = cols - floor( (cols^2 - N)/cols );
        %set(handles.uipGallery,'position',[0 0 0.95 0.95]);
        set(handles.slider1,'enable','off');
    end
    
    setappdata(handles.sampleVisualizer,'cols',cols);
    
    % pitch (box for axis) height and width
    rPitch  = 0.98/rows;
    cPitch  = 0.98/cols;
    
    % axis height and width
    axHight = 0.9/rows;
    axWidth = 0.9/cols;
    
    % clear previous axes handles for the thumbnail gallery
    hAxes = getappdata(handles.sampleVisualizer,'hAxes');
    if ~isempty(hAxes)
        f = find ( ishandle(hAxes) & hAxes);
        delete(hAxes(f));
    end
    
    % define common properties and values for all axes
    axesProp = {'dataaspectratio' ,...
                                'Parent',...
                                'PlotBoxAspectRatio', ...
                                'xgrid' ,...
                                'ygrid'};
    axesVal = {[1,1,1] , ...
                            handles.uipGallery,...
                            [1 1 1]...
                            'off',...
                            'off'};
%     imageProp = { 'ButtonDownFcn'};
%     imageVal = { 'openSpecificImage( guidata(gcf) )'};
    hAxes = zeros(N,1);
    %ind = 1;
    hActions = getappdata(handles.sampleVisualizer,'actionItems');
    set(hActions,'enable','off');
    
    % Creating thumbnail axes at adequate positions
    
    % go through all thumbnails (resp. dataframes)
    for thumbInd=1:nbrVisualizedThumbnails
        % specify row location for all columns
        y = 0.98-thumbInd*rPitch;
        % obtain dataFrame from io
        dataFrame = handles.base.io.load_thumbnail_frame(handles.currentSample,thumbInd,'prior');
        % plot overlay image in first column
        x = 0;
        ind = (thumbInd-1)*nbrChannels + nbrChannels + 1; % index for first column element
        hAxes(ind) = axes('position',[x y axWidth axHight],axesProp,axesVal);
        plotImInAxis(dataFrame.rawImage,hAxes(ind));
        % plot image for each color channel in column 2 till nbrChannels
        for ch = 1:nbrChannels
            x = 0.98-(nbrChannels-ch+1)*cPitch;
            ind = (thumbInd-1)*nbrChannels + ch;
            hAxes(ind) = axes('position',[x y axWidth axHight],axesProp,axesVal);
            plotImInAxis(dataFrame.rawImage(:,:,ch),hAxes(ind));
        end
    end    
    set(hActions,'enable','on');
    setappdata(handles.sampleVisualizer,'hAxes',hAxes);

%=================================

% Choose default command line output for imageGallery
addpath(cd);
handles.output = hObject;

%setappdata(handles.sampleVisualizer,'actionItems',[handles.pushbuttonLoad]);
        
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gui_sample_visualizer wait for user response (see UIRESUME)
%uiwait(handles.sampleVisualizer);


% --- Outputs from this function are returned to the command line.
function varargout = gui_sample_visualizer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection in popupChannel.
function popupChannel_Callback(hObject, eventdata, handles)
selectedChannel = get(hObject,'Value');
set(handles.imageOverview,'CData',handles.currentSample.overviewImage(:,:,selectedChannel));

    
% --- Helper function used in thumbnail gallery to plot thumbnails in axes
function plotImInAxis(im,hAx)%,str,fontSize)
    imageProp = {'ButtonDownFcn'};
    imageVal = {'openSpecificImage( guidata(gcf) )'};
    if size(im,3) > 1
        % create overlay image here
        imagesc(sum(im,3),imageProp,imageVal,'parent',hAx);
    else
        imagesc(im,imageProp,imageVal,'parent',hAx);
    end
    axis(hAx,'image');
    axis(hAx,'off');
    colormap(gray);
    drawnow;    

   
% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider



% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
