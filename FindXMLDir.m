function TiffDir_out = FindXMLDir(CartDir_in)
% function to verify in which directory the xml file is located. There
% are a few combinations present in the immc databases:
% immc38: dirs with e.g. .1.2 have a dir "processed" in cartridge dir, dirs
% without "." too "171651.1.2\processed\"
% immc26: dirs with name of cartridge, nothing else: "172182\mic06122006e7\"
% imcc26: dirs with e.g. .1.2: "173765.1.1\173765.1.1\processed\"

MinNumberOfXMLsNeeded = 1;
CurrentDir = CartDir_in;

% count iterations, if more than 10, return with error.
it = 0;

% if nothing is found, return error -1
TiffDir_out = 'No xml dir found';

while it < 10
    it = it + 1;
    if size(dir([CurrentDir filesep '*.xml']),1) == MinNumberOfXMLsNeeded
        TiffDir_out = CurrentDir;
        break
    else
        FilesDirs = dir(CurrentDir);
        if size(FilesDirs,1)> 2
            DirCount = 0;
            for ii = 1:size(FilesDirs,1)
                if FilesDirs(ii).isdir && ~strcmp(FilesDirs(ii).name, '.') && ~strcmp(FilesDirs(ii).name, '..') && ~strcmp(FilesDirs(ii).name, '.DS_Store')
                    DirCount = DirCount + 1;
                    NewDir = FilesDirs(ii).name;
                end
            end
            if DirCount == 1
                CurrentDir = [CurrentDir filesep NewDir];
            elseif DirCount == 0
                break
            else
                % if more than 1 directory is found, end search with error
                TiffDir_out = 'More than one dir found';
                break
            end
        end
    end
end
