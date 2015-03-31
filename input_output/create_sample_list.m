function sampleList=create_sample_list(ACTC);
%creates list from input dir. 
files = dir(ACTC.Program.inputDir);
if isempty(files)
    log_entry('inputDir is empty cannot continue',1,1);
    error('inputDir is empty cannot continue');
end

isdir = logical(cat(1,files.isdir));
sampleList = files(isdir); % select only directory entries from the current listing
end

