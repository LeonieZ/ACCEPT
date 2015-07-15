classdef activecontour_segmentation < workflow_object
    %ACTIVECONTOUR_SEGMENTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        currentFrame = [];
        segmentedFrame = [];
        lambda = [];
        inner_it = []
        breg_it = [];
        mu_update = [];
    end
    
    properties (Constant)
        sigma = 0.1; 
        tau = 0.1;
        theta = 0.5;
    end
    
    
    methods
        function self = activecontour_segmentation(dataFrame, lambda, inner_it, breg_it, varargin)
            
            if nargin > 5
                self.currentFrame = dataFrame.rawImage(:,:,varargin{2});
            else
                self.currentFrame = dataFrame.rawImage;
            end
            
         
            if size(lambda,2) == size(self.currentFrame,3)    
                self.lambda = lambda;
            elseif size(lambda,2) == 1
                self.lambda = repmat(lambda,1, size(self.currentFrame,3));
            end
            
            if size(breg_it,2) == size(self.currentFrame,3)    
                self.breg_it = breg_it;
            elseif size(breg_it,2) == 1
                self.breg_it = repmat(breg_it,1, size(self.currentFrame,3));
            end
            
            self.inner_it = inner_it;
            self.mu_update = round(0.5*inner_it);
            self.segmentedFrame = false(size(self.currentFrame));
            
            if nargin > 4
                init = varargin{1};
            else
                init = [];
            end
            
            for i = 1:size(self.currentFrame,3)
                tmp = bregman_cv(self, dataFrame, i, init);
                tmp = bwareaopen(tmp, 6);
                self.segmentedFrame(:,:,i) = tmp;
                clear grad div
            end
            
%             if dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask)
%                 self.segmentedFrame(repmat(self.mask,1,1,dataFrame.sample.numChannels)) = false;
%             end
        end
        
        function bin = bregman_cv(self, dataFrame, k, init)
        %BREGMAN_CV Summary of this function goes here
        %   Detailed explanation goes here
        f = self.currentFrame(:,:,k);

        % dimensions
        [nx, ny] = size(f);
        dim = ndims(f);

        % initialize primal variables
        u = zeros(nx,ny);
        u_bar = u; % dims: nx x ny
        % initialize dual variable
        p = zeros(nx,ny,dim); % dims: nx x ny x dim, dual variable
        b = zeros(nx,ny); % dims: nx x ny , bregman variable
        
        if isempty(init)
            f_scale = f - min(f(:));
            f_scale = f_scale/max(f_scale(:));
            init(:,:,k) = f_scale;
        end

        mu0 = max(mean(mean(f(init(:,:,k)<0.5))),0); % mean value outside object
        mu1 = max(mean(mean(f(init(:,:,k)>=0.5))),0); % mean value inside object
        if dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask) 
            f(dataFrame.mask.mask) = mu0;
        end


        i = 1; j = 1;
        while i <= self.breg_it(k)
            while j <= self.inner_it

                %%% step 1 : update p according to 
                %%% p_(n+1) = (I+delta F*)^(-1)(p_n + sigma K u_bar_n)
                % update dual p
                arg1 = p + self.sigma * grad(u_bar,'lr');
                p = arg1 ./ max(1,repmat(sqrt(sum(arg1.^2,3)),[1 1 dim])); %different for aniso TV


                %%% step 2: update u according to
                %%% u_(n+1) = (I+tau G)^(-1)(u_n - tau K* p_(n+1))
                u_old = u;
                arg2 =  (u + self.tau * div(p,'lr')) - self.tau/self.lambda(k) * ((f - mu1).^2 - (f - mu0).^2 - self.lambda(k) * b);
                u = max(0, min(1,arg2));


                %%% step 3: update u_bar according to
                %%% u_bar_(n+1) = u_(n+1)+ theta * (u_(n+1) - u_n)
                u_bar = u + self.theta * (u - u_old);


                % update mean values (mu 0 and mu1)
                if (mod(j,self.mu_update) == 0) && sum(sum((u>=0.5)))>0 && sum(sum((u<0.5)))>0
                    mu0 = max(mean(mean(f(u<0.5))),0); % mean value outside object
                    mu1 = max(mean(mean(f(u>=0.5))),0); % mean value inside object
                    if dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask) 
                        f(dataFrame.mask.mask) = mu0;
                    end
                end

                % update inner index
                j = j + 1;

                %plotte energiefunktional oder fehler (fehlt)
            end

            % update b (outer bregman update)
            b = b + 1/self.lambda(k) * ((f - mu0).^2 - (f - mu1).^2);


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

