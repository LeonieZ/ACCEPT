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
gui.im1 = plot_image(gui.im1_ax,gui.thumbs{i},gui.maxi,'fullscale_mg');
gui.im2 = plot_image(gui.im2_ax,gui.thumbs{i}(:,:,1),gui.maxi,'fullscale');
gui.im3 = plot_image(gui.im3_ax,gui.thumbs{i}(:,:,2),gui.maxi,'fullscale');
gui.im4 = plot_image(gui.im4_ax,gui.thumbs{i}(:,:,3),gui.maxi,'fullscale');
gui.im5 = plot_image(gui.im5_ax,gui.thumbs{i},gui.maxi,'normalized_mg');
gui.im6 = plot_image(gui.im6_ax,gui.thumbs{i}(:,:,1),gui.maxi,'normalized');
gui.im7 = plot_image(gui.im7_ax,gui.thumbs{i}(:,:,2),gui.maxi,'normalized');
gui.im8 = plot_image(gui.im8_ax,gui.thumbs{i}(:,:,3),gui.maxi,'normalized');
end

