classdef Result < handle
    % This class contains the output of a workflow. This can be the
    % measured cell features and classification. 
    properties
        features=table();
        classification=table();
        thumbnails=table();% containing the mapping of the thumbnails. 
        thumbnail_images = cell(0); %delete later
        segmentation = cell(0); %delete later
        scoring_results = struct('name',[],'institute',[],'scores',cell(0),'quality_scores',cell(0));
    end
end