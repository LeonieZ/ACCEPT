function varargout = imageGallery(varargin)
% IMAGEGALLERY M-file for imageGallery.fig
%      IMAGEGALLERY, by itself, creates a new IMAGEGALLERY or raises the existing
%      singleton*.
%
%      H = IMAGEGALLERY returns the handle to a new IMAGEGALLERY or the handle to
%      the existing singleton*.
% 
% 
% This GUI allows you to open several images and batch process all of them
% 

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imageGallery_OpeningFcn, ...
                   'gui_OutputFcn',  @imageGallery_OutputFcn, ...
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


% --- Executes just before imageGallery is made visible.
function imageGallery_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for imageGallery
addpath(cd);
handles.output = hObject;
setappdata(handles.figure1,'actionItems',[handles.imageSelection,handles.processImages,handles.reloadFromFiles]);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes imageGallery wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = imageGallery_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on button press in imageSelection.
function imageSelection_Callback(hObject, eventdata, handles)

    maxNumFiles = 100;
    maxNumCols = 4;
    set(handles.cancell,'value',0);

    [files dirName] = uigetfile({'*.tif ; *.jpg;*.bmp'},'MultiSelect','on');
    if ~dirName
        return;
    end
    
    if ~iscell(files)
        temp = files;
        files = cell(1);
        files{1} = temp;
    end
    cd(dirName);
    setappdata(handles.figure1,'files',files);

    N = size(files,2);
    if N > maxNumFiles
        warndlg(['Maximum number of files is ' num2str(maxNumFiles) '!'],'To many files');
        N = maxNumFiles;
        files = files(1:N);
    end
        
    if N > maxNumCols^2
        cols = maxNumCols;
        rows = ceil(N/cols);
        ratio = rows/cols;
        hight = ratio*0.95;
        pos = [0 -(hight-0.95) 0.95 hight];
        set(handles.uipanel1,'position',pos);
        set( handles.slider1,'enable','on','value',1);
    else
        cols = ceil( sqrt(N) );    %number of columns
        rows = cols - floor( (cols^2 - N)/cols );
        set( handles.slider1,'enable','off');
        set(handles.uipanel1,'position',[0 0 0.95 0.95]);
    end
    
    setappdata(handles.figure1,'cols',cols);
    
    rPitch = 0.98/rows;
    cPitch = 0.98/cols;
    axWidth = 0.9/(cols);
    axHight = 0.9/(rows);
    
    hAxes = getappdata(handles.figure1,'hAxes');
    if ~isempty(hAxes)
        f = find ( ishandle(hAxes) & hAxes);
        delete(hAxes(f));
    end
    
    axesProp = {'dataaspectratio' ,...
                                'Parent',...
                                'PlotBoxAspectRatio', ...
                                'xgrid' ,...
                                'ygrid'};
    axesVal = {[1,1,1] , ...
                            handles.uipanel1,...
                            [1 1 1]...
                            'off',...
                            'off'};
%     imageProp = { 'ButtonDownFcn'};
%     imageVal = { 'openSpecificImage( guidata(gcf) )'};
    hAxes = zeros(N,1);
    ind = 1;
    hActions = getappdata(handles.figure1,'actionItems');
    set(hActions,'enable','off');
    while ind<=N & ~get(handles.cancell,'value')
        [r c] = ind2sub([rows cols],ind);
        x = 0.98-(c)*cPitch;
        y = 0.98-(r)*rPitch;
        hAxes(ind) = axes( 'position', [x y axWidth axHight],axesProp,axesVal);
        im = imread( [dirName files{ind}] );

% Enable this line in case of large amount of data... 
% MAke sure to change the processing function to run on the image file and not on the data in the gui !!!
%         im = imresize(im,1/4);
        
        plotImInAxis(im,hAxes(ind),files{ind},11-cols)
        %pause(0.01);    %to allow the GUI response to "Cancell" button
        ind = ind+1;
    end 
    set(hActions,'enable','on');
    
    setappdata(handles.figure1,'hAxes',hAxes);
