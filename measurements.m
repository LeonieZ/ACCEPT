function [Msr, Thumbs] = measurements(seg_image, scaled_image, image_number, dataP, algP);
    
Thumbs = [];
Msr = table();
channelsToThreshold=unique(dataP.maskForChannel);


%%%%%%%%%%%%% test %%%%%%%%%%%%%
% Look for connecting components in 3d. Make sure that mask layers touch eachother 
if (sum(ismember(dataP.channelNames(channelsToThreshold),'DAPI') + ismember(dataP.channelNames(channelsToThreshold),'PE')+ismember(dataP.channelNames(channelsToThreshold),'APC')) == 3)
    seg_image_permut = zeros(size(seg_image));
    seg_image_permut(:,:,1) = seg_image(:,:,find(ismember(dataP.channelNames,'PE')));
    seg_image_permut(:,:,2) = seg_image(:,:,find(ismember(dataP.channelNames,'DAPI')));
    seg_image_permut(:,:,3) = seg_image(:,:,find(ismember(dataP.channelNames,'APC')));
    others = find(ones(1,dataP.numChannels) - ismember(dataP.channelNames,'PE') - ismember(dataP.channelNames,'DAPI') - ismember(dataP.channelNames,'APC'));
    for i = 1:numel(others)
        seg_image_permut(:,:,3+i) = seg_image(:,:,others(i));
    end
    CC = bwconncomp(seg_image_permut,6);
    Mask_permut = labelmatrix(CC);
    Mask(:,:,find(ismember(dataP.channelNames,'PE'))) = Mask_permut(:,:,1);
    Mask(:,:,find(ismember(dataP.channelNames,'DAPI'))) = Mask_permut(:,:,2);
    Mask(:,:,find(ismember(dataP.channelNames,'APC'))) = Mask_permut(:,:,3);
    for i = 1:numel(others)
        Mask(:,:,others(i)) = Mask_permut(:,:,3+i);
    end
    
else
    CC = bwconncomp(seg_image,6);
    Mask = labelmatrix(CC);
end
    

%P2A missing!
if CC.NumObjects > 0
    for ch=1:dataP.numChannels
        MsrTemp = regionprops(Mask(:,:,ch),scaled_image(:,:,ch)-min(min(scaled_image(:,:,ch))),...
                'MaxIntensity', 'PixelValues', 'MeanIntensity', 'Area', 'Perimeter');
        %i've tried arrayfun as an alternative for this loop but did
        %not get it to work properly. Usually a loop is faster so it
        %should not be a problem 
        %StandardDeviation = arrayfun(@(x) std2(x.PixelValues),MsrTemp);
        for i=1:numel(MsrTemp)
            MsrTemp(i).StandardDeviation=std2(MsrTemp(i).PixelValues);
            MsrTemp(i).Mass=sum(MsrTemp(i).PixelValues(:));
            %MsrTemp(i).PixelValues=NaN;
            if MsrTemp(i).Area > 1
                MsrTemp(i).P2A=MsrTemp(i).Perimeter^2/(4*pi*MsrTemp(i).Area);
            else
                MsrTemp(i).P2A=NaN;
            end
        end
        MsrTemp=rmfield(MsrTemp,'PixelValues');
        %fill structure so tables can be concatonated.
        MsrTemp=fillStructure(MsrTemp,CC.NumObjects);
        names=strcat(dataP.channelTargets(ch),'_',fieldnames(MsrTemp));
        tempTable=struct2table(MsrTemp);
        tempTable.Properties.VariableNames=names;
        Msr=[Msr tempTable];
    end
    thumbs = makeThumbnail(CC,scaled_image,dataP);
    ID=[str2double(image_number)*10000+1:1:str2double(image_number)*10000+CC.NumObjects];
    Msr=[Msr array2table(ID','VariableNames',{'ID'}),cell2table(thumbs','VariableNames',{'ThumbNail'})];
end

end


function thumbs = makeThumbnail(CC,scaled_image,dataP)
Msr=regionprops(CC,'BoundingBox');
x=dataP.temp.imageSize(1);
y=dataP.temp.imageSize(2);
for k=1:CC.NumObjects
xdim = Msr(k).BoundingBox(3)+9;
ydim = Msr(k).BoundingBox(4)+9;
lower_x = floor(max(min(max(round(Msr(k).BoundingBox(1)-5),1), y-xdim-1),1));
lower_y = floor(max(min(max(round(Msr(k).BoundingBox(2)-5),1), x-ydim-1),1));
higher_x = ceil(min(max(1+xdim,min(lower_x+xdim,y)),y));
higher_y = ceil(min(max(1+ydim,min(lower_y+ydim,x)),x));
thumbs{k} = scaled_image(lower_y:higher_y,lower_x:higher_x,:);
end
end

function MsrTemp=fillStructure(MsrTemp,NumObjects)
numMsr=numel(MsrTemp);
if numMsr~=NumObjects
    if numMsr==0;
        MsrTemp=struct('Area',NaN ,'Perimeter',NaN,...
            'MeanIntensity',NaN ,'MaxIntensity',NaN ,...
            'StandardDeviation' ,NaN , 'Mass',NaN,'P2A',NaN );
        MsrTemp(1:NumObjects)=struct('Area',NaN ,'Perimeter',NaN,...
            'MeanIntensity',NaN ,'MaxIntensity',NaN ,...
            'StandardDeviation' ,NaN , 'Mass',NaN,'P2A',NaN );
    else
        MsrTemp(numMsr+1:NumObjects)=struct('Area',NaN ,'Perimeter',NaN,...
            'MeanIntensity',NaN ,'MaxIntensity',NaN ,...
            'StandardDeviation' ,NaN , 'Mass',NaN,'P2A',NaN);
    end
end
    idx=arrayfun(@(x) isempty(x.MaxIntensity),MsrTemp);
    MsrTemp(idx)=struct('Area',NaN ,'Perimeter',NaN,...
        'MeanIntensity',NaN ,'MaxIntensity',NaN ,...
        'StandardDeviation' ,NaN , 'Mass',NaN,'P2A',NaN);
end
