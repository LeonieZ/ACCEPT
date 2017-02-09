function gui = gui_main(base,installDir)

% global gui

set(0,'units','characters');  
screensz = get(0,'screensize');

% Update chooseButton for tasks via available sampleProcessors
gui.tasks_raw = cellfun(@(s) s.name,base.availableSampleProcessors,'UniformOutput',false);

% select DEFAULT sampleProcessor number (in alphabetical order) for visualization
defaultSampleProcessorNumber = 1;

if(exist([installDir,filesep,'input_output',filesep,'LatestSettings.mat'], 'file') == 2)
   load([installDir,filesep,'input_output',filesep,'LatestSettings.mat'],'inputPath','resultPath','processor')
   proc = find(cellfun(@(s) strcmp(processor, s.name), base.availableSampleProcessors));
   if ~isempty(proc)
       currentProcessorIndex = proc;
       base.sampleProcessor = base.availableSampleProcessors{proc};
       base.sampleList.sampleProcessorId = base.sampleProcessor.id();
   else
       currentProcessorIndex = defaultSampleProcessorNumber;
       base.sampleProcessor = base.availableSampleProcessors{defaultSampleProcessorNumber};
       base.sampleList.sampleProcessorId=base.sampleProcessor.id();    
   end
   if exist(inputPath, 'dir')
        base.sampleList.inputPath = inputPath;
   end
   if exist(resultPath, 'dir')
        base.sampleList.resultPath = resultPath;
   end
else
    currentProcessorIndex = defaultSampleProcessorNumber;
    base.sampleProcessor = base.availableSampleProcessors{defaultSampleProcessorNumber};
    base.sampleList.sampleProcessorId=base.sampleProcessor.id();
end


uni_logo = imread('logoUT.png'); 
cancerid_logo = imread('logoCancerID.png');

gui.fig_main = figure('Units','characters','Position',[(screensz(3)-160)/2 12 160 60],'Name','ACCEPT - Automated CTC Classification Enumeration and PhenoTyping','MenuBar','none',...
    'NumberTitle','off','Color', [1 1 1],'Resize','off','Visible','off','CloseRequestFcn',@close_fcn);

gui.process_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Process','Units','characters','Position',[35 6 35 3],'FontUnits','normalized', 'FontSize',0.5,'Callback', {@process,base}); 
gui.visualize_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Visualize','Units','characters','Position',[90 6 35 3],'FontUnits','normalized', 'FontSize',0.5,'Callback', {@visualize,base});
gui.gate_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Gate','Units','characters','Position',[110 14 15 3],'FontUnits','normalized', 'FontSize',0.4,'Callback', {@gate,base});
gui.export_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Summary','Units','characters','Position',[110 10.8 15 3],'FontUnits','normalized', 'FontSize',0.4,'Callback', {@export_summary,base});
gui.title_axes = axes('Parent',gui.fig_main,'Units','characters','Position',[80 50 29 3]); axis off;
gui.title = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} ACCEPT','Units','characters','FontUnits','normalized', 'FontSize',1,'verticalAlignment','base','horizontalAlignment','center','FontWeight','bold');

gui.subtitle_axes = axes('Parent',gui.fig_main,'Units','characters','Position',[80 46 136 2]);axis off;
gui.subtitle = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208}A\color[rgb]{0,0,0}utom\color[rgb]{0,0,0}ated \color[rgb]{0.729,0.161,0.208}C\color[rgb]{0,0,0}TC \color[rgb]{0.729,0.161,0.208}C\color[rgb]{0,0,0}lassification \color[rgb]{0.729,0.161,0.208}E\color[rgb]{0,0,0}numeration and \color[rgb]{0.729,0.161,0.208}P\color[rgb]{0,0,0}heno\color[rgb]{0.729,0.161,0.208}T\color[rgb]{0,0,0}yping',...
    'Units','characters','FontUnits','normalized','FontSize',1,'verticalAlignment','base','horizontalAlignment','center','FontWeight','bold');
