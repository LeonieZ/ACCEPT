close all;
clear all;

%%% open new Icy session?
% eval('!open /Applications/icy/icy.app');
% pause(6);


%Data specifications
dataP = get_data_parameter;

%Algorithm specifications
algP = get_alg_parameter;

tic;

if algP.save_result == true
    CTC_detection(dataP, algP);
else
    [res, stat, dataP, algP] = CTC_detection(dataP, algP); 
end

toc;