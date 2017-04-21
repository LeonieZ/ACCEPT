%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 

clear all;

% Works on Windows with Matlab R2016a and MinGW gcc
if ispc
    % compare xml minGW gcc compiler properties set in xml file
    % USER\AppData\Roaming\MathWorks\MATLAB\R2016a
    mex -output bregman_cv_core_mex_openMP bregman_cv_core_mex.c -v COPTIMFLAGS="-O3" CXXFLAGS="$CXXFLAGS -fopenmp" LDFLAGS="$LDFLAGS -fopenmp";
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
    % works on linux
    %mex bregman_cv_core_mex.c CFLAGS="\$CFLAGS -fopenmp -Wall -O3" LDFLAGS="\$LDFLAGS -fopenmp";
    mex -output bregman_cv_core_mex_openMP bregman_cv_core_mex.c COPTIMFLAGS='-O3' CFLAGS='\$CFLAGS -fopenmp -Wall' LDFLAGS='\$LDFLAGS -fopenmp';
    mex bregman_cv_core_mex.c COPTIMFLAGS='-O3';
end