sz = get(gui.subtitle,'Extent');
while sz(3) > 135
    fsize = get(gui.subtitle,'FontSize');
    set(gui.subtitle,'FontSize',fsize - 0.05);
    sz = get(gui.subtitle,'Extent');
end
set(gui.subtitle,'Visible','on');

gui.task = uicontrol(gui.fig_main,'Style','text', 'String','Choose a task:','Units','characters','Position',[30 40.7 35 2],'FontUnits','normalized', 'FontSize',1,'BackgroundColor',[1 1 1]);
gui.task_list = uicontrol(gui.fig_main,'Style', 'popup','String', gui.tasks_raw,'Units','characters','Position', [67 41.4 62 1.2],'Callback', {@choosetask,base}, 'FontUnits','normalized', 'FontSize',0.9);  
set(gui.task_list,'Value',currentProcessorIndex);
sz = get(gui.task,'Extent');
curpos = get(gui.task,'Position'); 
if curpos(3) < sz(3)
    set(gui.task,'Position',[(160 - (65 + sz(3)))/2 curpos(2) sz(3) curpos(4)]); 
    set (gui.task_list,'Position',[(160 - 59 + sz(3))/2 41.4 62 1.2]);
end
sz = get(gui.task,'Extent');
while sz(4) > curpos(4)
    fsize = get(gui.task,'FontSize');
    set(gui.task,'FontSize',fsize - 0.01);
    sz = get(gui.task,'Extent');
end

gui.input_path_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Select input folder','Units','characters','Position',[23.3 35.8 32 2.3],'FontUnits','normalized', 'FontSize',0.5,'Callback', {@input_path,base});
gui.input_path_frame = uipanel('Parent',gui.fig_main, 'Units','characters','Position',[55.7 35.8 81 2.3]);
gui.input_path = uicontrol(gui.fig_main,'Style','text', 'String',base.sampleList.inputPath,'Units','characters','Position',[56.2 36.3 80 1.3],'FontUnits','normalized', 'FontSize',.7);

gui.results_path_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Select results folder','Units','characters','Position',[23.3 32.2 32 2.3],'FontUnits','normalized', 'FontSize',0.5,'Callback', {@results_path,base});
gui.results_path_frame = uipanel('Parent',gui.fig_main, 'Units','characters','Position',[55.7 32.2 81 2.3]);
gui.results_path = uicontrol(gui.fig_main,'Style','text', 'String',base.sampleList.resultPath,'Units','characters','Position',[56.2 32.7 80 1.3],'FontUnits','normalized', 'FontSize',.7);

sz_inButton = get(gui.input_path_button,'Extent'); sz_resButton = get(gui.results_path_button,'Extent');
if sz_inButton(3) > 32 || sz_resButton(3) > 32
    new_sz = max(sz_inButton(3),sz_resButton(3)) + 2;
    set(gui.input_path_button,'Position',[67.2-new_sz  35.8 new_sz 2.3]);
    set(gui.results_path_button,'Position',[67.2-new_sz 32.2 new_sz 2.3]);
end

gui.uni_logo_axes = axes('Units','characters','Position',[91.2 1.5 64 3]);
gui.uni_logo = imagesc(uni_logo); axis image; axis off;

gui.cancerid_logo_axes = axes('Units','characters','Position',[107.2 49.8 48 9.5]); 
gui.cancerid_logo = imagesc(cancerid_logo); axis image; axis off;

% calculate conversion factor pixels to characters
figure('Visible','off');
size_pixels=get(gcf,'Position');
set(gcf,'Units','characters');
size_characters=get(gcf,'Position');
f=size_pixels(3:4)./size_characters(3:4);
%%% 

gui.table = uitable('Parent', gui.fig_main, 'Data', [],'ColumnName', {'Sample name','Select'},'ColumnFormat', {'char','logical'},'ColumnEditable', [false,true],'RowName',[],'Units','characters',...
    'Position',[54.4 10.8 51.2 19.6],'ColumnWidth',{0.695*51.2*f(1) 0.295*51.2*f(1)}, 'FontUnits','normalized', 'FontSize',0.05,'CellEditCallback',@(src,evnt)EditTable(src,evnt));
