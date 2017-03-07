%Compile the xml2struct mex file, make sure you have the boost libraries 
%somehere (http://www.boost.org/) so you can point to it. Original
%compilation was done with boost 1.61.0 /g will mail the author to ask
%about the software license. 

if ismac
    mex -I'./rapidxml' -I'/Applications/Boost/boost_1_61_0/' xml2struct.cc;
elseif ispc
    mex -I'./rapidxml' -I'C:\Data\libraries\boost_1_63_0\boost_1_63_0\' xml2struct.cc;
end