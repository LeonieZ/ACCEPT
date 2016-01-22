classdef ActiveContourSegmentation < DataframeProcessorObject
    %ACTIVECONTOUR_SEGMENTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        maskForChannels = [];
        lambda = [];
        inner_it = []
        breg_it = [];
        mu_update = [];
        single_channel = [];
        init = [];
        adaptive_reg = 0;
    end
    
    properties
        clear_border = 0;
    end
    
    properties (Constant)
        sigma = 0.1; 
        tau = 0.1;
        theta = 0.5;
    end
    
    
    methods
        function this = ActiveContourSegmentation(lambda, inner_it, breg_it, varargin)
            %varargin(1) = init, varargin(2) = masksforchannels,
            %varargin(3) = single_channel

            if nargin > 5
                this.single_channel = varargin{3};
            end
                        
            if nargin > 4 && ~isempty(varargin{2})
                this.maskForChannels = varargin{2};
            end
            
            
            if isa(lambda,'numeric')
                this.lambda = lambda;
            elseif strcmp(lambda,'adaptive')
                this.lambda = 0.01;
                this.adaptive_reg = 1;
            end

            this.breg_it = breg_it;
 
            this.inner_it = inner_it;
%             this.mu_update = round(0.5*inner_it);
            this.mu_update = inner_it+1;
            
            
            if nargin > 3
                this.init = varargin{1};
            end
        end
        
        function returnFrame = run(this, inputFrame)
            if isa(inputFrame,'Dataframe')
                returnFrame = inputFrame;
                returnFrame.segmentedImage = false(size(inputFrame.rawImage));


                if isempty(this.maskForChannels) && isempty(this.single_channel)
                    this.maskForChannels = 1:1:inputFrame.nrChannels;
                elseif ~isempty(this.single_channel)
                    this.maskForChannels = zeros(1,inputFrame.nrChannels);
                    this.maskForChannels(this.single_channel) = this.single_channel;
                end

                if size(this.lambda,2) == 1
                    this.lambda = repmat(this.lambda,1, inputFrame.nrChannels);
                end

                if size(this.breg_it,2) == 1
                    this.breg_it = repmat(this.breg_it,1, inputFrame.nrChannels);
                end
                
                if ~isempty(this.init) 
                    if isa(this.init,'double') || isa(this.init,'logical')
                        cvInit = this.init;
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && isa(this.init{2},'char')
                        validatestring(this.init{1},{'otsu','triangle'});
                        validatestring(this.init{2},{'global','local'});
                        if strcmp(this.init{2},'local')
                            threshSeg = ThresholdingSegmentation(this.init{1},'local',[],this.maskForChannels);
                        elseif strcmp(this.init{2},'global') && ~isempty(this.init{3})
                            threshSeg = ThresholdingSegmentation(this.init{1},'global',this.init{3},this.maskForChannels);
                        end
                        cvInit = threshSeg.run(inputFrame.rawImage);
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && strcmp(this.init{1},'manual')
                        manualSeg = ThresholdingSegmentation('manual','local',[],[],[],this.init{2});
                        cvInit = manualSeg.run(inputFrame.rawImage);
                    else
                        cvInit = [];
                    end
                else
                    cvInit = [];
                end
               

                for i = 1:inputFrame.nrChannels
                    if any(this.maskForChannels == i)
                        tmp = bregman_cv(this, inputFrame, i, cvInit);
                        tmp = bwareaopen(tmp, 10);
                        returnFrame.segmentedImage(:,:,i) = tmp;
                    end
                end

                if isempty(this.single_channel) && isa(inputFrame,'Dataframe')
                    returnFrame.segmentedImage = returnFrame.segmentedImage(:,:,this.maskForChannels);
                end

            elseif isa(inputFrame,'double')
                returnFrame = false(size(inputFrame));

                if isempty(this.maskForChannels) && isempty(this.single_channel)
                    this.maskForChannels = 1:1:size(inputFrame,3);
                elseif ~isempty(this.single_channel)
                    this.maskForChannels = zeros(1,size(inputFrame,3));
                    this.maskForChannels(this.single_channel) = this.single_channel;
                end

                if size(this.lambda,2) == 1
                    this.lambda = repmat(this.lambda,1,size(inputFrame,3));
                end

                if size(this.breg_it,2) == 1
                    this.breg_it = repmat(this.breg_it,1,size(inputFrame,3));
                end
                
                if ~isempty(this.init) 
                    if isa(this.init,'double') || isa(this.init,'logical')
                        cvInit = this.init;
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && isa(this.init{2},'char')
                        validatestring(this.init{1},{'otsu','triangle'});
                        validatestring(this.init{2},{'global','local'});
                        if strcmp(this.init{2},'local')
                            threshSeg = ThresholdingSegmentation(this.init{1},'local',[],this.maskForChannels);
                        elseif strcmp(this.init{2},'global') && ~isempty(this.init{3})
                            threshSeg = ThresholdingSegmentation(this.init{1},'global',this.init{3},this.maskForChannels);
                        end
                        cvInit = threshSeg.run(inputFrame);
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && strcmp(this.init{1},'manual')
                        manualSeg = ThresholdingSegmentation('manual','local',[],[],[],this.init{2});
                        cvInit = manualSeg.run(inputFrame);
                    else
                        cvInit = [];
                    end
                else
                    cvInit = [];
                end

                for i = 1:size(inputFrame,3)
                    if any(this.maskForChannels == i)
                        tmp = bregman_cv(this, inputFrame, i, cvInit);
                        tmp = bwareaopen(tmp, 10);
                        returnFrame(:,:,i) = tmp;
                    end
                end

                if isempty(this.single_channel)
                    returnFrame = returnFrame(:,:,this.maskForChannels);
                end
                
            else
                error('Active Contour Segmentation can only be used on dataframes or double images.')
            end
        end
        
        function bin = bregman_cv(this, dataFrame, k, init)
        %BREGMAN_CV Summary of this function goes here
        %   Detailed explanation goes here
        if isa(dataFrame,'Dataframe')
            f = dataFrame.rawImage(:,:,k);
        elseif isa(dataFrame,'double')
            f = dataFrame;
        end
        

        
        % set lambda
        lambda_reg = this.lambda(k);
        
        % dimensions
        [nx, ny] = size(f);
        dim = ndims(f);
        
        %scale data f    
        f = f-min(f(:)); f = f/max(f(:));
        
        
        % initialize dual variable
        p = zeros(nx,ny,dim); % dims: nx x ny x dim, dual variable
        b = zeros(nx,ny); % dims: nx x ny , bregman variable
        
        if isempty(init)
            init(:,:,k) = f;
            % initialize primal variables
            u = zeros(nx,ny);
            u_bar = u; % dims: nx x ny
        else
            % initialize primal variables
            u = init(:,:,k);
            u_bar = u; % dims: nx x ny
        end
        
        if max(max((init(:,:,k)<0.5))) == 1 && max(max((init(:,:,k)>=0.5))) == 1
            mu0 = max(mean(mean(f(init(:,:,k)<0.5))),0); % mean value outside object
            mu1 = max(mean(mean(f(init(:,:,k)>=0.5))),0); % mean value inside object
        elseif max(max((init(:,:,k)<0.5))) == 0
            mu0 = min(f(:));
            mu1 = mean(mean(f(init(:,:,k)>=0.5)));
        elseif max(max((init(:,:,k)>=0.5))) == 0
            mu0 = mean(mean(f(init(:,:,k)<0.5)));
            mu1 = max(f(:));
        end
        
        if isa(dataFrame,'Dataframe') && dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask) 
            f(dataFrame.mask) = mu0;
        end %note: in case you are using the AC function on a double image using a mask is not possible

        tol = 1e-9;
        
        i = 1; j = 1;
        for l = 1:20
            while i <= this.breg_it(k)
                stat_u = []; 
                while j <= this.inner_it && (isempty(stat_u) || ~isempty(stat_u) && stat_u(end) >= tol) 
                    %%% step 1 : update p according to 
                    %%% p_(n+1) = (I+delta F*)^(-1)(p_n + sigma K u_bar_n)
                    % update dual p
                    arg1 = p + this.sigma * grad(u_bar,'shift');
                    p = arg1 ./ max(1,repmat(sqrt(sum(arg1.^2,3)),[1 1 dim])); %different for aniso TV


                    %%% step 2: update u according to
                    %%% u_(n+1) = (I+tau G)^(-1)(u_n - tau K* p_(n+1))
                    u_old = u;
                    arg2 =  (u + this.tau * div(p,'shift')) - this.tau/lambda_reg * ((f - mu1).^2 - (f - mu0).^2 - lambda_reg * b);
                    u = max(0, min(1,arg2));
                    stat_u(j) = (nx*ny)^(-1) * (sum((u(:) - u_old(:)).^2)/sum(u_old(:).^2));         



                    %%% step 3: update u_bar according to
                    %%% u_bar_(n+1) = u_(n+1)+ theta * (u_(n+1) - u_n)
                    u_bar = u + this.theta * (u - u_old);


                    % update mean values (mu 0 and mu1)
                    if (mod(j,this.mu_update) == 0) % && sum(sum((u>=0.5)))>0 && sum(sum((u<0.5)))>0
                        if max(max((init(:,:,k)<0.5))) == 1 && max(max((init(:,:,k)>=0.5))) == 1
                            mu0 = max(mean(mean(f(init(:,:,k)<0.5))),0); % mean value outside object
                            mu1 = max(mean(mean(f(init(:,:,k)>=0.5))),0); % mean value inside object
                        elseif max(max((init(:,:,k)<0.5))) == 0
                            mu0 = min(f(:));
                            mu1 = mean(mean(f(init(:,:,k)>=0.5)));
                        elseif max(max((init(:,:,k)>=0.5))) == 0
                            mu0 = mean(mean(f(init(:,:,k)<0.5)));
                            mu1 = max(f(:));
                        end
                        if isa(dataFrame,'Dataframe')&& dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask) 
                            f(dataFrame.mask) = mu0;
                        end
                    end

                    % update inner index
                    j = j + 1;

                end

                % update b (outer bregman update)
                b = b + 1/lambda_reg * ((f - mu0).^2 - (f - mu1).^2);

                % update outer index
                i = i + 1; j = 1;
            end
         
            bin = u >= 0.5;
            