gui.slider = uicontrol('Style','Slider','Parent',gui.fig_main,'Units','characters','Position',[105.6 10.8 3.2 19.6],'Min',-1,'Max',0,'Value',0,...
    'SliderStep', [1, 1] ,'Visible','on','Enable','off','Callback',{@update_table,base});
set(gui.fig_main,'Visible','on');
update_list(base);



function process(handle,~,base)
    display('Process samples...')
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5],'string','Process samples...');
    drawnow;

    sliderpos = -round(get(gui.slider,'Value'));
    selectedCellsInTable = find(gui.selectedCells);
    
    wbHandle = waitbar(0,'Please wait until samples are processed');
    el=event.listener(base,'updateProgress',@(src,event)update_wb(src,event,base,wbHandle));

    if isa(base.sampleProcessor,'Candidate_Selection') && isempty(base.sampleProcessor.pipeline{4}.gates)
        gui_gates = gui_manual_gates();
        waitfor(gui_gates.fig_main,'UserData')
        res = get(gui_gates.fig_main,'UserData');
        base.sampleProcessor.pipeline{4}.gates = res.gates;
        base.sampleProcessor.pipeline{4}.name = res.name;
        delete(gui_gates.fig_main)
        clear('gui_gates');
    end
    
    if size(selectedCellsInTable,1) == 0
        if sum(~base.sampleList.isProcessed) > 0
            if and(~isempty(base.sampleList.inputPath),~isempty(base.sampleList.resultPath))
                base.sampleList.toBeProcessed = ~base.sampleList.isProcessed;
                gui.selectedCells = base.sampleList.toBeProcessed;
                dat = get(gui.table,'data');
                for r=1:size(dat,1)
                    dat{r,2} = gui.selectedCells(sliderpos+r);     
                end 
                set(gui.table,'data',dat);
                base.run();
            else
                msgbox('no dirs selected');
            end
        else
            set(0,'defaultUicontrolFontSize', 14)
            choice = questdlg('All samples are processed. Do you want to process them again?', ...
                                'Processed Sample', 'Yes','No','No');
            set(0,'defaultUicontrolFontSize', 12)
            switch choice
                case 'Yes'
                    base.sampleList.toBeProcessed = base.sampleList.isProcessed;
                    gui.selectedCells = base.sampleList.toBeProcessed;
                    dat = get(gui.table,'data');
                    for r=1:size(dat,1)
                        dat{r,2} = gui.selectedCells(sliderpos+r);     
                    end 
                    set(gui.table,'data',dat);
                    base.run();
                case 'No'
            end
        end
    else
        if and(~isempty(base.sampleList.inputPath),~isempty(base.sampleList.resultPath))
            % clear current sampleList:
            base.sampleList.toBeProcessed = zeros(size(base.sampleList.toBeProcessed));
            % update the current sampleList: selected samples should be processed
            base.sampleList.toBeProcessed(selectedCellsInTable(:,1)) = 1;
            
            base.run();
        else
            msgbox('No directories selected.');
        end
    end
    %     gui.selectedCells = false(size(base.sampleList.sampleNames,2),1);
    set(handle,'backg',color,'String','Process');
    close(wbHandle)
    %delete(el)
    update_list(base);   
end

function visualize(handle,~,base)
%     global gui
    display('Visualize samples...')
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5],'string','Starting GUI')
    drawnow;
    selectedCellsInTable = find(gui.selectedCells);
    if size(selectedCellsInTable,1) == 0
        msgbox('No sample selected.');
    elseif size(selectedCellsInTable,1) == 1
        if and(~isempty(base.sampleList.inputPath),~isempty(base.sampleList.resultPath))
            % load selected sample
