/* 
 * ========================================================================
 * Bregman CV CORE: C-Implementation of Primal-Dual Hybrid-Gradient Method
 * efficiently solving the Multiscale TV Segmentation Problem
 * Reference: https://arxiv.org/abs/1604.06665
 * C. Brune, L. Zeune, G. van Dalum, 24 June 2016 (version 1)
 * ========================================================================
 * 
 * INPUT PARAMETERS
 *  f         vectorized input image
 *  nx        number of rows in Matlab
 *  ny        number of columns in Matlab
 *  lambda    regularization parameter
 *  breg_it   number of Bregman inner_itations
 *  inner_it  number of inner inner_itations
 *  tol       tolerance, algorithm accuracy
 *  u_input   
 *  u_bar     
 *  sigma     convergence parameter
 *  tau       convergence parameter
 *  theta     convergence parameter
 *  mu0       pre-estimated mean value
 *  mu1       pre-estimated mean value
 *
 * OUTPUT PARAMETERS
 *  u         desired image (binary segmentation obtained via u > 0.5)
 *
 * USAGE compilation in Matlab:
 *  mex bregman_cv_core_mex.c COPTIMFLAGS='-O3';
 *
 * COPYRIGHT: GPL open source license
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>
#include <matrix.h>
#include "mex.h"
#include "omp.h"

#if !defined(MAX)
    #define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif
#if !defined(MIN)
    #define	MIN(A, B)	((A) < (B) ? (A) : (B))
#endif

/* headers */
/*float Estimate_constants(float *f,float *mus,int nx,int ny);*/
float Set_zeros(float *u,float *u_bar,float *p1,float *p2,int nx,int ny);
float Scale(float *f,float *f_scaled,int nx,int ny);
float Update_constants(float *f,float *u,float *mus,int nx,int ny);
float Projection_dual_lq_ball(float *u,float *p1,float *p2,int nx, int ny,float sigma);
float Projection_data_fidelity(float *u,float *p1,float *p2,float *b,float *f,float *mus,int nx,int ny,float tau,float lambda);
float Primal_update(float *u_bar,float *u,float *u_old,int nx,int ny,float theta);
float Bregman_update(float *f,float *mus,float *b,int nx,int ny,float lambda);
float Binary_result(float *u,int nx,int ny,float thresh);
float Copy_array(float *u, float *u_old, int size);
float Relative_error(float *stat_u, float *u, float *u_old, int nx, int ny);

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray*prhs[]){    
    
    /* input variable declarations */
    int nx, ny, breg_it, inner_it;
    float *f, lambda, tol, *u_input, *u_bar, mu0, mu1;
    
    /* output and temporary variable declarations */
    int i, j;
    float *u, *u_old, *p1, *p2, *b, *mus, sigma, tau, theta, *stat_u;

    /* handling Matlab INPUT parameters */
    f         = (float *)   mxGetData(prhs[0]);  /* vectorized input image */
    nx        = (int)     mxGetScalar(prhs[1]);  /* number of rows in Matlab */
    ny        = (int)     mxGetScalar(prhs[2]);  /* number of columns in Matlab */
    lambda    = (float)   mxGetScalar(prhs[3]);  /* regularization parameter */
    breg_it   = (int)     mxGetScalar(prhs[4]);  /* number of Bregman inner_itations */
    inner_it  = (int)     mxGetScalar(prhs[5]);  /* number of inner inner_itations */
    tol       = (float)   mxGetScalar(prhs[6]);  /* tolerance, algorithm accuracy */
    u_input   = (float *)   mxGetData(prhs[7]);
    u_bar     = (float *)   mxGetData(prhs[8]);
    sigma     = (float)   mxGetScalar(prhs[9]);  /* convergence parameters */
    tau       = (float)   mxGetScalar(prhs[10]);
    theta     = (float)   mxGetScalar(prhs[11]);
    mu0       = (float)   mxGetScalar(prhs[12]); /* mean values */
    mu1       = (float)   mxGetScalar(prhs[13]);
    
    /* handling Matlab OUTPUT parameters */
    u     = (float *) mxGetData(plhs[0]=mxCreateNumericMatrix(nx,ny,mxSINGLE_CLASS,mxREAL));
    /* initialize: u = u_input */
    Copy_array(u_input,u,nx*ny);
    
    /* arrays and variables used in the algorithms */
    /*u_bar = (float *) calloc(nx*ny,sizeof(float));*/
    p1    = (float *) calloc(nx*ny,sizeof(float));
    p2    = (float *) calloc(nx*ny,sizeof(float));
    u_old = (float *) calloc(nx*ny,sizeof(float));
    b     = (float *) calloc(nx*ny,sizeof(float));
    
    /* Variables to be returned to Matlab 
    u_bar = (float *) mxGetData(plhs[1]=mxCreateNumericMatrix(nx,ny,mxSINGLE_CLASS,mxREAL));
    p1    = (float *) mxGetData(plhs[2]=mxCreateNumericMatrix(nx,ny,mxSINGLE_CLASS,mxREAL));
    p2    = (float *) mxGetData(plhs[3]=mxCreateNumericMatrix(nx,ny,mxSINGLE_CLASS,mxREAL));
    u_old = (float *) mxGetData(plhs[4]=mxCreateNumericMatrix(nx,ny,mxSINGLE_CLASS,mxREAL));
    b     = (float *) mxGetData(plhs[5]=mxCreateNumericMatrix(nx,ny,mxSINGLE_CLASS,mxREAL));*/
    
    stat_u = (float*) calloc(1,sizeof(float));
    stat_u[0] = FLT_MAX;
    
    mus = (float*) calloc(2,sizeof(float));    
    /* compute estimate for foreground and background intensity constants mu0 and mu1 */
    /*Estimate_constants(f,mus,nx,ny);*/
    mus[0] = mu0; mus[1] = mu1; /* use mu parameters being transfered here */
    /*mexPrintf("\n mus[0]= %e, mus[1]= %e \n",mus[0],mus[1]);*/
    
    /* Bregman inner_itations */
    for (i = 0; i < breg_it; i++){
    
        /* set u, u_bar, p1 and p2 back to zero */
        /* Set_zeros(u,u_bar,p1,p2,nx,ny); */
        
        /* main primal-dual inner_itation */
        j = 0;
        while ( j < inner_it && stat_u[0] >= tol){
        /*for (j = 0; j < inner_it; j++){*/
            /* mexPrintf("\nInner inner_itation: %d\n",j+1); */

            /* STEP 1 : update p according to 
             * p_(j+1) = (I+sigma delta F*)^(-1)(p_j + sigma K u_bar_j) 
             * more precisely:
             * p_(j+1) = (p_j + sigma grad(u_bar_j)) / max(1,|p_j + sigma grad(u_bar_j)|)
             */
            Projection_dual_lq_ball(u_bar,p1,p2,nx,ny,sigma);

            /* store old inner_itate: u_old = u */
            Copy_array(u,u_old,nx*ny);
                        
            /* STEP 2: update u according to
             * u_(j+1) = (I+tau delta G)^(-1)(u_j - tau K* p_(j+1))
             * more precisely:
             * u_(j+1) = max(0,min(1,u_j+tau*div(p_(j+1))-tau/lambda*((f-mu1)^2-(f-mu0)^2-lambda*b_i)))
             */
            Projection_data_fidelity(u,p1,p2,b,f,mus,nx,ny,tau,lambda);
            
            /* Track relative error of u iterates for stopping criterion 
             * stat_u(j) = (nx*ny)^(-1) * (sum((u(:) - u_old(:)).^2)/sum(u_old(:).^2));
             */
            Relative_error(stat_u,u,u_old,nx,ny);
            /*mexPrintf("\n stat_u = %e \n",stat_u[0]);*/
            
            /* STEP 3: update u_bar according to
             * u_bar_(j+1) = u_(j+1)+ theta * (u_(j+1) - u_j)
             */
            Primal_update(u_bar,u,u_old,nx,ny,theta);
          
            /* Update mu values (mu0 and mu1) */
            /* Note: There is no mu update used here */
            
            j = j+1;
        }
        
        /* update b (outer Bregman update)
         * b = b + 1/lambda * ((f-mu0)^2 - (f-mu1)^2)
         */
        Bregman_update(f,mus,b,nx,ny,lambda);
        
        /* Update mu values (mu0 and mu1) */
        /*Update_constants(f,u,mus,nx,ny);
        mexPrintf("\n mus[0]= %e, mus[1]= %e \n",mus[0],mus[1]);*/
        
        /* Binary_result(u,nx,ny,0.5f); */
    }
    
    /* free variables */
    free(u_old); free(p1); free(p2); free(b); free(mus); free(stat_u); /* algorithm arrays */
}

