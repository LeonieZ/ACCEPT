classdef rescore_using_gate < SampleProcessor
%CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties
        previousProcessor=SampleProcessor();
        gates=[];
    end
    
    methods 
        function this = rescore_using_gate()
            this.name = 'Rescore using gate';
            this.version = '0.1';
            this.dataframeProcessor = DataframeProcessor('FullImage_Detection', this.make_dataframe_pipeline(),'0.1');
            this.pipeline = this.make_sample_pipeline();
        end
        
        
        function outputStr = id(this) 
            [outputStr,this.previousProcessor] = this.choose_processor_to_rescore();
            this.gates=[];
        end
        
        function run(this,inputSample)
            % Catch empty gate Popup can be skipped by filling gate befor
            % run
            if isempty(this.gates)
                this.ask_for_gates();
            end
            
            if isempty(inputSample.results.features)
                %When we have nothing to gate we run the original sampleProcessor
                this.previousProcessor.run(inputSample)
            end
                %we do our gatinging
            this.pipeline{1}.run(inputSample)
            
        end
        
        function pipeline = make_sample_pipeline(this)
            pipeline = cell(0);
      
            mc = ManualClassification(cell(0),'ManualGates');
            pipeline{1} = mc;
            
        end
        
        function ask_for_gates(this)
            %create fileui popup to ask for file in which gate is stored
            gui_gates = gui_manual_gates();
            waitfor(gui_gates.fig_main,'UserData')
            res = get(gui_gates.fig_main,'UserData');
            this.gates = res.gates;
            this.pipeline{1}.gates=this.gates;
            this.pipeline{1}.name = res.name;
        end
    end
    
    methods (Static)    
        function pipeline = make_dataframe_pipeline()
            pipeline = cell(0);
            ef = ExtractFeatures();      
            pipeline{1} = [];
            pipeline{2} = ef;
        end
        
        function [selectedProcessorId,selectedProcessor] = choose_processor_to_rescore()
                d = dialog('Position',[300 300 250 150],'Name','Select a sample processor that you want to rescore');
                processors=IO.check_available_sample_processors();
                txt = uicontrol('Parent',d,...
                       'Style','text',...
                       'Position',[20 80 210 40],...
                       'String','Select a color');

                popup = uicontrol('Parent',d,...
                       'Style','popup',...
                       'Position',[75 70 100 25],...
                       'String',cellfun(@(s) s.name,processors,'UniformOutput',false),...
                       'Callback',@popup_callback);

                btn = uicontrol('Parent',d,...
                       'Position',[89 20 70 25],...
                       'String','choose',...
                       'Callback','delete(gcf)');

                selectedProcessor = processors{1};

                % Wait for d to close before running to completion
                uiwait(d);

                function popup_callback(popup,callbackdata)
                      idx = popup.Value;
                      % This code uses dot notation to get properties.
                      % Dot notation runs in R2014b and later.
                      % For R2014a and earlier:
                      % idx = get(popup,'Value');
                      % popup_items = get(popup,'String');
                      selectedProcessor = processors{idx};
                end
                selectedProcessorId=selectedProcessor.id();
        end
    end
    
end