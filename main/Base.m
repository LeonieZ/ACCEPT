classdef Base < handle
    %UI superclass to deal with basic things such as: class attributes and turning on profiling
    %or parralel processing
    
    properties
        programVersion= '1.0.0-beta';
        sampleList = SampleList();
        sampleProcessor = SampleProcessor();
        availableSampleProcessors = {};
        profiler = false;
        parallelProcessing = false;
        logger;
        pool;
        busy;
        progress;
        nrProcessed;
    end
    
    events
        updateProgress;
    end
    
    methods
        function this = Base()
            % Constructor will be called without arguments by the main script.
            % It starts filling the sampleList, the logging and turn on the 
            % profiler or parallel pool when turned on with the variables above
            
             % find the directory in which ACCEPT is installed
            installDir = fileparts(which('ACCEPT.m'));
            
            % Create logger
            this.logger = Logger(installDir);
            this.logger.entry(this,LogMessage(1,['>>>> Session started <<<< ACCEPT version: ', this.programVersion]));
          
            % Search for available SampleProcessors and populate the list.
            this.availableSampleProcessors=IO.check_available_sample_processors();
            
            % Create an empty SampleList
            this.sampleList=SampleList();
            
            % Turn on profiler and parallel pool when needed.
            if this.profiler
                profile on;
            end
            if this.parallelProcessing == true
                this.pool=parpool;    
            end
            
            % adding log listeners
            addlistener(this.sampleList,'logMessage',@(src,event)this.logger.entry(src,event));
            
            % add progress listener
        end
        
        function run(this)
            % run SampleProcessor with each sample marked as toBeProcessed
            this.busy=true;
            nbrSamples = size(this.sampleList.toBeProcessed,2);
            this.nrProcessed = 0;
            if ~isa(this.sampleProcessor,'Rescore_Using_Gate')
                if ~isempty(find(this.sampleList.isProcessed(find(this.sampleList.toBeProcessed))))  %#ok<EFIND,FNDSB>
                    set(0,'defaultUicontrolFontSize', 14)
                    choice = questdlg('Some selected samples are already processed. Do you want to process them again?', ...
                                    'Processed Sample', 'Yes','No','No');
                    set(0,'defaultUicontrolFontSize', 12)
                else
                    choice = 'No';
                end
                if strcmp(choice,'No')
                    this.sampleList.toBeProcessed(this.sampleList.isProcessed)= false;
                end
            end
            for k=1:nbrSamples
                if this.sampleList.toBeProcessed(k)
                    try 
                        sample = IO.load_sample(this.sampleList,k);
                        if ~isa(this.sampleProcessor,'Rescore_Using_Gate')
                            sample.results=Result(); 
                        end
                        this.logger.entry(this,LogMessage(2,['Processing sample ',sample.id ,'...']));
                        this.sampleProcessor.run(sample);
                        IO.save_sample(sample);
                        IO.save_results_as_xls(sample);
                        this.logger.entry(this,LogMessage(2,['Sample ',sample.id ,' is processed.']));
                        this.nrProcessed = this.nrProcessed + 1;
                        this.update_progress();
                    catch
                        this.logger.entry(this,LogMessage(2,['Sample NR',num2str(k) ,' failed to load']));
                    end
                end
            end
            if this.profiler
                profile viewer
            end
            this.busy=false;
        end
        
        function update_progress(this)
        % Update the progress variable. 
        this.progress = this.nrProcessed / sum(this.sampleList.toBeProcessed);
        notify(this,'updateProgress')
        end
                
        function h=save_splash(this)
            screen = get(0,'screensize');
            screenWidth  = screen(3);
            screenHeight = screen(4);

            im = imread('splashSource.tif');
            imageWidth  = size(im,2);
            imageHeight = size(im,1);

            pos = [ceil((screenWidth-imageWidth)/2) ceil((screenHeight-imageHeight)/2) imageWidth imageHeight];

            h = figure('visible','on','menubar','none','paperpositionmode','auto','numbertitle','off','resize','off','position',pos,'name','About the ACCEPT algorithm');

            image(im);
            set(gca,'visible','off','Position',[0 0 1 1]);

            text(40,135, ['ACCEPT algorithm ',this.programVersion],'units','pixel','horizontalalignment','left','fontsize',18,'color',[.1 .1 .1]);
            text(40,105, 'Code by Leonie Zeune, Guus van Dalum & Christoph Brune','units','pixel','horizontalalignment','left','fontsize',12,'color',[.1 .1 .1]);
            set(h,'PaperPositionMode','auto')
            print -dtiff -r300 splash;
        end
        
        function save_state(this)
            file = which('ACCEPT.m');
            installDir = fileparts(file);
            inputPath = this.sampleList.inputPath;
            resultPath = this.sampleList.resultPath;
            processor = this.sampleProcessor.name;
            save([installDir,filesep,'input_output',filesep,'LatestSettings.mat'],'inputPath','resultPath','processor');
            this.delete;
        end

        function delete(this)
            %destructor takes care of the profiler and parpool. 
            this.logger.entry(this,LogMessage(1,'>>>> Session stopped <<<< '));
            delete(this.logger);
            delete(this.sampleList);
            delete(this.sampleProcessor);
            if this.profiler
                profile off;
                profile viewer;
            end
            if this.parallelProcessing==1
                this.pool.delete()
            end
        end
        
    end
    
end

