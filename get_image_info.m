function dataP = get_image_info(dataP)
%function to fill the dataP.temp.imageinfos variable

for i=1:numel(dataP.temp.imageFileNames)
    dataP.temp.imageinfos{i}=imfinfo(dataP.temp.imageFileNames{i});
end

%check if image is CellTracks image
try tags=dataP.temp.imageinfos{1}(1).UnknownTags;
    for i=1:numel(tags)
        if tags(i).ID==754
            dataP.temp.imagesAreFromCT=true;
        end
    end
catch dataP.temp.imagesAreFromCT=false;
end

%Have to add a check for the 2^15 offset.
dataP.temp.imagesHaveOffset=false;