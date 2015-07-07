classdef ui < handle
    %UI superclass to deal with basic things such as: class attributes and turning on profiling
    %or parralel processing
    
    properties
        programVersion= '0.1';
        profiler=false;
        parallelProcessing=false;
        ioHandle;
        currentSample;
        workFlow;
        log;
        pool;
    end
    
    methods
        function self=ui()
            %constructor will be called without arguments by children. It
            %starts the logging, profiler and parallel pool when turned on.
            installDir = fileparts(which('ACTC.m'));
            self.log=logger(installDir);
            self.log.entry('',logmessage(1,['>>>> Session started <<<< actc version: ', self.programVersion]));
            self.ioHandle=io([installDir,filesep,'examples',filesep,'test_images'],[installDir,filesep,'examples',filesep,'results']);
            self.currentSample=sample();
            self.workFlow=workflow();
            %adding log listeners
            addlistener(self.ioHandle,'logMessage',@self.log.entry);
            addlistener(self.currentSample,'logMessage',@self.log.entry);
            addlistener(self.workFlow,'logMessage',@self.log.entry);
            
            if self.profiler
                profile -memory on;
            end
            if self.parallelProcessing==1
                self.pool=parpool;    
            end
            
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

