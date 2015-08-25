function varargout = gui(varargin)
% gui MATLAB code for gui.fig
%      gui, by itself, creates a new gui or raises the existing
%      singleton*.
%
%      H = gui returns the handle to a new gui or the handle to
%      the existing singleton*.
%
%      gui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in gui.M with the given input arguments.
%
%      gui('Property','Value',...) creates a new gui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui

% Last Modified by GUIDE v2.5 25-Aug-2015 17:50:27

%-------------------------------------------------------------------------

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
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

%-------------------------------------------------------------------------

% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui (see VARARGIN)

handles.base = varargin{1};

% Choose default command line output for gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in chooseTask.
function chooseTask_Callback(hObject, eventdata, handles)
% hObject    handle to chooseTask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = cellstr(get(hObject,'String')); %returns chooseTask contents as cell array
contents{get(hObject,'Value')} %returns selected item from chooseTask


% --- Executes during object creation, after setting all properties.
function chooseTask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chooseTask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% initialize choose button for tasks
tasks = {'Feature Collection';};
set(hObject,'String',tasks);


% --- Executes on button press in processButton.
function processButton_Callback(hObject, eventdata, handles)
% hObject    handle to processButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
display('Process samples')


% --- Executes on button press in visualizeButton.
function visualizeButton_Callback(hObject, eventdata, handles)
% hObject    handle to visualizeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
display('Visualize samples')


% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
display('Load samples...')
inputPath = '/Users/brunec/git/ACTC/examples/test_images';
resultPath = '/Users/brunec/git/ACTC/examples/results';
handles.base.sampleProcessor = SampleProcessor();
handles.base.sampleList = handles.base.io.create_sample_list(...
                        inputPath,resultPath,handles.base.sampleProcessor);
sl = handles.base.sampleList;
nbrSamples = size(sl.sampleNames,2);
nbrAttributes = 4;
dat = cell(nbrSamples,nbrAttributes);
for r=1:nbrSamples
    dat{r,1} = sl.sampleNames{1,r};
    dat{r,2} = sl.sampleProcessorId;
    dat{r,3} = sl.isProcessed(1,r);
    dat{r,4} = sl.isToBeProcessed(1,r);    
end                    
cnames = {'   Sample Name   ','   Sample Processor   ','   is processed   ','   to be processed'   };
rnames = {};
% create details table
tableSamples = uitable('Parent',handles.uipanelSampleList,'Units','normalized',...
            'Data',dat,'ColumnName',cnames,'RowName',rnames,'ColumnWidth',{135},'Position',[0 0 1 1],...
            'CellSelectionCallback',@(src,evnt)set(src,'UserData',evnt.Indices));
%get(tableSamples,'UserData')
