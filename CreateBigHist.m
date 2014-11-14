function [Hist_out, BinsTriangleThreshold_out, Succes_out] = CreateBigHist(DirectoryNameTiffs_in, MaskEdgesCartridge_in, ...
    ChannelToThreshold_in, dataP, algP)

Hist_out = 0;
TiffFiles = dir([DirectoryNameTiffs_in filesep '*.tif']);
TifCount = length(TiffFiles);
Succes_out = [];

BinsTriangleThreshold_out = 1:1:4095;

for ii = 1:TifCount
            
    % read tiffs from threshold channel
    FileNameTif = [DirectoryNameTiffs_in filesep TiffFiles(ii).name];
    [ScaledImage, ErrorTiff] = ReadImmcTiffAndScale(FileNameTif, ChannelToThreshold_in, dataP, algP);
    
    if strcmp(ErrorTiff, 'Tiff is not an IMMC tiff!')
        Succes_out = ErrorTiff;
        return
    elseif strcmp(ErrorTiff, ['Tiff from channel ' num2str(ChannelToThreshold_in) ' is not readable!'])
        Succes_out = ErrorTiff;
        return
    end
    
    % if there is an offset of 32768, subtract
    if max(ScaledImage) > 32767
        ScaledImage = ScaledImage - 32768;
    end
    
    % select mask from stack and resize
    MaskEdge = imresize(squeeze(MaskEdgesCartridge_in(:,:,ii)),size(ScaledImage));
    
    % create total histogram, by using the same bins every time (creating
    % one big image costs too much memory). Reshape masked image for
    % correct creation of histogram
    VectorIm = reshape(double(ScaledImage(MaskEdge)),1,[]);
  
    
    if ~isempty(VectorIm)
        HistIm = hist(VectorIm, BinsTriangleThreshold_out);
        Hist_out = Hist_out + HistIm;
    end
end