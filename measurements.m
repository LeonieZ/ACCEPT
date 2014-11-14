function [Msr, Thumbs] = measurements(seg_image, image_to_seg, image_number, dataP, algP);
    
% %empty IDsMsr so check in if statement wbc works
%     IDsMsr=[];
%     % start off by evaluating all dapi positive events. We have to be
%     % carefull of size as at actc classifier is based on PE mask
%     % size not dapi!!!
Thumbs = [];
Msr = [];

DAPI_im = squeeze(image_to_seg(:,:,1));
FITC_im = squeeze(image_to_seg(:,:,2));
PE_im = squeeze(image_to_seg(:,:,3));
APC_im = squeeze(image_to_seg(:,:,4));
Mask = squeeze(seg_image(:,:,dataP.thresholdChannel));

[x, y] = size(Mask);

CC = bwconncomp(Mask,4);
    
if CC.NumObjects > 0
            %only dapi measurements needs dimensions etc, those are for
            %all other msrs the same. Subtract minimum value to get rid of
            %certain offsets.
            MsrDAPI = regionprops(CC, DAPI_im-min(DAPI_im(:)), ...
                'MaxIntensity', 'PixelValues', 'MeanIntensity', 'Area', 'Perimeter','BoundingBox');
%             MsrDAPI(k).StandardDeviation = std(double(MsrDAPI(k).PixelValues));
%             MsrDAPI(k).StandardDeviation = sum(double(MsrDAPI(k).PixelValues));
            
            MsrFITC = regionprops(CC, FITC_im-min(FITC_im(:)), ...
                'MaxIntensity', 'PixelValues', 'MeanIntensity');
            MsrPE = regionprops(CC, PE_im-min(PE_im(:)), ...
                'MaxIntensity', 'PixelValues', 'MeanIntensity');
            MsrAPC = regionprops(CC, APC_im-min(APC_im(:)), ...
                'MaxIntensity', 'PixelValues', 'MeanIntensity');

            for k = 1 : CC.NumObjects
                Msr(k).ID = str2double([num2str(image_number) num2str(dataP.thresholdChannel) num2str(k,'%04.0f')]);
                Msr(k).ImgNum = str2double(image_number);
                Msr(k).MaxIntensity_DAPI = MsrDAPI(k).MaxIntensity; 
                Msr(k).MeanIntensity_DAPI = MsrDAPI(k).MeanIntensity; 
                Msr(k).StandardDeviation_DAPI = std(double(MsrDAPI(k).PixelValues));
                Msr(k).Mass_DAPI = sum(double(MsrDAPI(k).PixelValues));
                Msr(k).Area = MsrDAPI(k).Area; 
                Msr(k).Perimeter = MsrDAPI(k).Perimeter; 
                Msr(k).BoundingBox = MsrDAPI(k).BoundingBox;
                Msr(k).MaxIntensity_FITC = MsrFITC(k).MaxIntensity; 
                Msr(k).MeanIntensity_FITC = MsrFITC(k).MeanIntensity;
                Msr(k).StandardDeviation_FITC = std(double(MsrFITC(k).PixelValues));
                Msr(k).Mass_FITC = sum(double(MsrFITC(k).PixelValues));
                Msr(k).MaxIntensity_PE = MsrPE(k).MaxIntensity; 
                Msr(k).MeanIntensity_PE = MsrPE(k).MeanIntensity;
                Msr(k).StandardDeviation_PE = std(double(MsrPE(k).PixelValues));
                Msr(k).Mass_PE = sum(double(MsrPE(k).PixelValues));
                Msr(k).MaxIntensity_APC = MsrAPC(k).MaxIntensity; 
                Msr(k).MeanIntensity_APC = MsrAPC(k).MeanIntensity;
                Msr(k).StandardDeviation_APC = std(double(MsrAPC(k).PixelValues));
                Msr(k).Mass_APC = sum(double(MsrAPC(k).PixelValues));
                
                xdim = Msr(k).BoundingBox(3)+9;
                ydim = Msr(k).BoundingBox(4)+9;
                lower_x = min(max(round(Msr(k).BoundingBox(1)-5),1), y-xdim-1);
                lower_y = min(max(round(Msr(k).BoundingBox(2)-5),1), x-ydim-1);
                higher_x = max(1+xdim,min(lower_x+xdim,y));
                higher_y = max(1+ydim,min(lower_y+ydim,x));
                
                Thumbs = zeros(ydim+1, xdim+1,5);
                Thumbs(:,:,1) = DAPI_im(lower_y:higher_y,lower_x:higher_x);
                Thumbs(:,:,2) = FITC_im(lower_y:higher_y,lower_x:higher_x);
                Thumbs(:,:,3) = PE_im(lower_y:higher_y,lower_x:higher_x);
                Thumbs(:,:,4) = APC_im(lower_y:higher_y,lower_x:higher_x);
                Thumbs(:,:,5) = Mask(lower_y:higher_y,lower_x:higher_x);
                
                Msr(k).Thumbs = Thumbs;
                