%             bin = imclearborder(bin);
            
            if this.adaptive_reg == 1
                stats = regionprops(bin,'Solidity','Eccentricity','PixelIdxList');
                go_on = 0;

                for s = 1:size(stats,1)
                    if size(stats(s).PixelIdxList,1) < 10 || stats(s).Eccentricity > 0.95
                        bin(stats(s).PixelIdxList) = 0;
                    end
                    if stats(s).Solidity < 0.95
                        go_on = 1;
                    end
                end
                
                if go_on == 1
                    D = bwdist(~bin);
                    D = -D;
                    D(~bin) = -Inf;
                    L = watershed(D);

                    bin(L <= 1) = 0;
                    bin(L > 1) = 1;
                    stats = regionprops(bin,'Solidity','Eccentricity','PixelIdxList');
                    go_on = 0;

                    for s = 1:size(stats,1)
                        if size(stats(s).PixelIdxList,1) < 10 || stats(s).Eccentricity > 0.95
                            bin(stats(s).PixelIdxList) = 0;
                        end
                        if stats(s).Solidity < 0.95
                            go_on = 1;
                        end
                    end
                end
                    

                if go_on == 1
                    i = 1; j = 1;
                    lambda_reg = lambda_reg + 0.05;
                    p = zeros(nx,ny,dim); % dims: nx x ny x dim, dual variable
                    b = zeros(nx,ny); % dims: nx x ny , bregman variable

                    if isempty(init)
                        init(:,:,k) = f;
        %                initialize primal variables
                        u = zeros(nx,ny);
                        u_bar = u; % dims: nx x ny
                    else
        %                initialize primal variables
                        u = init(:,:,k);
                        u_bar = u; % dims: nx x ny
                    end
                else
                    break
                end   
            else
                break
            end
        end
        if this.clear_border
            bin = imclearborder(bin);
        end
        end   
    end
    