%             currentSample = IO.load_sample(base.sampleList,selectedCellsInTable(1),0);
            currentSample = IO.load_sample(base.sampleList,selectedCellsInTable(1));
            if ~isempty(currentSample.results.segmentation)
                IO.save_sample(currentSample);
                currentSample = IO.load_sample(base.sampleList,selectedCellsInTable(1));
            end
            if size(currentSample.results.thumbnails,1)<1 || isempty(currentSample.results.features)
               msgbox('Empty Sample.')
            else
               % run sampleVisGui with loaded sample
               GuiSample = gui_sample(base,currentSample);
%                CS_scoring_gui(base,currentSample);
            end  
        else
            msgbox('No directories selected.')
        end
    else
        msgbox('Too many samples selected for visualization.');
    end
%     base.sampleList.toBeProcessed = ~base.sampleList.isProcessed;
    gui.selectedCells = false(size(base.sampleList.sampleNames,2),1);
    dat = get(gui.table,'data');
    for r=1:size(dat,1)
        dat{r,2} = 0;     
    end
    set(gui.table,'data',dat);
    set(handle,'backg',color,'String','Visualize')
end

function gate(handle,~,base)
color = get(handle,'backg');
set(handle,'backgroundcolor',[1 .5 .5])
drawnow;



pos_button = get(gui.gate_button,'Position');
pos_main = get(gui.fig_main,'Position');
d = dialog('Units','characters','Position',[pos_main(1)+pos_button(1) pos_main(2)+pos_button(2)+pos_button(4)+0.5 60 5],'Name','Multiple Gates');
uicontrol('Parent',d,'Units','characters','Position',[4 1 25 3],'FontUnits','normalized','FontSize',0.3,'String','Specify Gates.','Callback',@btn1_callback);
uicontrol('Parent',d,'Units','characters','Position',[31 1 25 3],'FontUnits','normalized','FontSize',0.3,'String','Load Existing Gates.','Callback',@btn2_callback);
savedGate = 2;
waitfor(d);
function btn1_callback(~,~)
    savedGate = 0;
    delete(gcf)
end
function btn2_callback(~,~)
    savedGate = 1;
    delete(gcf)
end

if savedGate == 0 || savedGate == 1
    rug = Rescore_Using_Gate();
    rug.previousProcessor = base.sampleProcessor;
    rug.set_gates(savedGate); 

    if ~isempty(rug.gate)
        selectedCellsInTable = find(gui.selectedCells);
        if and(~isempty(base.sampleList.inputPath),~isempty(base.sampleList.resultPath))
            if size(selectedCellsInTable,1) == 0
                base.sampleList.toBeProcessed = ones(size(base.sampleList.toBeProcessed));
            else
                % clear current sampleList:
                base.sampleList.toBeProcessed = zeros(size(base.sampleList.toBeProcessed));
                % update the current sampleList: selected samples should be processed
                base.sampleList.toBeProcessed(selectedCellsInTable(:,1)) = 1;
            end
        end
        base.sampleProcessor = rug;
        base.run;

        base.sampleProcessor = rug.previousProcessor;
        update_list(base)
    end
    
end
set(handle,'backg',color)
end

function export_summary(handle,~,base)
color = get(handle,'backg');
set(handle,'backgroundcolor',[1 .5 .5])
drawnow;


pos_button = get(gui.export_button,'Position');
pos_main = get(gui.fig_main,'Position');
d = dialog('Units','characters','Position',[pos_main(1)+pos_button(1) pos_main(2)+pos_button(2)+pos_button(4)+0.5 60 5],'Name','Export Summary Table');
uicontrol('Parent',d,'Units','characters','Position',[4 1 25 3],'FontUnits','normalized','FontSize',0.25,'String','All Samples.','Callback',@exp2_callback);
uicontrol('Parent',d,'Units','characters','Position',[31 1 25 3],'FontUnits','normalized','FontSize',0.25,'String','Only Selected Samples.','Callback',@exp1_callback);
allSamples = 2;
waitfor(d);
function exp1_callback(~,~)
    allSamples = 0;
    delete(gcf)
end
function exp2_callback(~,~)
    allSamples = 1;
    delete(gcf)
