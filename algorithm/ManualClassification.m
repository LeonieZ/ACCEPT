%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 
classdef ManualClassification < SampleProcessorObject
    %MANUAL_CLASSIFICATION applies a combination of linear gates on the
    %extracted features for every object found
    
    properties
        index
        name = 'manualGate';
        gates
    end
    
    methods
        function this = ManualClassification(gates,name,varargin)
            %varargin{1} type and varargin{2} fills this.index if only one entry
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
            %check if gates are in correct format
            if ~iscell(this.gates) || size(this.gates,2) ~= 3
                 error('Gates are not in the correct format.')
            end
            if isa(inputSample,'Sample')
                %load sample
                returnSample = inputSample;
                
                %check of feature table exists
                if isempty(inputSample.results.features)
                    notify(this,'logMessage',logmessage(1,'No features available for classification.'));
                    return
                end
                
                %check if classification with given name exists, if yes
                %delete first, then attach new classification
                if sum(strcmp(returnSample.results.classification.Properties.VariableNames,this.name)) == 0
                    returnSample.results.classification = [returnSample.results.classification gate_objects(this,inputSample)];
                else
                    returnSample.results.classification(:,strcmp(returnSample.results.classification.Properties.VariableNames,this.name)) = [];
                    returnSample.results.classification = [returnSample.results.classification gate_objects(this,inputSample)];
                end

            elseif isa(inputSample,'table')
                %check if table is not empty
                if isempty(inputSample)
                    notify(this,'logMessage',logmessage(1,'No features available for classification.'));
                    return
                end

                %fill output table with results
                returnSample = gate_objects(this,inputSample);
            else
                error('Manual Classification can be only used with a sample or a table as input.')
            end
        end

        function tbl = gate_objects(this,inputSample)
            %load gates
            gates = this.gates;
            tbl = table();
            %nr of objects to be gated
            if isa(inputSample,'Sample')
                nrObjects = size(inputSample.results.features,1);
            else
                nrObjects = size(inputSample,1);
            end
            %call gate function
            if nrObjects > 0
                eval(['tbl.' this.name ' = isGatedBy(this,inputSample,gates,nrObjects);']); 
            end
        end

        function bool = isGatedBy(this,inputSample,gateStr,nrObjects)
            % This function returns if measured events fall in gate

            % set gates for easy iteration
            gate_valuesl = zeros(1, size(gateStr,1));
            gate_valuesu = zeros(1, size(gateStr,1));
            %determine if upper or lower bound
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
            %delete if uppen and lower bound are the same
            toDelete = gate_valuesl == gate_valuesu;
            gate_valuesl(toDelete) = [];
            gate_valuesu(toDelete) = [];
            gateStr(toDelete,:) = [];

            if isa(inputSample,'Sample')
                %load features to gate
                features = inputSample.results.features;
                %replace NaN values with 0
                features_noNaN = features{:,:};
                features_noNaN(isnan(features_noNaN)) = 0;
                features{:,:} = features_noNaN;     
                
                %do the actual gating
                if ~isempty(this.index) %gate all entries
                    bool = true;
                    for ii = 1:size(gateStr,1)
                        if ~isempty(gateStr{ii,1}) && sum(ismember(fieldnames(features),gateStr{ii,1}))>0
                            include_event = features.(gateStr{ii,1})(this.index) > gate_valuesl(ii) & features.(gateStr{ii,1})(this.index) <= gate_valuesu(ii);
                            bool = bool & include_event;
                        end
                    end
                else %gate single entry
                    bool = true(nrObjects,1);
                    for ii = 1:size(gateStr,1)
                        if ~isempty(gateStr{ii,1}) && sum(ismember(fieldnames(features),gateStr{ii,1}))>0
                            include_event = features.(gateStr{ii,1}) > gate_valuesl(ii) & features.(gateStr{ii,1}) <= gate_valuesu(ii);
                            bool = bool & include_event;
                        end
                    end
                end
            elseif isa(inputSample,'table')
                if ~isempty(this.index) %gate all entries
                    bool = true;
                    for ii = 1:size(gateStr,1)
                        if ~isempty(gateStr{ii,1}) && sum(ismember(fieldnames(inputSample),gateStr{ii,1}))>0
                            include_event = inputSample.(gateStr{ii,1})(this.index) > gate_valuesl(ii) & inputSample.(gateStr{ii,1})(this.index) <= gate_valuesu(ii);
                            bool = bool & include_event;
                        end
                    end
                else
                    bool = true(nrObjects,1); %gate only one entry
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



