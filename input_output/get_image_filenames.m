function [dataP, Success_out] = get_image_filenames(dataP, input_cartridge)
% find tiff dir and place file names in dataP.temp Struct.

path_input_cartridge = fullfile(dataP.input_folder, input_cartridge);

tiff_dir  = FindTiffDir(path_input_cartridge);

if strcmp(tiff_dir, 'No Tiff dir found') || strcmp(tiff_dir, 'More than one dir found')
    Success_out = tiff_dir;
    return
else
    imageFileNames = dir([tiff_dir filesep '*.tif']);
    Success_out='tiff dir found';
end

for i=1:numel(imageFileNames)
 dataP.temp.imageFileNames{i} = [tiff_dir filesep imageFileNames(i).name];  
end