/******************************/

/* compute estimate for foreground and background intensity constants mu0 and mu1 */
float Estimate_constants(float *f,float *mus,int nx,int ny){

    float *f_scaled = (float*) calloc(nx*ny,sizeof(float));
    Scale(f,f_scaled,nx,ny); /* scale to [0,1] */
        
    /* compute mean value outside object, mu0 background */
    int mu0_counter = 0;
    int mu1_counter = 0;
    int i;
    for(i=0; i<nx*ny; i++){
        if(f_scaled[i] < 0.5f){
            mus[0] = mus[0] + f[i];
            mu0_counter++;
        }
        if(f_scaled[i] >= 0.5f){
            mus[1] = mus[1] + f[i];
            mu1_counter++;
        }
    }
    mus[0] = MAX(mus[0]/mu0_counter,0.0f);
    mus[1] = MAX(mus[1]/mu1_counter,0.0f);
    return *mus;
}

/* set vectors back to zero */
float Set_zeros(float *u,float *u_bar,float *p1,float *p2,int nx,int ny){
    int s;
    for (s=0;s<nx*ny;s++){
        u[s]     = 0.0f;
        u_bar[s] = 0.0f;
        p1[s]    = 0.0f;
        p2[s]    = 0.0f;
    }
    return 1;
}

