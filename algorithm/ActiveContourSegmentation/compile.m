clear all;

% works on windows with Matlab R2016a and MinGW gcc
if ispc
    % compare xml minGW gcc compiler properties set in xml file
    % USER\AppData\Roaming\MathWorks\MATLAB\R2016a
    mex bregman_cv_core_mex.c COPTIMFLAGS='-O3'; %CFLAGS='-fopenmp' LDFLAGS='-fopenmp';
end

% mex bregman_cv_core.c CFLAGS="\$CFLAGS -Wall -O3"

% works on linux
%mex bregman_cv_core.c CFLAGS="\$CFLAGS -fopenmp -Wall -O3" LDFLAGS="\$LDFLAGS -fopenmp"