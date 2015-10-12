function [ ] = refresh_gui( gui, score, i )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
set(gui.thumbs_number,'String',num2str(i));
set(gui.sld,'Value',i);

if isempty(score{i})
        set(gui.score, 'String', '-');
    else
        set(gui.score, 'String', num2str(score{i}));
end 

axes(gui.im1_ax); 
if gui.maxi == 255
    gui.im1 = imagesc(flip(uint8(gui.thumbs{i}),3)); 
else
    gui.im1 = imagesc(flip((single(gui.thumbs{i})/single(gui.maxi)),3)); 
end %are there more possibilities?
set(gui.im1_ax,'visible','off'); %freezeColors;
axes(gui.im2_ax); gui.im2 = imagesc(cat(3,zeros(size(gui.thumbs{i}(:,:,1))),zeros(size(gui.thumbs{i}(:,:,1))),single(gui.thumbs{i}(:,:,1))/single(gui.maxi))); axis off;%colormap(gui.im2_ax, gui.map_blue); set(gui.im2_ax,'visible','off','CLim',[gui.mini, gui.maxi]); freezeColors;
axes(gui.im3_ax); gui.im3 = imagesc(cat(3,zeros(size(gui.thumbs{i}(:,:,2))),single(gui.thumbs{i}(:,:,2))/single(gui.maxi),zeros(size(gui.thumbs{i}(:,:,2))))); axis off; %colormap(gui.im3_ax, gui.map_green); set(gui.im3_ax,'visible','off','CLim',[gui.mini, gui.maxi]); freezeColors;
axes(gui.im4_ax); gui.im4 = imagesc(cat(3,single(gui.thumbs{i}(:,:,3))/single(gui.maxi),zeros(size(gui.thumbs{i}(:,:,3))),zeros(size(gui.thumbs{i}(:,:,3))))); axis off; %colormap(gui.im4_ax, gui.map_red); set(gui.im4_ax,'visible','off','CLim',[gui.mini, gui.maxi]); freezeColors;

axes(gui.im5_ax);
if gui.maxi == 255
    gui.im5 = imagesc(flip(uint8((gui.thumbs{i}-repmat(min(min(gui.thumbs{i})),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1))*255./repmat(max(max(gui.thumbs{i}-repmat(min(min(gui.thumbs{i})),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1))),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1)),3));
else
    gui.im5 = imagesc(flip(single(gui.thumbs{i}-repmat(min(min(gui.thumbs{i})),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1))./single(repmat(max(max(gui.thumbs{i}-repmat(min(min(gui.thumbs{i})),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1))),size(gui.thumbs{i},1),size(gui.thumbs{i},2),1)),3));
end    
set(gui.im5_ax,'visible','off'); %freezeColors;
axes(gui.im6_ax); gui.im6 = imagesc(cat(3,zeros(size(gui.thumbs{i}(:,:,1))),zeros(size(gui.thumbs{i}(:,:,1))),single(gui.thumbs{i}(:,:,1)-min(min(gui.thumbs{i}(:,:,1))))/single(max(max(gui.thumbs{i}(:,:,1)))))); axis off; %colormap(gui.im6_ax, gui.map_blue); set(gui.im6_ax,'visible','off','CLim',[min(min(gui.thumbs{i}(:,:,1))),max(max(gui.thumbs{i}(:,:,1)))]); freezeColors;
axes(gui.im7_ax); gui.im7 = imagesc(cat(3,zeros(size(gui.thumbs{i}(:,:,2))),single(gui.thumbs{i}(:,:,2)-min(min(gui.thumbs{i}(:,:,2))))/single(max(max(gui.thumbs{i}(:,:,2)))),zeros(size(gui.thumbs{i}(:,:,2))))); axis off; %colormap(gui.im7_ax, gui.map_green); set(gui.im7_ax,'visible','off','CLim',[min(min(gui.thumbs{i}(:,:,2))),max(max(gui.thumbs{i}(:,:,2)))]); freezeColors;
axes(gui.im8_ax); gui.im8 = imagesc(cat(3,single(gui.thumbs{i}(:,:,3)-min(min(gui.thumbs{i}(:,:,3))))/single(max(max(gui.thumbs{i}(:,:,3)))),zeros(size(gui.thumbs{i}(:,:,3))),zeros(size(gui.thumbs{i}(:,:,3))))); axis off; %colormap(gui.im8_ax, gui.map_red); set(gui.im8_ax,'visible','off','CLim',[min(min(gui.thumbs{i}(:,:,3))),max(max(gui.thumbs{i}(:,:,3)))]); freezeColors;
end

