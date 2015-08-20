classdef Base < handle
    %UI superclass to deal with basic things such as: class attributes and turning on profiling
    %or parralel processing
    
    properties
        programVersion= 'v0.1';
        profiler=false;
        parallelProcessing=false;
        workflow=Workflow();
        log;
        pool;
    end
    
    methods
        function this=base()
            installDir = fileparts(which('ACCEPT.m'));
            %constructor will be called without arguments by children. It
            %starts the logging, profiler and parallel pool when turned on.
            this.log=logger(installDir);
            this.log.entry('',logmessage(1,['>>>> Session started <<<< actc version: ', this.programVersion]));
            
            this.workflow=workflow();
       
            %adding log listeners
            addlistener(this.workFlow,'logMessage',@this.log.entry);
            
            %show splash logo
            h=this.show_logo();
            pause(1);
            close(h);
            
            if this.profiler
                profile -memory on;
            end
            if this.parallelProcessing==1
                this.pool=parpool;    
            end
            
        end

        function h=show_logo(this)
            screen = get(0,'screensize');
            screenWidth  = screen(3);
            screenHeight = screen(4);

            im = imread('logo2.tif');
            imageWidth  = size(im,2);
            imageHeight = size(im,1);

            pos = [ceil((screenWidth-imageWidth)/2) ceil((screenHeight-imageHeight)/2) imageWidth imageHeight];

            h = figure('visible','on','menubar','none','paperpositionmode','auto','numbertitle','off','resize','off','position',pos,'name','About the ACCEPT algorithm');

            image(im);
            set(gca,'visible','off','Position',[0 0 1 1]);

            text(40,135, ['ACCEPT algorithm ',this.programVersion],'units','pixel','horizontalalignment','left','fontsize',18,'color',[.1 .1 .1]);
            text(40,105, 'Code by Leonie Zeune, Guus van Dalum & Christoph Brune','units','pixel','horizontalalignment','left','fontsize',12,'color',[.1 .1 .1]);
        end

        function delete(this)
            %destructor takes care of the profiler and parpool. 
            this.log.entry('',logmessage(1,'>>>> Session stopped <<<< '));
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

