classdef Result < handle
    % This class contains the output of a workflow. This can be the
    % measured cell features and classification. 
    properties
        features=table();
        classification=table();
        thumbnails=[];% containing the mapping of the thumbnails. 
    end
end