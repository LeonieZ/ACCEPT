classdef SampleOverviewLoading < SampleProcessorObject
    %SAMPLEOVERVIEWLOADING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        reductionFactor = 1/8;
    end
    
    methods
        function this = SampleOverviewLoading(reductionFactor)
            if nargin == 1
                this.reductionFactor = reductionFactor;
            end    
        end
        
        function returnSample = run(this, inputSample)
            returnSample = inputSample;
            
            if isempty(returnSample.overviewImage)                    
                loader = inputSample.loader(inputSample);
                if ~isa(loader,'ThumbnailLoader')
                    returnSample.histogram = zeros(65535,inputSample.imageSize(3));
                    returnSample.histogram_down = zeros(65535,inputSample.imageSize(3));
                    frameOrder = loader.calculate_frame_nr_order;
                    reducedSize = [ceil(inputSample.imageSize(1)*this.reductionFactor(1)),inputSample.imageSize(2)*this.reductionFactor(1),inputSample.imageSize(3)];
                    reducedSize = ceil(reducedSize);
                    inputSample.overviewImage = zeros(reducedSize(1)*inputSample.rows,reducedSize(2)*inputSample.columns,reducedSize(3),'uint16');
                    for i = 1:inputSample.rows
                        for j = 1:inputSample.columns
                            offset=[reducedSize(1)*(i-1)+1,reducedSize(2)*(j-1)+1];
                            frame = loader.load_data_frame(frameOrder(i,j));
                            tempImage=imresize(frame.rawImage,this.reductionFactor);
                            inputSample.overviewImage(offset(1):offset(1)+reducedSize(1)-1,offset(2):offset(2)+reducedSize(2)-1,:)=tempImage;
                            inputSample.histogram = inputSample.histogram + histc(reshape(frame.rawImage,numel(frame.rawImage)/frame.nrChannels,frame.nrChannels),1:1:65535);
                            inputSample.histogram_down = inputSample.histogram_down + histc(reshape(tempImage,numel(tempImage)/frame.nrChannels,frame.nrChannels),1:1:65535);
                        end
                    end
                end
            end
        end
    end   
end