/* compute estimate for foreground and background intensity constants mu0 and mu1 */
float Update_constants(float *f,float *u,float *mus,int nx,int ny){

    float *mus_tmp = (float*) calloc(2,sizeof(float));
    mus_tmp[0] = mus[0];
    mus_tmp[1] = mus[1];            
    
    /* compute mean value outside object, mu0 background */
    float *mus_sum = (float*) calloc(2,sizeof(float));
    int mu0_counter = 0;
    int mu1_counter = 0;
    int i;
    for(i=0; i<nx*ny; i++){
        if(u[i] < 0.5f){
            mus_sum[0] = mus_sum[0] + f[i];
            mu0_counter++;
        }
        if(u[i] >= 0.5f){
            mus_sum[1] = mus_sum[1] + f[i];
            mu1_counter++;
        }
    }
    /* mexPrintf("\n mu counters: %d %d \n",mu0_counter,mu1_counter); */
    if (mu0_counter > 0 && mu1_counter > 0){
        mus[0] = MAX(mus_sum[0]/mu0_counter,0.0f);
        mus[1] = MAX(mus_sum[1]/mu1_counter,0.0f);
        mexPrintf("\n mu0 counter: %d, mu1 counter %d \n",mu0_counter,mu1_counter);
        /* mexPrintf("\n mus: %e %e \n",mus[0],mus[1]); */
    } else{
        mus[0] = mus_tmp[0];
        mus[1] = mus_tmp[1];
    }        
    return *mus;
}

/* compute the projection into the lq ball
 * p_(n+1) = (p_n + sigma grad(u_bar_n)) / max(1,|p_n + sigma grad(u_bar_n)|) 
 */
float Projection_dual_lq_ball(float *u,float *p1,float *p2,int nx, int ny,float sigma){
    float v1,v2,gradY,gradX,gradMag;
    int i,j;
#pragma omp parallel for shared(u,p1,p2) private(i,j,gradY,gradX,gradMag,v1,v2)
    for(j=0; j<ny; j++){
        for(i=0; i<nx; i++){
            /* compute the gradient with symmetric Neumann zero boundary conditions */
            if(i == nx-1) gradX = 0.0f;/*gradX = u[i*ny     + (j-1)] - u[i*ny + j];*/
                else       gradX = u[j*nx     + (i+1)] - u[j*nx + i];
            
            if(j == ny-1) gradY = 0.0f;/*gradY = u[(i-1)*ny +     j] - u[i*ny + j];*/
                else       gradY = u[(j+1)*nx +     i] - u[j*nx + i];
            /* compute temporary argument */
            v1 = p1[j*nx + i] + sigma*(gradX);
            v2 = p2[j*nx + i] + sigma*(gradY);
            /* the case lq = l2 vector norm */
            gradMag = sqrt(pow(v1,2) + pow(v2,2));
            if(gradMag > 1){
                p1[j*nx + i] = v1/gradMag;
                p2[j*nx + i] = v2/gradMag;
            }else{
                p1[j*nx + i] = v1;
                p2[j*nx + i] = v2;
            }            
        }
    }
    return 1;
}

/* Projection data fidelity
 * u_(j+1) = max(0,min(1,u_j+tau*div(p_(j+1))-tau/lambda*((f-mu1)^2-(f-mu0)^2-lambda*b_i)))
 */
