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
%             this.mu_update = inner_it+1;
            
            
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
                
%                 [nx, ny,~] = size(inputFrame.rawImage);
%                 mean_im = sum(sum(inputFrame.rawImage,1),2)./(nx*ny);
%                 var_im = sum(sum((inputFrame.rawImage-repmat(mean_im,[nx ny 1])).^2,1),2)./(nx*ny);
%                 contrast_im = max(max(inputFrame.rawImage))-min(min(inputFrame.rawImage));
%                 ratio_im = var_im./contrast_im;
% %                 ratio_im = var_im./mean_im;
%                 grad1 = grad(inputFrame.rawImage(:,:,1),'lr');
%                 grad2 = grad(inputFrame.rawImage(:,:,2),'lr');
%                 grad3 = grad(inputFrame.rawImage(:,:,3),'lr');
%                 grad4 = grad(inputFrame.rawImage(:,:,4),'lr');
%                 grad1_x = norm(grad1(:,:,1));grad1_y = norm(grad1(:,:,2)); grad1_ratio = grad1_x/grad1_y;
%                 grad2_x = norm(grad2(:,:,1));grad2_y = norm(grad2(:,:,2)); grad2_ratio = grad2_x/grad2_y;
%                 grad3_x = norm(grad3(:,:,1));grad3_y = norm(grad3(:,:,2)); grad3_ratio = grad3_x/grad3_y;
%                 grad4_x = norm(grad4(:,:,1));grad4_y = norm(grad4(:,:,2)); grad4_ratio = grad4_x/grad4_y;
%                 table_mean_var = table(mean_im(:,:,1),mean_im(:,:,2),mean_im(:,:,3),mean_im(:,:,4),var_im(:,:,1),var_im(:,:,2),var_im(:,:,3),var_im(:,:,4),...
%                     contrast_im(:,:,1),contrast_im(:,:,2),contrast_im(:,:,3),contrast_im(:,:,4),ratio_im(:,:,1),ratio_im(:,:,2),ratio_im(:,:,3),ratio_im(:,:,4),...
%                     grad1_ratio, grad2_ratio, grad3_ratio,grad4_ratio,...
%                     'VariableNames',{'Mean1' 'Mean2' 'Mean3' 'Mean4' 'Var1' 'Var2' 'Var3' 'Var4' 'Contrast1' 'Contrast2' 'Contrast3' 'Contrast4' 'Ratio1' 'Ratio2' 'Ratio3' 'Ratio4' 'GradRatio1' 'GradRatio2' 'GradRatio3' 'GradRatio4'});
%                 
%                 mfile = matfile('test_table.mat','Writable',true);
%                 mfile.table_mean_var = [mfile.table_mean_var;table_mean_var];

                %for i = 1:inputFrame.nrChannels
                for i = 1:4
                    if any(this.maskForChannels == i)
                        tmp = bregman_cv(this, inputFrame, i, cvInit);
                        tmp = bwareaopen(tmp, 10);
                        returnFrame.segmentedImage(:,:,i) = tmp;
                    end
                end
%                   icy_im3show(returnFrame.rawImage);icy_im3show(returnFrame.segmentedImage);

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
        

        % dimensions
        [nx, ny] = size(f);
        dim = ndims(f);
        
