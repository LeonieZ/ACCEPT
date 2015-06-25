classdef ui < handle
    %UI superclass to deal with basic things such as: class attributes and turning on profiling
    %or parralel processing
    
    properties
        programVersion= '0.1';
        profiler=false;
        parralelProcessing=false;
        ioHandle;
        samples;
        currentSample;
        workFlow;
        log;
        pool;
    end
    
    methods
        function self=ui()
            %constructor will be called without arguments by children. It
            %starts the logging, profiler and parralel pool when turned on.
            installDir = fileparts(which('ACTC.m'));
            self.log=logger(installDir);
            self.log.entry(['>>>> Session started <<<< actc version: ', self.programVersion],1,1);
            self.ioHandle=io(self.log,[installDir,filesep,'examples',filesep,'test_images'],[installDir,filesep,'examples',filesep,'results']);
            if self.profiler
                profile -memory on;
            end
            if self.parralelProcessing==1
                self.pool=parpool;    
            end
        end
        
        function delete(self)
            %destructor takes care of the profiler and parpool. 
            self.log.entry('>>>> Session stopped <<<< ',1,1);
            delete(self.log)
            if self.profiler
                profile off;
                profile viewer;
            end
            if self.parralelProcessing==1
                self.pool.delete()
            end
        end
        
    end
    
end

