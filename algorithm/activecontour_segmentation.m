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
        function self = activecontour_segmentation(dataFrame, lambda, inner_it, breg_it)
            self.currentFrame = dataFrame.rawImage;
            self.lambda = lambda;
            self.inner_it = inner_it;
            self.breg_it = breg_it;
            self.mu_update = round(0.5*inner_it);
            self.segmentedFrame = false(size(self.currentFrame));
                        
            for i = 1:size(self.currentFrame,3)
                self.segmentedFrame(:,:,i) = bregman_cv(self, self.currentFrame(:,:,i));
            end  
        end
        
        function bin = bregman_cv(self, img)
        %BREGMAN_CV Summary of this function goes here
        %   Detailed explanation goes here
        f = single(img);
        f_scale = f/max(f(:));
        level = graythresh(f_scale);
        BW = im2bw(f_scale,level);

        % dimensions
        [nx, ny, nz] = size(f);
        dim = ndims(f);

        % initialize primal variables
        u = zeros(nx,ny,nz);
        u_bar = u; % dims: nx x ny x nz
        % initialize dual variable
        p = zeros(nx,ny,nz,dim); % dims: nx x ny x nz x dim, dual variable
        b = zeros(nx,ny,nz); % dims: nx x ny x nz , bregman variable

        mu0 = max(mean(mean(f(BW<0.5))),0); % mean value outside object
        mu1 = max(mean(mean(f(BW>=0.5))),0); % mean value inside object
%         mu0 = max(mean(mean(f(f/max(f(:))<0.5))),0); % mean value outside object
%         mu1 = max(mean(mean(f(f/max(f(:))>=0.5))),0); % mean value inside object


        i = 1; j = 1;
        while i <= self.breg_it
            while j <= self.inner_it

                %%% step 1 : update p according to 
                %%% p_(n+1) = (I+delta F*)^(-1)(p_n + sigma K u_bar_n)
                % update dual p
                arg1 = p + self.sigma * grad(u_bar);
                p = arg1 ./ max(1,repmat(sqrt(sum(arg1.^2,4)),[1 1 1 dim])); %different for aniso TV


                %%% step 2: update u according to
                %%% u_(n+1) = (I+tau G)^(-1)(u_n - tau K* p_(n+1))
                u_old = u;
                arg2 =  (u + self.tau * div(p)) - self.tau/self.lambda * ((f - mu1).^2 - (f - mu0).^2 - self.lambda * b);
                u = max(0, min(1,arg2));


                %%% step 3: update u_bar according to
                %%% u_bar_(n+1) = u_(n+1)+ theta * (u_(n+1) - u_n)
                u_bar = u + self.theta * (u - u_old);


                % update mean values (mu 0 and mu1)
                if (mod(j,self.mu_update) == 0) && sum(sum((u>=0.5)))>0 && sum(sum((u<0.5)))>0
                    mu0 = max(mean(mean(f(u<0.5))),0); % mean value outside object
                    mu1 = max(mean(mean(f(u>=0.5))),0); % mean value inside object
                end

                % update inner index
                j = j + 1;

                %plotte energiefunktional oder fehler (fehlt)
            end

            % update b (outer bregman update)
            b = b + 1/self.lambda * ((f - mu0).^2 - (f - mu1).^2);


            % update outer index
            i = i + 1; j = 1;
        end
        bin = u >= 0.5;
        end
    
    end
    
end

function div_v = div(v)

% forward euler discretization with zero gradient boundary
% -> cf. [Chambolle - an algorithm for total variation minimization and
%    applications (2004)]
% -> !!! in 1D v should be a column vector !!!
% -> Assumption: \Omega = [0,1] x [0,1] x [0,1], i.e. spatial step sizes
%    are hx = 1 / nx, hy = 1 / ny and hz = 1 / nz
% v = input matrix (muplitple layers in 4th dimension, i.e. if v = grad_u with u 2D
% then v(:,:,:1) = grad_x_u and v(:,:,:2) = grad_y_u.)

[nx, ny, nz] = size(v);
% hx = 1/nx; hy = 1/ny; hz = 1/nz;
hx = 1; hy = 1; hz = 1;

dim = size(v,4);

div_v = hx^(-1) * cat(1, v(1,:,:,1), v(2:nx-1,:,:,1) - v(1:nx-2,:,:,1), -v(nx-1,:,:,1));
if (dim >= 2)
    div_v = div_v + hy^(-1) * cat(2, v(:,1,:,2), v(:,2:ny-1,:,2) - v(:,1:ny-2,:,2), -v(:,ny-1,:,2));
end
if (dim >= 3)
    div_v = div_v + hz^(-1) * cat(3, v(:,:,1,3), v(:,:,2:nz-1,3) - v(:,:,1:nz-2,3), -v(:,:,nz-1,3));
end
end

function grad_u = grad(u)

% forward euler discretization with zero gradient boundary
% -> cf. [Chambolle - an algorithm for total variation minimization and
%    applications (2004)]
% -> !!! in 1D u should be a column vector !!!
% -> Assumption: \Omega = [0,1] x [0,1] x [0,1], i.e. spatial step sizes
%    are hx = 1 / nx, hy = 1 / ny and hz = 1 / nz
[nx, ny, nz] = size(u);
% hx = 1/nx; hy = 1/ny; hz = 1/nz;
hx = 1; hy = 1; hz = 1;

dim = ndims(u);

grad_u(:,:,:,1) = hx^(-1) * cat(1, u(2:nx,:,:) - u(1:nx-1,:,:), zeros(1,ny,nz));
if (dim >= 2)
    grad_u(:,:,:,2) = hy^(-1) * cat(2, u(:,2:ny,:) - u(:,1:ny-1,:), zeros(nx,1,nz));
end
if (dim >= 3)
    grad_u(:,:,:,3) = hz^(-1) * cat(3, u(:,:,2:nz) - u(:,:,1:nz-1), zeros(nx,ny,1));
end
end