%         mean_im = sum(sum(f,1),2)./(nx*ny)
%         var_im = sum(sum((f-ones(nx,ny)*mean_im).^2,1),2)./(nx*ny)
%         contrast_im = max(max(f))-min(min(f))
%         ratio_im = var_im./contrast_im
%         grad_im = grad(f,'shift');
%         grad_x = norm(grad_im(:,:,1));grad_y = norm(grad_im(:,:,2)); grad_ratio = grad_y/grad_x;
%         this.lambda(k) = this.lambda(k)*grad_ratio;
            
        f = f-min(f(:)); f = f/max(f(:));
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
        
        if isa(dataFrame,'Dataframe') && dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask) 
            f(dataFrame.mask) = mu0;
        end %note: in case you are using the AC function on a double image using a mask is not possible

        u_ges = zeros(nx,ny,1,1,this.breg_it(k));
        J_ges = zeros(this.breg_it(k));
        b_ges = zeros(nx,ny,1,1,this.breg_it(k));
        tol = 1e-9;
        
        i = 1; j = 1;
        lambda_test = linspace(0.1,1,20);
        this.lambda(k) = 0.05;
        for l = 1:length(lambda_test)
            %this.lambda(k) = lambda_test(l);
            p = zeros(nx,ny,dim); % dims: nx x ny x dim, dual variable
            b = zeros(nx,ny); % dims: nx x ny , bregman variable

            if isempty(init)
                f_scale = f - min(f(:));
                f_scale = f_scale/max(f_scale(:));
                init(:,:,k) = f_scale;
%                initialize primal variables
                u = zeros(nx,ny);
                u_bar = u; % dims: nx x ny
            else
%                initialize primal variables
                u = init(:,:,k);
                u_bar = u; % dims: nx x ny
            end

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
                    arg2 =  (u + this.tau * div(p,'shift')) - this.tau/this.lambda(k) * ((f - mu1).^2 - (f - mu0).^2 - this.lambda(k) * b);
                    u = max(0, min(1,arg2));
                    stat_u(j) = (nx*ny)^(-1) * sum(sum(sum((u - u_old).^2)));         



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

                    %plotte energiefunktional oder fehler (fehlt)
                end

                % update b (outer bregman update)
                b = b + 1/this.lambda(k) * ((f - mu0).^2 - (f - mu1).^2);

                % store every result
                u_ges(:,:,:,1,l*i) = u > 0.5;
%                 p_ges(:,:,:,1,l*i) = p;
%                 mu0_ges(l*i) = mu0;
%                 mu1_ges(l*i) = mu1;
%                 J_ges(l*i) = sum(sum(u_ges(:,:,:,1,l*i).*((f-mu1).^2-(f-mu0).^2))) + this.lambda(k)*sum(sum(sqrt(sum(p.^2,3))));
%                 J_ges(l*i) = sum(sum(u_ges(:,:,:,1,l*i).*((f-mu1).^2-(f-mu0).^2))) + sum(sum(sqrt(sum(p.^2,3))));
%                 D_ges(l*i) = sum(sum(u_ges(:,:,:,1,l*i).*((f-mu1).^2-(f-mu0).^2)));
                R_ges(l*i) = sum(sum(sqrt(sum(grad(u_ges(:,:,:,1,l*i),'shift').^2,3))));
                b_ges(:,:,:,1,i) = b;


                % update outer index
                i = i + 1; j = 1;
            end
            if l > 1 && sum(sum(u_ges(:,:,:,1,l-1))) == 0
                break
            end
            i = 1; j = 1;
            bin = u >= 0.5;
            CC = bwconncomp(bin,8);
            
            %if CC.NumObjects > 1
                bin = imclearborder(bin);
            %end
            
            stats = regionprops(bin,'Solidity','Eccentricity','PixelIdxList');
            go_on = 0;
            for s = 1:size(stats,1)
                if size(stats(s).PixelIdxList,1) < 10 || stats(s).Eccentricity > 0.95
                    bin(stats(s).PixelIdxList) = 0;
                end
                if stats(s).Solidity < 0.9
                    go_on = 1;
                end
            end            
%             CH = bwconvhull(bin, 'objects', 8);
            
            
            if go_on == 1
                this.lambda(k) = this.lambda(k) + 0.05;
            else
                break
            end
        end
        
        
        