%                 Msr(k).Thumbs(:,:,1) = DAPI_im(lower_x:higher_x,lower_y:higher_y);
%                 Msr(k).Thumbs(:,:,2) = FITC_im(lower_x:higher_x,lower_y:higher_y);
%                 Msr(k).Thumbs(:,:,3) = PE_im(lower_x:higher_x,lower_y:higher_y);
%                 Msr(k).Thumbs(:,:,4) = APC_im(lower_x:higher_x,lower_y:higher_y);
%                 Msr(k).Thumbs(:,:,5) = Mask(lower_x:higher_x,lower_y:higher_y);
%                 
            end
            
%             % change msrs that have more than 1 row, for GUI displaying purposes. Remove old msrs.
%             MsrDAPI = ChangeGravity(MsrDAPI);
%             MsrDAPI = RmvMsrmnts(MsrDAPI, 'Gravity');
%             SizeNucleiImg = [];
%             NrobjectsPE = zeros(1, max(LabelImage));
%             NrobjectsDAPI = zeros(1, max(LabelImage));
%                         
%             imHelpPE = squeeze(image_to_seg(:,:,2));
%             imHelpDAPI = squeeze(image_to_seg(:,:,0));
%             MpImgPE = multiscaleProduct(imHelpPE, 1.5);
%             MinimumC = MsrPE.minimum;
%             MaximumC = MsrPE.maximum;
%             MsrId = MsrPE.id;
%             
%             for jj = 1:max(LabelImage)
%                 bool = MsrDAPI(jj).size > 75 & MsrDAPI(jj).size < 2000 & MsrDAPI(jj).MaxVal > 170 & MsrPE(jj).StdDev > 50 & MsrAPC(jj).Maxval < 60;
%                 if bool
%                     maskTotalLabel = LabelImage == jj;
%                     xMask = MinimumC(1,MsrId==jj)-5:MaximumC(1,MsrId==jj)+5;
%                     xMask(xMask<0|xMask>size(imHelpPE,1)-1)=[];
%                     yMask = MinimumC(2,MsrId==jj)-5:MaximumC(2,MsrId==jj)+5;
%                     yMask(yMask<0|yMask>size(imHelpPE,2)-1)=[];
%                     maskIn = maskTotalLabel(xMask, yMask);
%                     CutImageMPPE = MpImgPE(xMask, yMask);
%                    
%                     CutImageOrigPE = imHelpPE(xMask, yMask);
%                     CutImageDAPI = imHelpDAPI(xMask, yMask);
%                     
%                     [NrobjectsDAPI(jj) SizeNuclei] = countDapiNuclei(CutImageDAPI, maskIn);
%                     SizeNucleiImg = [SizeNucleiImg SizeNuclei];
%                     
%                     [msr_dots_dummy NrobjectsPE(jj) mask_dummy] = countDots(CutImageMPPE, CutImageOrigPE, maskIn, 3);
% 
%                 else
%                     NrobjectsPE(jj) = 0;
% %                     NrobjectsDAPI(jj) = 0;
%                 end
%             end
%             MsrPEApoptosis = dip_measurement(MsrPE.id, 'Apoptosis' , NrobjectsPE);
%             MsrPE = [MsrPE, MsrPEApoptosis];
%             MsrDAPICluster = dip_measurement(MsrDAPI.id, 'Cluster' , NrobjectsDAPI);
%             MsrDAPI = [MsrDAPI, MsrDAPICluster];
%             sizesTotal = [sizesTotal SizeNucleiImg];
%             
%            % set prefixes so msrs can be combined.
%             MsrDAPI.prefix ='DAPI';
%             MsrFITC.prefix ='FITC';
%             MsrPE.prefix ='PE';
%             MsrAPC.prefix ='APC';
%             MsrImage = [MsrDAPI, MsrFITC, MsrPE, MsrAPC];
%             
%             % create measurement IDs to match image numbers. Max 10000
%             % objects are now possible per image, determined by padded
%             % zeros at num2str
%             IDsMsr = zeros(1, size(MsrImage,1));
%             for jj = 1:size(MsrImage,1)
%                 IDsMsr(jj) = str2double([num2str(ImgNumber) num2str(3) num2str(jj,'%04.0f')]);
%             end
%             
%             % assign IDs and add measurements to total measurements
%             if size(MsrTotal,1) == 0
%                 % set image ids
%                 MsrImage.id = IDsMsr(1):IDsMsr(end);
%                 MsrTotal = MsrImage;
%             else
%                 MsrImage.id = IDsMsr(1):IDsMsr(end);
%                 MsrTotal = [MsrTotal; MsrImage];
%             end
% end

end


