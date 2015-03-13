function [Success_out, Msr] = classification(res)
% script to run classifiers on measurement output. 

Success_out = res.success;
Msr = res.Msr;

% load gates
gates
    
%First Gatingate
isACTC = isGatedBy(Msr,Breast);
isWBC = isGatedBy(Msr,WBC);
% isONLYFITC = isGatedBy(Msr,ONLYFITC);
% isONLYFITC2 = isGatedBy(Msr,ONLYFITC2);
% isCKCD45 = isGatedBy(Msr,CKCD45);
% isNucleus = isGatedBy(Msr,Nucleus);
isCellline = isGatedBy(Msr,Cellline);
size(isACTC)
size(Msr)
% add classification results to measurement output
for jj = 1:size(res.Msr,1)
    Msr.ACTC(jj) = isACTC(jj);
    Msr.WBC(jj) = isWBC(jj);
%     Msr.CKCD45(jj) = isCKCD45(jj);
%     Msr.Nucleus(jj) = isNucleus(jj);
%     Msr.ONLYFITC(jj) = isONLYFITC(jj);
%     Msr.ONLYFITC2(jj) = isONLYFITC2(jj);
    Msr.Cellline(jj) = isCellline(jj);
end    
    

    
end %function classfication

%% function to proof if an event falls into a class
function [bool] = isGatedBy(Msr,gateStr,index)
% This function returns if measured events falls in Gate

% set gates for easy iteration
gate_valuesl = zeros(1, size(gateStr,1));
gate_valuesu = zeros(1, size(gateStr,1));
for gate = 1:size(gateStr,1)
    if strcmp(gateStr{gate,2}, 'upper')
        gate_valuesl(gate) = -inf;
        gate_valuesu(gate) = gateStr{gate,3};
    else
        gate_valuesl(gate) = gateStr{gate,3};
        gate_valuesu(gate) = inf;
    end
end

if nargin == 3;
    bool=true;
    for ii = 1:size(gateStr,1)
        include_event = Msr.(gateStr{ii,1})(index) > gate_valuesl(ii) & Msr.(gateStr{ii,1})(index) < gate_valuesu(ii);
        bool = bool & include_event;
    end
else
    bool=ones(size(Msr,1),1);
    for index=1:size(Msr,1)
        for ii = 1:size(gateStr,1)
            include_event = Msr.(gateStr{ii,1})(index) > gate_valuesl(ii) & Msr.(gateStr{ii,1})(index) < gate_valuesu(ii);
            bool(index) = bool(index) & include_event;
        end
    end
end


end

