function log_entry(entry,saveToFile,display)
% General function to log events to a text file for easy debuging and
% bookkeeping. Can also display the entry if required.
 
global ACTC;

switch nargin 
    case 0
        error('actc:logEntry:TooManyInputs', ...
            'requires at most 3 optional inputs');
    case 1
        saveToFile=1;
        display=0;
    case 2
        display = 0;
        
end

entry = [datestr(now,13),': ',entry];

if saveToFile
    fid = fopen(fullfile(ACTC.Program.install_dir,ACTC.Program.logfile),'a');
    fprintf(fid,'%s\r\n', entry);
    fclose(fid);   
end

if display
    disp(entry)
end
