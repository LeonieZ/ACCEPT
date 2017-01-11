classdef ManualClassification < SampleProcessorObject
    %MANUAL_CLASSIFICATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        index
        name = 'manualGate';
        gates
    end
    
    methods
        function this = ManualClassification(gates,name,varargin)
            %varargin{1} type and varargin{2} this.index if only one entry
            %should be processed
            
            this.gates = gates;
            
            this.name = name;
            
            if nargin > 2
                this.index = varargin{2};
            else 
                this.index = [];
            end    
        end
        
        function returnSample = run(this, inputSample)
            if ~iscell(this.gates) || size(this.gates,2) ~= 3
                 error('Gates are not in the correct format.')
            end
            if isa(inputSample,'Sample')
                returnSample = inputSample;

                if isempty(inputSample.results.features)
                    notify(this,'logMessage',logmessage(1,'No features available for classification.'));
                    return
                end
                
                if sum(strcmp(returnSample.results.classification.Properties.VariableNames,this.name)) == 0
                    returnSample.results.classification = [returnSample.results.classification gate_objects(this,inputSample)];
                else
                    returnSample.results.classification(:,strcmp(returnSample.results.classification.Properties.VariableNames,this.name)) = [];
                    returnSample.results.classification = [returnSample.results.classification gate_objects(this,inputSample)];
                end

            elseif isa(inputSample,'table')
                if isempty(inputSample)
                    notify(this,'logMessage',logmessage(1,'No features available for classification.'));
                    return
                end


                returnSample = gate_objects(this,inputSample);
            else
                error('Manual Classification can be only used with a sample or a table as input.')
            end
        end

        function tbl = gate_objects(this,inputSample)
            gates = this.gates;
            tbl = table();
            if isa(inputSample,'Sample')
                nrObjects = size(inputSample.results.features,1);
            else
                nrObjects = size(inputSample,1);
            end
            if nrObjects > 0
                eval(['tbl.' this.name ' = isGatedBy(this,inputSample,gates,nrObjects);']); 
            end
        end

        function bool = isGatedBy(this,inputSample,gateStr,nrObjects)
            % This function returns if measured events falls in Gate

            % set gates for easy iteration
            gate_valuesl = zeros(1, size(gateStr,1));
            gate_valuesu = zeros(1, size(gateStr,1));
            for gate = 1:size(gateStr,1)
                if ~isempty(gateStr{gate,2})
                    if strcmp(gateStr{gate,2}, 'upper')
                        gate_valuesl(gate) = -inf;
                        gate_valuesu(gate) = gateStr{gate,3};
                    else
                        gate_valuesl(gate) = gateStr{gate,3};
                        gate_valuesu(gate) = inf;
                    end
                end
            end
            toDelete = gate_valuesl == gate_valuesu;
            gate_valuesl(toDelete) = [];
            gate_valuesu(toDelete) = [];
            gateStr(toDelete,:) = [];

            if isa(inputSample,'Sample')
                features = inputSample.results.features;
                features_noNaN = features{:,:};
                features_noNaN(isnan(features_noNaN)) = 0;
                features{:,:} = features_noNaN;     

                if ~isempty(this.index)
                    bool = true;
                    for ii = 1:size(gateStr,1)
                        if ~isempty(gateStr{ii,1}) && sum(ismember(fieldnames(features),gateStr{ii,1}))>0
                            include_event = features.(gateStr{ii,1})(this.index) > gate_valuesl(ii) & features.(gateStr{ii,1})(this.index) <= gate_valuesu(ii);
                            bool = bool & include_event;
                        end
                    end
                else
                    bool = true(nrObjects,1);
%                     for j = 1:nrObjects
%                         for ii = 1:size(gateStr,1)
%                             if ~isempty(gateStr{ii,1}) && sum(ismember(fieldnames(features),gateStr{ii,1}))>0
%                                 include_event = features.(gateStr{ii,1})(j) > gate_valuesl(ii) & features.(gateStr{ii,1})(j) <= gate_valuesu(ii);
%                                 bool(j) = bool(j) & include_event;
%                             end
%                         end
%                     end
                    for ii = 1:size(gateStr,1)
                        if ~isempty(gateStr{ii,1}) && sum(ismember(fieldnames(features),gateStr{ii,1}))>0
                            include_event = features.(gateStr{ii,1}) > gate_valuesl(ii) & features.(gateStr{ii,1}) <= gate_valuesu(ii);
                            bool = bool & include_event;
                        end
                    end
                end
            elseif isa(inputSample,'table')
                if ~isempty(this.index)
                    bool = true;
                    for ii = 1:size(gateStr,1)
                        if ~isempty(gateStr{ii,1}) && sum(ismember(fieldnames(inputSample),gateStr{ii,1}))>0
                            include_event = inputSample.(gateStr{ii,1})(this.index) > gate_valuesl(ii) & inputSample.(gateStr{ii,1})(this.index) <= gate_valuesu(ii);
                            bool = bool & include_event;
                        end
                    end
                else
                    bool = true(nrObjects,1);
%                     for j = 1:nrObjects
%                         for ii = 1:size(gateStr,1)
%                             if ~isempty(gateStr{ii,1}) && sum(ismember(fieldnames(inputSample),gateStr{ii,1}))>0
%                                 include_event = inputSample.(gateStr{ii,1})(j) > gate_valuesl(ii) & inputSample.(gateStr{ii,1})(j) <= gate_valuesu(ii);
%                                 bool(j) = bool(j) & include_event;
%                             end
%                         end
%                     end
                    for ii = 1:size(gateStr,1)
                        if ~isempty(gateStr{ii,1}) && sum(ismember(fieldnames(inputSample),gateStr{ii,1}))>0
                            include_event = inputSample.(gateStr{ii,1}) > gate_valuesl(ii) & inputSample.(gateStr{ii,1}) <= gate_valuesu(ii);
                            bool = bool & include_event;
                        end
                    end
                end     
            end
            bool = double(bool);
        end

    end
end



