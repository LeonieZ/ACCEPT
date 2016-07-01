clear all;

% Works on Windows with Matlab R2016a and MinGW gcc
if ispc
    % compare xml minGW gcc compiler properties set in xml file
    % USER\AppData\Roaming\MathWorks\MATLAB\R2016a
    mex bregman_cv_core_mex.c COPTIMFLAGS='-O3'; 
end

% Works on Mac with clang and gcc (6.1, incl. openMP).
if ismac
    % compare xml file in /Users/userxyz/.matlab/R2016a/mex_C_maci64.xml
    % for compiler parameters
    mex -output bregman_cv_core_mex_openMP bregman_cv_core_mex.c COPTIMFLAGS='-O3' CFLAGS='\$CFLAGS -fopenmp -Wall' LDFLAGS='\$LDFLAGS -fopenmp';
    mex bregman_cv_core_mex.c COPTIMFLAGS='-O3';
end

if isunix
    % works on linux, TODO double-check
    %mex bregman_cv_core.c CFLAGS="\$CFLAGS -fopenmp -Wall -O3" LDFLAGS="\$LDFLAGS -fopenmp"
end