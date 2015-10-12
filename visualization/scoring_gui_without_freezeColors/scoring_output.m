classdef scoring_output
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        scores = [];
        contact = [];
        path = [];
        name = [];
    end
    
    methods
        function self = scoring_output(scr, cntc, varargin)
            if nargin == 2
                self.scores = scr;
                self.contact = cntc;
                date = datestr(now, 'yyyy_mmmm_dd'); 
                self.name = ['results_', date, '.mat'];
            elseif nargin == 3
                self.scores = scr;
                self.contact = cntc;
                date = datestr(now, 'yyyy_mmmm_dd_HH_MM_SS'); 
                self.name = ['results_',varargin{1},'_', date, '.mat'];
            end
        end
        
        function self = update_scores (self,scr)
            self.scores = scr;
            
            if isempty(self.path)
                self.path = pwd;
            end
            
            if exist([self.path filesep self.name],'file')
                m = matfile([self.path filesep self.name],'Writable',true);
                res = m.res;
                res.scores = self.scores;
                m.res = res;
            end
        end
        
        function save_res(self,varargin)
            if nargin == 1
                self.path = pwd;
            else
                self.path = varargin{1};
            end
                
            res.scores = self.scores;
            res.contact = self.contact;
            
            save([self.path filesep self.name], 'res');
        end
    end
    
end

