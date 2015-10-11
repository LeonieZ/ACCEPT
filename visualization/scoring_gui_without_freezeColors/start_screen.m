function fig_logo = start_screen

screen = get(0,'screensize');
swidth  = screen(3);
sheight = screen(4);

im = imread('CTC_image+logo.png');
iwidth  = size(im,2);
iheight = size(im,1);

pos = [(swidth-0.5*iwidth)/2 (sheight-0.5*iheight)/2 0.5*iwidth 0.5*iheight];

fig_logo = figure('visible','on','menubar','none','paperpositionmode','auto','numbertitle','off','resize','off','position',pos,'name','CTC Scoring Tool');

image(im);
set(gca,'visible','off','Position',[0 0 1 1]);

text(0.5,0.5, 'CTC Scoring Tool','units','normalized','horizontalalignment','left','fontsize',50,'color',[1 1 1]);
text(30,90, 'Version: 0.1,  (2015-08-01)','units','pixel','horizontalalignment','left','fontsize',20,'color',[1 1 1]);
text(30,65, 'Code by Leonie Zeune, Guus van Dalum & Christoph Brune','units','pixel','horizontalalignment','left','fontsize',15,'color',[1 1 1]);
end