end

function div_v = div(v,method)
persistent Dx_div Dy_div

N = size(v,2);
M = size(v,1);

if size(Dx_div,1) ~= N || size(Dy_div,1) ~= M
    Dx_div = [];
    Dy_div = [];
end

if isempty(Dx_div) && strcmp(method,'lr')
    Dx_div = spdiags([-ones(N,1) ones(N,1)],[0 1],N,N); Dx_div(N,:) = 0;
    Dy_div = spdiags([-ones(M,1) ones(M,1)],[0 1],M,M); Dy_div(M,:) = 0;
end

if strcmp(method,'shift')
    v = single(v);
    % forward euler discretization with zero gradient boundary
    % -> cf. [Chambolle - an algorithm for total variation minimization and
    %    applications (2004)]
    % -> !!! in 1D v should be a column vector !!!
    % -> Assumption: \Omega = [0,1] x [0,1] x [0,1], i.e. spatial step sizes
    %    are hx = 1 / nx, hy = 1 / ny and hz = 1 / nz
    % v = input matrix (muplitple layers in 4th dimension, i.e. if v = grad_u with u 2D
    % then v(:,:,:1) = grad_x_u and v(:,:,:2) = grad_y_u.)

    [nx, ny, ~] = size(v);
    % hx = 1/nx; hy = 1/ny; hz = 1/nz;
    hx = 1; hy = 1;

    div_v = hx^(-1) * cat(1, v(1,:,1), v(2:nx-1,:,1) - v(1:nx-2,:,1), -v(nx-1,:,1));
    div_v = div_v + hy^(-1) * cat(2, v(:,1,2), v(:,2:ny-1,2) - v(:,1:ny-2,2), -v(:,ny-1,2));