% hObject    handle to imageSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in processImages.
function processImages_Callback(hObject, eventdata, handles)
    
    set(handles.cancell,'value',0);
    hAxes = getappdata(handles.figure1,'hAxes');
    files = getappdata(handles.figure1,'files');

    cols = getappdata(handles.figure1,'cols');
    
    if isempty(hAxes) | isempty(files)
        return;
    end
    
    imageProp = { 'ButtonDownFcn'};
    imageVal = { 'openSpecificImage( guidata(gcf) )'};
    N = length(hAxes);
    ind = 1;
    hActions = getappdata(handles.figure1,'actionItems');
    set(hActions,'enable','off');
    while ind<=N & ~get(handles.cancell,'value')        
        if (ishandle(hAxes(ind) ) & hAxes(ind))
            hIm = findobj( hAxes(ind),'type','image');
            
            % in case images where downsamples (resized) use this line to
            % load the image (it will reread it from the file)
%             im = imread(files{ind});  Reading image from the file (good for large images)           
            im = getimage( hIm );
            try
                % change this function to you'r own processing function !!
                [im score] = processIm(im);
            catch
                disp('The follwing error occur while trying to process the images (halting execution):');
                disp(lasterr);
                break;
            end
            
            str = ['Score: ' num2str(score) '   ' files{ind}];
            plotImInAxis(im,hAxes(ind),str,11-cols)
            pause(0.01);
        end
        ind = ind+1;
    end 
    set(hActions,'enable','on');
% hObject    handle to processImages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in closeAll.
function closeAll_Callback(hObject, eventdata, handles)
%     imtool close all
    h = findobj(0,'type','figure');
    f = find (h ~=handles.figure1);
    close(h(f));
% hObject    handle to closeAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in reloadFromFiles.
function reloadFromFiles_Callback(hObject, eventdata, handles)
    set(handles.cancell,'value',0);
    hAxes = getappdata(handles.figure1,'hAxes');
    files = getappdata(handles.figure1,'files');
    
    if isempty(hAxes) | isempty(files)
        return;
    end
    
    cols = getappdata(handles.figure1,'cols');
   
    imageProp = { 'ButtonDownFcn'};
    imageVal = { 'openSpecificImage( guidata(gcf) )'};
    N = length(hAxes);
    ind = 1;
    hActions = getappdata(handles.figure1,'actionItems');
    set(hActions,'enable','off');
    while ind<=N & ~get(handles.cancell,'value')
        if (ishandle(hAxes(ind) ) & hAxes(ind))
            im = imread( files{ind} );
%             im = imresize(im,1/4);            

            plotImInAxis(im,hAxes(ind),files{ind},11-cols);
            pause(0.01);
        end
            ind = ind+1;
    end 
    set(hActions,'enable','on');

% hObject    handle to reloadFromFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in cancell.
function cancell_Callback(hObject, eventdata, handles)
% hObject    handle to cancell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cancell




% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
    pos = get(handles.uipanel1,'position');
    hight = pos(4);
    if hight > 1
        val = get(hObject,'value');
        yPos = -val * (hight-0.95);
        pos(2) = yPos;
        set(handles.uipanel1,'position',pos);
    end
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

% Hint: slider controls usually have a light gray background, change
%       'usewhitebg' to 0 to use default.  See ISPC and COMPUTER.
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function plotImInAxis(im,hAx,str,fontSize)
    imageProp = { 'ButtonDownFcn'};
    imageVal = { 'openSpecificImage( guidata(gcf) )'};
    
    imagesc(im, imageProp,imageVal,'parent',hAx );
    axis(hAx,'image');
    axis(hAx,'off');    
    str = strrep( str,'_',' ');
    title( hAx,str,'fontsize',fontSize);
    drawnow;