float Projection_data_fidelity(float *u,float *p1,float *p2,float *b,float *f,float *mus,int nx,int ny,float tau,float lambda){
    int i,j;
    float P_v1, P_v2,div;
#pragma omp parallel for shared(u,p1,p2) private(i,j,P_v1,P_v2,div)
    for(j=0;j<ny;j++) {
        for(i=0;i<nx;i++) {
            /* compute the divergence with symmetric Neumann zero boundary conditions */
            /* In Matlab P_v1 corresponds to derivative in col direction (first dim) */
            if (i == 0) P_v1 = p1[j*nx + i];
            else
                if (i == nx-1) P_v1 = -p1[j*nx + i-1];
                else P_v1 = p1[j*nx + i] - p1[j*nx +     i-1];
            /* In Matlab P_v2 corresponds to derivative in row direction (second dim) */
            if (j == 0) P_v2 = p2[j*nx + i];
            else
                if (j == ny-1) P_v2 = -p2[(j-1)*nx + i];
                else P_v2 = p2[j*nx + i] - p2[   (j-1)*nx + i];
            div = P_v1 + P_v2;
            u[j*nx + i] = MAX( 0.0f , MIN(1.0f , u[j*nx + i] + tau*div - (tau/lambda)*(pow(f[j*nx + i]-mus[1],2)-pow(f[j*nx + i]-mus[0],2)-lambda*b[j*nx + i]) ) );

        }
    }
    return *u;
}

/* Track relative error of u iterates for stopping criterion 
 * stat_u(j) = (nx*ny)^(-1) * (sum((u(:) - u_old(:)).^2)/sum(u_old(:).^2));
 */
float Relative_error(float *stat_u, float *u, float *u_old, int nx, int ny){
    int i;
    float norm_u_res = 0.0f;
    float norm_uold = 0.0f;
    for(i=0;i<nx*ny;i++){
        norm_u_res = norm_u_res + pow(u[i]-u_old[i],2);
        norm_uold  = norm_uold  + pow(u_old[i],2);
    }
    stat_u[0] = norm_u_res/(norm_uold*nx*ny);
    return *stat_u;
}

/* Primal solution update
 * u_bar_(j+1) = u_(j+1) + theta * (u_(j+1) - u_j)
 */
float Primal_update(float *u_bar,float *u,float *u_old,int nx,int ny,float theta){
    int i;
#pragma omp parallel for shared(u_bar,u,u_old) private(i)
    for(i=0;i<nx*ny;i++){
        u_bar[i] = u[i] + theta*(u[i] - u_old[i]);
    }
    return *u_bar;
}

/* Bregman update
 * b = b + 1/lambda * ((f-mu0)^2 - (f-mu1)^2)
 */
float Bregman_update(float *f,float *mus,float *b,int nx,int ny,float lambda){
    int i;
    for(i=0;i<nx*ny;i++){
        b[i] = b[i] + (1/lambda)*(pow(f[i]-mus[0],2)-pow(f[i]-mus[1],2));
    }
    return *b;
}

/* Binary solution via thresholding
 * u = u > thres
 */
float Binary_result(float *u,int nx,int ny,float thresh){
    int i;
#pragma omp parallel for shared(u) private(i)
    for(i=0;i<nx*ny;i++){
        if (u[i] > thresh){
            u[i] = 1.0f;
        }else{
            u[i] = 0.0f;
        }
    }
    return *u;
}

/********************************************************************/

/* store old inner_itate */
float Copy_array(float *u, float *u_old, int size){
    int i;
#pragma omp parallel for shared(u,u_old) private(i)
    for(i=0;i<size;i++){
        u_old[i] = u[i];
    }
    return *u_old;
}

/* scale the vector/matrix f to [0,1] */
float Scale(float *f,float *f_scaled,int nx,int ny){
    int i;
    float fmin = FLT_MAX;
    for(i=0; i<nx*ny; i++){
            fmin = MIN(fmin,f[i]);
    }    
    for(i=0; i<nx*ny; i++){
            f_scaled[i] = f[i] - fmin;
    }
    float fmax = FLT_MIN;
    for(i=0; i<nx*ny; i++){
            fmax = MAX(fmax,f_scaled[i]);
    }
    for(i=0; i<nx*ny; i++){
            f_scaled[i] = f_scaled[i]/fmax;
    }
    return *f_scaled;
}

