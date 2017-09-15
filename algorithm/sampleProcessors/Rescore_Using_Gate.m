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
classdef Rescore_Using_Gate < SampleProcessor
    % Rescore_Using_Gate SampleProcessor for gating of extracted objects.
        
    properties
        previousProcessor = SampleProcessor();
        gate = struct('gates',cell(0),'name','');
    end
    
    methods 
        function this = Rescore_Using_Gate()
            this.name = 'Rescore Using Gate';
            this.version = '0.1';
            this.pipeline = this.make_sample_pipeline();
            this.showInList = false;
        end
        
        
        function [] = set_gates(this,savedGate) 
            if savedGate == 0
                %call gui to specify gates
                gui_gates = gui_manual_gates();
                waitfor(gui_gates.fig_main,'UserData')
                try
                    %store gates
                    this.gate = get(gui_gates.fig_main,'UserData');
                catch 
                    return
                end
                %delete gui
                delete(gui_gates.fig_main)
                clear('gui_gates');
            elseif savedGate == 1
                %load gates saved before
                file = which('ACCEPT.m');
                installDir = fileparts(file);
                [file_name, folder_name] = uigetfile([installDir filesep 'misc' filesep 'saved_gates' filesep '*.mat'],'Load gate.');
                try
                    this.gate(1).gates = importdata([folder_name filesep file_name]);
                    this.gate(1).name = strrep(file_name,'.mat','');
                catch 
                    return
                end
            else
                return
            end
            %store name and gates
            if ~isempty(this.gate)
                this.pipeline{1}.name = this.gate.name;
                this.pipeline{1}.gates = this.gate.gates;
            end
        end
        
        function run(this,inputSample)
            %start gating
            if isempty(this.gate)
                this.set_gates(0);
            end
            
            if isempty(inputSample.results.features)
                %When we have nothing to gate we run the original sampleProcessor
                this.previousProcessor.run(inputSample);
            end
            
            % apply gate
            this.pipeline{1}.run(inputSample);  

        end
    end
    
    methods (Static)      
        function pipeline = make_sample_pipeline()
            pipeline = cell(0);
      
            mc = ManualClassification(cell(0),'ManualGates');
            pipeline{1} = mc;           
        end
    end
    
end