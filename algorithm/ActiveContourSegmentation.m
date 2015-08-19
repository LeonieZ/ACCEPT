classdef ActiveContourSegmentation < WorkflowObject
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
            
            this.lambda = lambda; 
            this.breg_it = breg_it;
 
            this.inner_it = inner_it;
            this.mu_update = round(0.5*inner_it);
            
            if nargin > 3
                this.init = varargin{1};
            end
        end
        
        function returnFrame = run(this, inputFrame)
            returnFrame = inputFrame;
            returnFrame.segmentedImage = false(size(inputFrame.rawImage));
                

            if isempty(this.maskForChannels) && isempty(this.single_channel)
                this.maskForChannels = 1:1:size(inputFrame.rawImage,3);
            elseif ~isempty(this.single_channel)
                this.maskForChannels = zeros(1,size(inputFrame.rawImage,3));
                this.maskForChannels(this.single_channel) = this.single_channel;
            end
                                 
            if size(this.lambda,2) == 1
                this.lambda = repmat(this.lambda,1, size(inputFrame.rawImage,3));
            end
            
            if size(this.breg_it,2) == 1
                this.breg_it = repmat(this.breg_it,1, size(this.currentFrame,3));
            end
            
            for i = 1:size(inputFrame.rawImage,3)
                if any(this.maskForChannels == i)
                    tmp = bregman_cv(this, inputFrame, i, this.init);
                    tmp = bwareaopen(tmp, 10);
                    returnFrame.segmentedImage(:,:,i) = tmp;
                    clear grad div
                end
            end
            
            if nargin < 6
                this.segmentedFrame = this.segmentedFrame(:,:,this.maskForChannels);
            end
        end
        
        function bin = bregman_cv(this, dataFrame, k, init)
        %BREGMAN_CV Summary of this function goes here
        %   Detailed explanation goes here
        f = this.currentFrame(:,:,k);

        % dimensions
        [nx, ny] = size(f);
        dim = ndims(f);

        % initialize dual variable
        p = zeros(nx,ny,dim); % dims: nx x ny x dim, dual variable
        b = zeros(nx,ny); % dims: nx x ny , bregman variable
        
        if isempty(init)
            f_scale = f - min(f(:));
            f_scale = f_scale/max(f_scale(:));
            init(:,:,k) = f_scale;
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
        
        if dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask) 
            f(dataFrame.mask.mask) = mu0;
        end


        i = 1; j = 1;
        while i <= this.breg_it(k)
            while j <= this.inner_it

                %%% step 1 : update p according to 
                %%% p_(n+1) = (I+delta F*)^(-1)(p_n + sigma K u_bar_n)
                % update dual p
                arg1 = p + this.sigma * grad(u_bar,'lr');
                p = arg1 ./ max(1,repmat(sqrt(sum(arg1.^2,3)),[1 1 dim])); %different for aniso TV


                %%% step 2: update u according to
                %%% u_(n+1) = (I+tau G)^(-1)(u_n - tau K* p_(n+1))
                u_old = u;
                arg2 =  (u + this.tau * div(p,'lr')) - this.tau/this.lambda(k) * ((f - mu1).^2 - (f - mu0).^2 - this.lambda(k) * b);
                u = max(0, min(1,arg2));


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
                    if dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask) 
                        f(dataFrame.mask.mask) = mu0;
                    end
                end

                % update inner index
                j = j + 1;

                %plotte energiefunktional oder fehler (fehlt)
            end

            % update b (outer bregman update)
            b = b + 1/this.lambda(k) * ((f - mu0).^2 - (f - mu1).^2);


            % update outer index
            i = i + 1; j = 1;
        end
        bin = u >= 0.5;
        end
    
    end
    
end

function div_v = div(v,method)
persistent Dx_div Dy_div

N = size(v,2);
M = size(v,1);

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
    grad_u = cat(3,u*Dx_grad',Dy_grad*u);
end
end

