clear all; close all;
warning('off','all');

global gui name

% thumbs = find_thumbs;

% open start screen
logo = start_screen;
pause(1.5);
delete(logo);

%open explanation
explanation_window = explanation;
uiwait(explanation_window);

%ask for name and institute
name = inputdlg({'Name','Institute'},...
              'Please fill out your name and institute.', [1,75 ; 1,75],{'',''},'on');
          
while sum(cellfun(@(x)~isempty(x),name)) ~= 2
    waitfor(msgbox('Please fill out your institute and name', 'Error','error'));
    name = inputdlg({'Name','Institute'},...
              'Please fill out your name and institute.', [1,75 ; 1,75],{'',''},'on');
end

scoring_gui();

uiwait(gui.fig_main);
reminder = email_reminder;