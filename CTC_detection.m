function [res, stat, dataP, algP] = CTC_detection(dataP, algP)

stat = [];

% param = strcat('segMethod=',func2str(algP.segMethod),'_EM=',num2str(algP.maxEMIts),'_Breg=',num2str(algP.maxBregIts),'_w=',num2str(algP.w),'_mu_v=',num2str(algP.mu_v),'_recAccur=',num2str(algP.regAccur));
param = strcat('segMethod=',func2str(algP.segMethod));
resPath = fullfile(dataP.output_folder, param);

processed_cartridges = dir(resPath);
numel_processed_cartridges = numel(processed_cartridges);
names_processed_cartridges = cell(numel_processed_cartridges,1);
% carts_to_process = [];

%%% check if cartridges are already processed
ii = 1;
while ii  <= numel_processed_cartridges
    if strcmp(processed_cartridges(ii).name, '.') || strcmp(processed_cartridges(ii).name, '..') || strcmp(processed_cartridges(ii).name, '.DS_Store')
       processed_cartridges(ii) = [];
       ii = ii-1;
       numel_processed_cartridges = numel_processed_cartridges -1;
       names_processed_cartridges(end,:) = [];
    else
       names_processed_cartridges{ii} = processed_cartridges(ii).name;
    end
    ii = ii + 1;
end

input_cartridges = dir(dataP.input_folder);
numel_input_cartridges = numel(input_cartridges);

names_input_cartridges = cell(numel_input_cartridges,1);

%%% verify if results directories are already there. If not, create directories.
ii = 1;
while ii  <= numel_input_cartridges
    if strcmp(input_cartridges(ii).name, '.') || strcmp(input_cartridges(ii).name, '..') || strcmp(input_cartridges(ii).name, '.DS_Store')
       input_cartridges(ii) = [];
       ii = ii-1;
       numel_input_cartridges = numel_input_cartridges -1;
       names_input_cartridges(end,:) = [];
    else
       names_input_cartridges{ii} = input_cartridges(ii).name;
       if ~exist([resPath filesep names_input_cartridges{ii} filesep 'measurements'], 'dir') && nargout == 0 
            mkdir([resPath filesep names_input_cartridges{ii}], 'measurements');
       end
    end
    ii = ii + 1;
   
end


%%% index to mark cartridges that are already processed
already_processed = ismember(names_input_cartridges, names_processed_cartridges);

dataP.input_catridges = struct('name', names_input_cartridges, 'already_processed', num2cell(already_processed), 'process', zeros(size(already_processed)));  

        
%%% specify which cartridges should be processed
if algP.ignore_existing_results == true
   carts_to_process = dataP.input_catridges;
else
   carts_to_process = dataP.input_catridges(already_processed == 0);
end

numel_carts_to_process = size(carts_to_process,1);
    
res = struct;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% process cartridges

if algP.profile_on == true
    profile -memory on;
end
tic;

% if algP.parallelProcessing == true
%     %%% open matlabpool for parallel processing.
%     if isempty(algP.numCores)
%         algP.numCores = feature('numCores');
%     end
%     
%     %%% get current parallel pool, without creating a new one
%     current_pool = gcp('nocreate');
%     
%     %%% open new one if necessary 
%     if isempty(current_pool)
%         parpool('local', algP.numCores);
%     elseif current_pool.NumWorkers ~= algP.numCores
%         delete(current_pool);
%         parpool('local', algP.numCores);
%     end
%     
%     %%% process single cartridges
%     parfor jj = 1:numel_carts_to_process
%         res(jj).name = carts_to_process(jj).name;
%         try 
%             [res(jj).success, res(jj).Msr] = FindAndMeasureObjects(carts_to_process(jj).name, dataP, algP);
%         catch
%             res(jj).success = 'FindAndMeasureObjects failed';
%         end
%     end
%     
%     %%% close matlabpool
%     delete(gcp('nocreate')) 
%     
% else
    for jj = 1:numel_carts_to_process
        res.name = carts_to_process(jj).name;
        [res.success, res.Msr] = FindAndMeasureObjects(carts_to_process(jj).name, dataP, algP);
        
        if algP.processXML == true
            [res.success, res.Msr, res.xml] = processXML(fullfile(dataP.input_folder, carts_to_process(jj).name), res);
        end

        if algP.classify == true
            [res.success, res.Msr] = classification(res);
        end

        %%% save results and statistics as mat file
        if nargout == 0
            %%% create string with current date and time as result filename
            resFileName = datestr(now, 'yyyy_mmmm_dd'); 
            save(fullfile([resPath filesep res.name filesep 'measurements'],strcat(resFileName,'.mat')),'algP', 'dataP','res','stat');
        end
    end
% end

toc;
if algP.profile_on == true
    profile off;
    profile viewer;
end

end % function CTC_detection
