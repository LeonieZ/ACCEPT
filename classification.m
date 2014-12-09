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

% add classification results to measurement output
for jj = 1:size(res.Msr,2)
    Msr(jj).ACTC = isACTC(jj);
    Msr(jj).WBC = isWBC(jj);
%     Msr(jj).CKCD45 = isCKCD45(jj);
%     Msr(jj).Nucleus = isNucleus(jj);
%     Msr(jj).ONLYFITC = isONLYFITC(jj);
%     Msr(jj).ONLYFITC2 = isONLYFITC2(jj);
    Msr(jj).Cellline = isCellline(jj);
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
        include_event = Msr(index).(gateStr{ii,1}) > gate_valuesl(ii) & Msr(index).(gateStr{ii,1}) < gate_valuesu(ii);
        bool = bool & include_event;
    end
else
    bool=ones(size(Msr,2),1);
    for index=1:size(Msr,2)
        for ii = 1:size(gateStr,1)
            include_event = Msr(index).(gateStr{ii,1}) > gate_valuesl(ii) & Msr(index).(gateStr{ii,1}) < gate_valuesu(ii);
            bool(index) = bool(index) & include_event;
        end
    end
end


end

