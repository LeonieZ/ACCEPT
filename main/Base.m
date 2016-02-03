classdef Base < handle
    %UI superclass to deal with basic things such as: class attributes and turning on profiling
    %or parralel processing
    
    properties
        programVersion= '1.0.0-beta';
        sampleList;
        sampleProcessor;
        availableSampleProcessors;
        io;
        profiler=false;
        parallelProcessing=false;
        busy=false;
        log;
        pool;
    end
    
    methods
        function this = Base()
            this.io = IO();
            this.sampleList=this.io.create_sample_list();
            
            % search for available SampleProcessors
            tmp = what('sampleProcessors');
            this.availableSampleProcessors = tmp.m;
            
            installDir = fileparts(which('ACCEPT.m'));
            %constructor will be called without arguments by children. It
            %starts the logging, profiler and parallel pool when turned on.
            this.log=Logger(installDir);
            this.log.entry('',LogMessage(1,['>>>> Session started <<<< ACCEPT version: ', this.programVersion]));
              
            %adding log listeners
            %addlistener(this.workflow,'logMessage',@this.log.entry);
            
            if this.profiler
                profile -memory on;
            end
            if this.parallelProcessing==1
                this.pool=parpool;    
            end
            
        end
        
        function run(this)
            % run SampleProcessor with each sample marked as toBeProcessed
            this.busy=true;
            nbrSamples = size(this.sampleList.toBeProcessed,2);
            
            wbar = waitbar(0,'Please wait...');
            nrProcessed = 0;
            for k=1:nbrSamples
                if this.sampleList.toBeProcessed(k) == 1
                    wbar_fraction = nrProcessed / sum(this.sampleList.toBeProcessed);
                    waitbar(wbar_fraction,wbar,'Please wait...')
                    if this.sampleList.isProcessed(k) == 0
                        sample = this.io.load_sample(this.sampleList,k);
                        waitbar(wbar_fraction,wbar,['Please wait... Sample ' sample.id ' is being processed.'])
                        disp(['Processing sample ',sample.id ,'...']);
                        this.sampleProcessor.run(sample);
                        this.io.save_sample(sample);
                        disp(['Sample ',sample.id ,' is processed.']);
                    else
                        choice = questdlg(strcat('Sample ', this.sampleList.sampleNames(k) ,' is already processed. Do you want to process it again?'), ...
                                'Processed Sample', 'Yes','No','No');
                            % Handle response
                            switch choice
                                case 'Yes'
                                    sample = this.io.load_sample(this.sampleList,k);
                                    sample.results=Result(); 
                                    waitbar(wbar_fraction,wbar,['Please wait... Sample ' sample.id ' is being processed.'])
                                    disp(['Processing sample ',sample.id ,'...']);
                                    this.sampleProcessor.run(sample);
                                    this.io.save_sample(sample);
                                    disp(['Sample ',sample.id ,' is processed.']);  
                                case 'No'
                                   % break
                            end   
                    end
                    nrProcessed = nrProcessed + 1;
                end
            end
            this.busy=false;
            close(wbar)
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

        function delete(this)
            %destructor takes care of the profiler and parpool. 
            this.log.entry('',LogMessage(1,'>>>> Session stopped <<<< '));
            delete(this.log)
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

