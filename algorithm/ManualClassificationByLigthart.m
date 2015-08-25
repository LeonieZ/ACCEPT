classdef ManualClassificationByLigthart < SampleProcessorObject
    %MANUAL_CLASSIFICATION_BYLIGTHART Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        classTable = table();
        nrObjects
        index
        type = [];
    end
    
    methods
        function this = ManualClassificationByLigthart(varargin)
            if nargin > 0
                this.type = varargin{1};
            else 
                this.type = 'Breast';
            end
            
            if nargin > 1
                this.index = varargin{2};
                this.nrObjects = 1;
            else 
                this.index = [];
                this.nrObjects = [];    
            end    
        end
        
        function returnFrame = run(this, inputFrame) %change to sample
            returnFrame = inputFrame;
            
            if isempty(inputFrame.measurements)
                notify(this,'logMessage',logmessage(1,'No measurements available for classification.'));
                return
            end
            
            if isempty(this.nrObjects)
                this.nrObjects = inputFrame.measurements.nrObjects;    
            end
            
            this.classTable = gate_objects(this,dataFrame); 
            
            returnFrame.classificationResults = this.classTable;
        end
        
        function tbl = gate_objects(this,dataFrame)
            tbl = table();
            
            if this.nrObjects > 0
                % load gates
                [Breast, Prostate, Cellline, WBC] = gates();
                
                if strcmp(this.type,'Breast')
                    CTCGates = Breast;
                elseif strcmp(this.type,'Prostate')
                    CTCGates = Prostate;
                end
                
                tbl.isACTC = isGatedBy(this,dataFrame,this.index,CTCGates);
                tbl.isWBC = isGatedBy(this,dataFrame,this.index,WBC);
                tbl.isCellline = isGatedBy(this,dataFrame,this.index,Cellline);   
            end
        end
        
        function bool = isGatedBy(this,dataFrame,index,gateStr)
        % This function returns if measured events falls in Gate

        % set gates for easy iteration
        gate_valuesl = zeros(1, size(gateStr,1));
        gate_valuesu = zeros(1, size(gateStr,1));
        for gate = 1:size(gateStr,1)
            if strcmp(gateStr{gate,2}, 'upper')
                gate_valuesl(gate) = -inf;
                gate_valuesu(gate) = gateStr{gate,3};
            else
                gate_valuesl(gate) = gateStr{gate,3};
                gate_valuesu(gate) = inf;
            end
        end

        if ~isempty(index)
            bool = true;
            for ii = 1:size(gateStr,1)
                include_event = dataFrame.measurements.msrTable.(gateStr{ii,1})(index) > gate_valuesl(ii) & dataFrame.measurements.msrTable.(gateStr{ii,1})(index) < gate_valuesu(ii);
                bool = bool & include_event;
            end
        else
            bool = true(this.nrObjects,1);
            for index = 1:this.nrObjects
                for ii = 1:size(gateStr,1)
                    include_event = dataFrame.measurements.msrTable.(gateStr{ii,1})(index) > gate_valuesl(ii) & dataFrame.measurements.msrTable.(gateStr{ii,1})(index) < gate_valuesu(ii);
                    bool(index) = bool(index) & include_event;
                end
            end
        end
        end

    end
    
end

function [Breast, Prostate, Cellline, WBC] = gates()
    Breast{1,1} = 'CK_StandardDeviation';
    Breast{1,2} = 'lower';
    Breast{1,3} = 50;
    Breast{2,1} = 'CK_Area';
    Breast{2,2} = 'lower';
    Breast{2,3} = 75;
    Breast{3,1} = 'CK_Area';
    Breast{3,2} = 'upper';
    Breast{3,3} = 2000;
    Breast{4,1} = 'DNA_MaxIntensity';
    Breast{4,2} = 'lower';
    Breast{4,3} = 170;
    Breast{5,1} = 'CD45_MaxIntensity';
    Breast{5,2} = 'upper';
    Breast{5,3} = 60;

    Prostate{1,1} = 'CK_StandardDeviation';
    Prostate{1,2} = 'lower';
    Prostate{1,3} = 50;
    Prostate{2,1} = 'CK_Area';
    Prostate{2,2} = 'lower';
    Prostate{2,3} = 75;
    Prostate{3,1} = 'CK_Area';
    Prostate{3,2} = 'upper';
    Prostate{3,3} = 500;
    Prostate{4,1} = 'DNA_MaxIntensity';
    Prostate{4,2} = 'lower';
    Prostate{4,3} = 170;
    Prostate{5,1} = 'CD45_MaxIntensity';
    Prostate{5,2} = 'upper';
    Prostate{5,3} = 60;

    Cellline{1,1} = 'CK_MaxIntensity';
    Cellline{1,2} = 'lower';
    Cellline{1,3} = 400;
    Cellline{2,1} = 'CK_Area';
    Cellline{2,2} = 'lower';
    Cellline{2,3} = 75;
    Cellline{3,1} = 'CK_Area';
    Cellline{3,2} = 'upper';
    Cellline{3,3} = 10000;
    Cellline{4,1} = 'DNA_MaxIntensity';
    Cellline{4,2} = 'lower';
    Cellline{4,3} = 170;
    Cellline{5,1} = 'CD45_MaxIntensity';
    Cellline{5,2} = 'upper';
    Cellline{5,3} = 200;

    WBC{1,1} = 'CK_StandardDeviation';
    WBC{1,2} = 'upper';
    WBC{1,3} = 50;
    WBC{2,1} = 'DNA_Area';
    WBC{2,2} = 'lower';
    WBC{2,3} = 50;
    WBC{3,1} = 'DNA_Area';
    WBC{3,2} = 'upper';
    WBC{3,3} = 1000;
    WBC{4,1} = 'DNA_MaxIntensity';
    WBC{4,2} = 'lower';
    WBC{4,3} = 170;
    WBC{5,1} = 'CD45_MaxIntensity';
    WBC{5,2} = 'lower';
    WBC{5,3} = 100;
    WBC{6,1} = 'DNA_P2A';
    WBC{6,2} = 'upper';
    WBC{6,3} = 1.5;
end