%         if this.breg_it(k) > 2
%             % compute spectral response function
%             S = zeros(1,this.breg_it(k)); 
%             Du = zeros(size(f,1),size(f,2),this.breg_it(k));
%             for j=1:this.breg_it(k)
%                 % compute spectral response
%                 if j == 1
%                     u1=u_ges(:,:,:,1,j);
%                     u0=u1;
%                 else
%                     u0=u_ges(:,:,:,1,j-1);
%                     u1=u_ges(:,:,:,1,j);
%                 end
%                 du = (u1-u0);
%                 Du(:,:,j) = du;
%                 S(j) = sum(abs(du(:)));
%             end 
% %             figure(this.breg_it(k)+1); plot(S(2:end-1));
% %             axis on
%             k_max = find(S == max(S),1,'first');
%             if S(k_max) >= 5
%                 bin = sum(Du(:,:,1:min(k_max+1,this.breg_it(k))),3);
%             else
%                 bin = zeros(nx,ny);
%             end
%         else
% %             R_ges = R_ges-min(R_ges);
% %             R_ges = R_ges/max(R_ges);
% %             D_ges = D_ges-min(D_ges);
% %             D_ges = abs(D_ges/max(D_ges)-1);
%             residual = R_ges - abs(D_ges);
%             J_ges = R_ges + D_ges;
% %             residual = residual/max(residual);
%             R_der = zeros(size(R_ges)); D_der = zeros(size(R_ges)); residual_der = zeros(size(R_ges)); gap_der = zeros(size(R_ges)); J_ges_der = zeros(size(R_ges));fraction = zeros(size(R_ges));
%             R_der(2:end) = (R_ges(2:end) - R_ges(1:end-1))/(max(R_ges)-min(R_ges));
%             D_der(2:end) = (D_ges(2:end) - D_ges(1:end-1))/(max(D_ges)-min(D_ges));
%             %fraction(2:end) = R_ges_scaled(2:end) ./ D_ges_scaled(2:end);
%             J_ges_der(2:end-1) = J_ges(3:end) + J_ges(1:end-2)  - 2* J_ges(2:end-1);
%             residual_der(2:end) = residual(2:end) - residual(1:end-1);
%             
% %             gap_ges = R_ges - D_ges;
%             gap_der = R_der - D_der;
%             
% %             k_min = find(D_ges == min(D_ges),1,'first');
% %             figure(); plot(log(-D_ges(1:end)),log(R_ges(1:end)));
% %             Lcurv = zeros(size(D_ges));
% %             for i = 2:(length(D_ges)-1)
% %                 Lcurv(i) = (R_ges(i+1) + R_ges(i-1) - 2*R_ges(i))/((D_ges(i+1) - D_ges(i-1))^2);
% %             end
%             %figure(); plot(R_ges(1:end),'b-*'); hold on; plot(D_ges(1:end),'g-*');plot(D_der,'r-*');plot(R_der,'m-*');plot(J_ges_der,'y-*');
% %             figure(); plot(R_der,'m-*');hold on; plot(D_der,'r-*');plot(abs(D_der)+abs(R_der),'b-*');
% %             axis on; hold off;
%             %figure(); plot(residual_der,'magenta');
% %             icy_imshow(u_ges);
% %             k_min_curv = find(abs(Lcurv(2:end) <= 0.1,1,'first'))
% %             k_min = find(residual_der(2:end) <= 0.1,1,'first');
% %             k_min = find(J_ges_der(2:end) <= 2,1,'first')+1
%             k_min = find(abs(D_der(2:end))+abs(R_der(2:end)) <= 0.1,1,'first')+1;
%             if ~isempty(k_min)
%                 act_lambda = lambda_test(k_min);
%                 bin = u_ges(:,:,:,1,k_min);
%             else
%                 act_lambda = lambda_test(length(D_ges));
%                 bin = u_ges(:,:,:,1,length(D_ges));
%             end
%             
%             table_par = table(k,act_lambda,grad_ratio, 'VariableNames',{'Channel' 'Parameter' 'GradientRatio'});
%                 
%                 mfile = matfile('test_table2.mat','Writable',true);
%                 mfile.table_par = [mfile.table_par;table_par];
% %             icy_imshow(bin);
%         end   
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

