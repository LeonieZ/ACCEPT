function [sampleList, saveList]=create_sample_list(ACTC)
%creates list of samples from input dir. It also checks if these samples are already processed in the output dir.
files = dir(ACTC.Program.inputFolder);
if isempty(files)
    log_entry('inputDir is empty cannot continue',1,1);
    error('inputDir is empty cannot continue');
end

% select only directory entries from the input listing and remove
% anything that starts with a .*.
inputList = files([files.isdir] & ~strncmpi('.', {files.name}, 1)); 

%Check in results dir if any samples are already done.
try load([ACTC.Program.outputFolder filesep processed.mat],samplesProccesed)
catch 
    %appears to be no lest so lets create a empty sampleProccesed variable
    sampleProccessed=['empty'];
end
sampleList=setdiff({inputList.name},sampleProccessed);
saveList=strcat(ACTC.Program.outputFolder,filesep,sampleList,'.mat');
end