end

if allSamples == 0 || allSamples == 1
    [file,path] = uiputfile([base.sampleList.resultPath filesep base.sampleList.sampleProcessorId filesep 'summaryTable.xlsx'],'Save summary file.');
    if ischar(file)
        if allSamples == 1
            selectedCellsInTable = linspace(1,size(base.sampleList.sampleNames,2),size(base.sampleList.sampleNames,2));
        elseif allSamples == 0
            selectedCellsInTable = find(gui.selectedCells);
        end        
        t = IO.export_samplelist_results_summary(base.sampleList, selectedCellsInTable,[path,file]); 
        if isempty(t)
                msgbox('Empty summary. No file saved.');
        end
        gui.selectedCells = false(size(base.sampleList.sampleNames,2),1);
        dat = get(gui.table,'data');
        for r=1:size(dat,1)
            dat{r,2} = 0;     
        end
        set(gui.table,'data',dat);
    end
end

set(handle,'backg',color)
end

function input_path(~,~,base)
%     global gui
    inputPath = uigetdir(pwd,'Please select an input folder.');
    if inputPath ~= 0
        set(gui.input_path,'String',inputPath);
        base.sampleList.inputPath=inputPath;
        update_list(base);
    end
end

function results_path(~,~,base)
%     global gui
    resultPath = uigetdir(pwd,'Please select a results folder.');
    if resultPath ~= 0
        test=strfind(resultPath,get(gui.input_path,'String'));
        if isempty(test)
            set(gui.results_path,'String',resultPath);
        else
            msgbox('The results folder cannot be located inside of the image folder')
        end
        base.sampleList.resultPath=resultPath;
        update_list(base);
    end
end

function choosetask(source,~,base)
%     global gui
    val = get(source,'Value');        
    set(gui.task_list,'Value',val);
    % create sampleProcessor object for selected sampleProcessor 
    base.sampleProcessor = base.availableSampleProcessors{val};
    base.sampleList.sampleProcessorId=base.sampleProcessor.id();
    update_list(base);
end

function EditTable(source, eventdata)
sliderpos = -round(get(gui.slider,'Value'));
data=get(source,'Data'); % get the data cell array of the table
cols=get(source,'ColumnFormat'); % get the column formats
if ~isempty(eventdata.Indices) && strcmp(cols(eventdata.Indices(2)),'logical') % if the column of the edited cell is logical
    data{eventdata.Indices(1),eventdata.Indices(2)}=eventdata.EditData;
    gui.selectedCells(eventdata.Indices(1)+sliderpos) = eventdata.EditData;% set the data value to true 
end
set(source,'data',data); % resets the vertical scroll to the top of the table
end

function update_list(base)
%     global gui
    % update inputPath if none is selected. 
    nbrRows = 15;
    if or(isempty(base.sampleList.inputPath),isempty(base.sampleList.resultPath))
        dat{1,1}='Please select an';
        dat{2,1}='input and output folder.';
        set(gui.table,'data', dat,'Visible','off');
        size_nd = get(gui.table,'Extent');
        pos_cur = get(gui.table,'Position');
        if size_nd(3) > pos_cur(3)
            set(gui.table, 'Position',[(160 - size_nd(3))/2, pos_cur(2), size_nd(3), pos_cur(4)]);
            set(gui.gate_button,'Position',[(160 + size_nd(3))/2+4.4, pos_cur(2), 15, 3]);
            set(gui.export_button,'Position',[(160 + size_nd(3))/2+4.4, pos_cur(2)+3.2, 15, 3]);
        end
        set(gui.table,'Visible','on');
    else
        sliderpos = -round(get(gui.slider,'Value'));
        sl = base.sampleList;
        base.sampleList.update_sample_list();
        nbrSamples = size(sl.sampleNames,2);
        gui.selectedCells = false(nbrSamples,1);
        nbrAttributes = 2;
        dat = cell(min(nbrSamples,nbrRows),nbrAttributes);
        if nbrSamples - sliderpos > 0
            nrField = min([nbrSamples,nbrRows,nbrSamples - sliderpos]);
        else
            nrField = min([nbrSamples,nbrRows]);
            sliderpos = 0;
            set(gui.slider,'Value',sliderpos);
        end
        for r=1:nrField
            dat{r,1} = sl.sampleNames{1,r+sliderpos};
            if sl.isProcessed(1,r+sliderpos) == 0
                dat(r,1) = cellfun(@(x) ['<html><table border=0 width=400 bgcolor=#FF9999><TR><TD>' x '</TD></TR> </table></html>'], dat(r,1), 'UniformOutput', false);
            else 
                dat(r,1) = cellfun(@(x) ['<html><table border=0 width=400 bgcolor=#99FF99><TR><TD>' x '</TD></TR> </table></html>'], dat(r,1), 'UniformOutput', false);
            end
