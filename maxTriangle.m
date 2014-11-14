function [Success_out, varargout] = maxTriangle(input_tiff_dir, MaskEdgesCartridge, dataP, algP)
%Determine treshold by maxtriangle
%dist - based on ACTC Scripts FindObjectsinCartridge, MaxTriangleDist
%% parameters and initialization
varargout = cell(dataP.numFrames,1);

%% Threshold
for ii = 1:dataP.numFrames
    % determine global threshold for all images, by creating one big histogram
    [HistTotal, BinsTriangleThreshold, Success_out] = CreateBigHist(input_tiff_dir, MaskEdgesCartridge,...
        ii, dataP, algP);
%     bar(HistTotal);

    % get global cartridge threshold value
    varargout{ii} = MaxTriangleDist(HistTotal, BinsTriangleThreshold);
end

end %function maxTriangle

%% function to determine the treshold
function thres_val_out = MaxTriangleDist(Hist_in, Bins_in)
    % function to determine a threshold value using the "triangle threshold"
    % method. This method determines the maximum distance of the image
    % histogram to a line from the maximum count to the maximum bin. 

    % determine maximum counts and index to derive slope
    MaxBin = Bins_in(find(Hist_in, 1, 'last'));
    [MaxCounts, Index]= max(Hist_in);

    % if maximum number of pixels are saturated, neglect these pixels in
    % determining the threshold
    if Index == Bins_in(end)
        Hist_in(end) = 0; 
        [MaxCounts, Index]= max(Hist_in);
    end
    %rcRamp = MaxCounts/(Bins_in(Index)-Bins_in(end));
    rcRamp = (Hist_in(MaxBin)-MaxCounts)/(Bins_in(MaxBin)-Bins_in(Index));

    % solve linear equation ax+b=-(x-c)/a+d for x
    % solution: x = (d-b+c/a)/(a+1/a)
    XCrossing = (Hist_in(Index:MaxBin)-MaxCounts+(Bins_in(Index:MaxBin )-Bins_in(Index))/rcRamp)/(rcRamp+1/rcRamp);
    YCrossing = rcRamp*XCrossing + MaxCounts;

    DistToRamp = sqrt((XCrossing-Bins_in(Index:MaxBin)).^2+(YCrossing-Hist_in(Index:MaxBin )).^2);
    [MaxDist, IndexThresVal] = max(DistToRamp);

    thres_val_out = Bins_in(IndexThresVal+Index-1);
end %function maxTriangleDist