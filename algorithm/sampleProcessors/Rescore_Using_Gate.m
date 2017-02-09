classdef Rescore_Using_Gate < SampleProcessor
%CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
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
                gui_gates = gui_manual_gates();
                waitfor(gui_gates.fig_main,'UserData')
                try
                    this.gate = get(gui_gates.fig_main,'UserData');
                catch 
                    return
                end
                delete(gui_gates.fig_main)
                clear('gui_gates');
            elseif savedGate == 1
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
            if ~isempty(this.gate)
                this.pipeline{1}.name = this.gate.name;
                this.pipeline{1}.gates = this.gate.gates;
            end
        end
        
        function run(this,inputSample)
 
            if isempty(this.gate)
                this.set_gates(0);
            end
            
            if isempty(inputSample.results.features)
                %When we have nothing to gate we run the original sampleProcessor
                this.previousProcessor.run(inputSample);
            end
            
            %apply gate
            this.pipeline{1}.run(inputSample);  
%             IO.attach_results_summary(inputSample)

        end
    end
    
    methods (Static)      
        function pipeline = make_sample_pipeline()
            pipeline = cell(0);
      
            mc = ManualClassification(cell(0),'ManualGates');
            pipeline{1} = mc;           
        end
    end
    
%     methods (Static)    
%         function pipeline = make_dataframe_pipeline()
%             pipeline = cell(0);
%             ef = ExtractFeatures();      
%             pipeline{1} = [];
%             pipeline{2} = ef;
%         end
%         
%         function [selectedProcessorId,selectedProcessor] = choose_processor_to_rescore()
%                 d = dialog('Position',[300 300 250 150],'Name','Select a sample processor that you want to rescore');
%                 processors=IO.check_available_sample_processors();
%                 txt = uicontrol('Parent',d,...
%                        'Style','text',...
%                        'Position',[20 80 210 40],...
%                        'String','Select a color');
% 
%                 popup = uicontrol('Parent',d,...
%                        'Style','popup',...
%                        'Position',[75 70 100 25],...
%                        'String',cellfun(@(s) s.name,processors,'UniformOutput',false),...
%                        'Callback',@popup_callback);
% 
%                 btn = uicontrol('Parent',d,...
%                        'Position',[89 20 70 25],...
%                        'String','choose',...
%                        'Callback','delete(gcf)');
% 
%                 selectedProcessor = processors{1};
% 
%                 % Wait for d to close before running to completion
%                 uiwait(d);
% 
%                 function popup_callback(popup,callbackdata)
%                       idx = popup.Value;
%                       % This code uses dot notation to get properties.
%                       % Dot notation runs in R2014b and later.
%                       % For R2014a and earlier:
%                       % idx = get(popup,'Value');
%                       % popup_items = get(popup,'String');
%                       selectedProcessor = processors{idx};
%                 end
%                 selectedProcessorId=selectedProcessor.id();
%         end
%     end
    
end