%             dat{r,2} = sl.isProcessed(1,r);
        dat{r,2} = false;
        end
        set(gui.table,'data', dat,'Visible','off');
        pos_cur = get(gui.table,'Position');
        size_nd = get(gui.table,'Extent');
        if size_nd(4) > pos_cur(4)
            while size_nd(4) > pos_cur(4)
                dat(end,:) = [];
                nbrRows = size(dat,1);
                set(gui.table,'data', dat);
                size_nd = get(gui.table,'Extent');
            end
            set(gui.table, 'Position',[(160 - size_nd(3))/2, 9 + (23.2 - size_nd(4))/2, size_nd(3), size_nd(4)]);  
            set(gui.table,'FontSize',get(gui.table,'FontSize')*pos_cur(4)/size_nd(4));
            slider_pos = get(gui.slider,'Position');
            set(gui.slider,'Position',[(160 + size_nd(3))/2, 9 + (23.2 - size_nd(4))/2, slider_pos(3), size_nd(4)]);
            slider_pos = get(gui.slider,'Position');
            set(gui.gate_button,'Position',[slider_pos(1)+slider_pos(3)+1.2, slider_pos(2), 15, 3]);
            set(gui.export_button,'Position',[slider_pos(1)+slider_pos(3)+1.2, slider_pos(2)+3.2, 15, 3]);
        end
        if nbrSamples > nbrRows
            set(gui.slider, 'Min',-nbrSamples+nbrRows,'Max',0,'Value',-sliderpos,'SliderStep', [1, 1]/(nbrSamples-nbrRows), 'Enable','on');
        else
            set(gui.slider,'Min',-1,'Max',0,'Value',0,'SliderStep', [1, 1] ,'Enable','off');
        end
        set(gui.table,'Visible','on');
    end
end

function update_table(handle,~,base)
% update uitable
val = -round(get(handle,'Value'));
sl = base.sampleList;
nbrRows = size(get(gui.table,'Data'),1);
nbrSamples = size(sl.sampleNames,2);
nbrAttributes = 2;
dat = cell(min(nbrSamples,nbrRows),nbrAttributes);
for r=1:min(nbrSamples,nbrRows)
    dat{r,1} = sl.sampleNames{1,r+val};
    if sl.isProcessed(1,r+val) == 0
        dat(r,1) = cellfun(@(x) ['<html><table border=0 width=400 bgcolor=#FF9999><TR><TD>' x '</TD></TR> </table></html>'], dat(r,1), 'UniformOutput', false);
    else 
        dat(r,1) = cellfun(@(x) ['<html><table border=0 width=400 bgcolor=#99FF99><TR><TD>' x '</TD></TR> </table></html>'], dat(r,1), 'UniformOutput', false);
    end
    dat{r,2} = gui.selectedCells(r+val);
end
set(gui.table,'data', dat);
end

function close_fcn(~,~) 
%     fid=fopen([installDir,filesep,'input_output',filesep,'LatestSettings.txt'],'w');
    base.save_state;
    delete(gcf)
end

function update_wb(~,~,base,wbHandle)
    waitbar(base.progress,wbHandle);
end


end