elseif strcmp(method,'lr')
    %% GRAD DIV, left-right definition
    % (FASTEST, but only works for double images, since no sparse single arrays available)
    div_v = v(:,:,1)*Dx_div + Dy_div'*v(:,:,2);
end
end

function grad_u = grad(u,method)
persistent Dx_grad Dy_grad

N = size(u,2);
M = size(u,1);
if size(Dx_grad,1) ~= N || size(Dy_grad,1) ~= M
    Dx_grad = [];
    Dy_grad = [];
end

if isempty(Dx_grad) && strcmp(method,'lr')
    Dx_grad = spdiags([-ones(N,1) ones(N,1)],[0 1],N,N); Dx_grad(N,:) = 0;
    Dy_grad = spdiags([-ones(M,1) ones(M,1)],[0 1],M,M); Dy_grad(M,:) = 0;
end

if strcmp(method,'shift')
    u = single(u);
    % forward euler discretization with zero gradient boundary
    % -> cf. [Chambolle - an algorithm for total variation minimization and
    %    applications (2004)]
    % -> !!! in 1D u should be a column vector !!!
    % -> Assumption: \Omega = [0,1] x [0,1] x [0,1], i.e. spatial step sizes
    %    are hx = 1 / nx, hy = 1 / ny and hz = 1 / nz
    [nx, ny] = size(u);
    % hx = 1/nx; hy = 1/ny; hz = 1/nz;
    hx = 1; hy = 1;

    grad_u(:,:,1) = hx^(-1) * cat(1, u(2:nx,:) - u(1:nx-1,:), zeros(1,ny));
    grad_u(:,:,2) = hy^(-1) * cat(2, u(:,2:ny) - u(:,1:ny-1), zeros(nx,1));
elseif strcmp(method,'lr')
    %% GRAD DIV, left-right definition
    % (FASTEST, but only works for double images, since no sparse single arrays available) 
    if issparse(u*Dx_grad') || issparse(Dy_grad*u)
        grad_u = cat(3,full(u*Dx_grad'),full(Dy_grad*u));
    else 
        grad_u = cat(3,u*Dx_grad',Dy_grad*u);
    end
end
end

