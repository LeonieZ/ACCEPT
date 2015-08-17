classdef base < handle
    %UI superclass to deal with basic things such as: class attributes and turning on profiling
    %or parralel processing
    
    properties
        programVersion= 'v0.1';
        profiler=false;
        parallelProcessing=false;
        %io;
        %currentSample;
        workflow=workflow();
        log;
        pool;
    end
    
    methods
        function self=base()
            installDir = fileparts(which('ACCEPT.m'));
            %constructor will be called without arguments by children. It
            %starts the logging, profiler and parallel pool when turned on.
            self.log=logger(installDir);
            self.log.entry('',logmessage(1,['>>>> Session started <<<< actc version: ', self.programVersion]));
            
            % REMOVED
            %self.currentSample=sample();
            
            % a workflow object always deals with only one sample
            self.workflow=workflow();
           
            %adding log listeners
            %addlistener(self.io,'logMessage',@self.log.entry);
            %addlistener(self.currentSample,'logMessage',@self.log.entry);
            addlistener(self.workFlow,'logMessage',@self.log.entry);
            
            %show splash logo
            h=self.show_logo();
            pause(1);
            close(h);
            
            if self.profiler
                profile -memory on;
            end
            if self.parallelProcessing==1
                self.pool=parpool;    
            end
            
        end

        function h=show_logo(self)
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

            text(40,135, ['ACCEPT algorithm ',self.programVersion],'units','pixel','horizontalalignment','left','fontsize',18,'color',[.1 .1 .1]);
            text(40,105, 'Code by Leonie Zeune, Guus van Dalum & Christoph Brune','units','pixel','horizontalalignment','left','fontsize',12,'color',[.1 .1 .1]);
        end

        function delete(self)
            %destructor takes care of the profiler and parpool. 
            self.log.entry('',logmessage(1,'>>>> Session stopped <<<< '));
            delete(self.log)
            if self.profiler
                profile off;
                profile viewer;
            end
            if self.parallelProcessing==1
                self.pool.delete()
            end
        end
        
    end
    
end

