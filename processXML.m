function [Success_out, Msr, xml] = processXML( path_input_cartridge, res )
% Process XML file if available
%% determine in which directory the xml file is located.

Success_out = res.success;
NoXML = 0;
xml = [];

% find directory where xml file is located in
xml_dir  = FindXMLDir(path_input_cartridge);

if strcmp(xml_dir, 'No xml dir found') || strcmp(xml_dir, 'More than one dir found')
    Success_out = xml_dir;
    NoXML=1;
else
    XMLFile = dir([xml_dir filesep '*.xml']);
end

%% Load & process XML file
if NoXML == 0
    xml=xml2struct([xml_dir filesep XMLFile.name]);
    if isfield(xml,'archive')
        xml.num_events = size(xml.archive{2}.events.record,2);
        xml.CellSearchIds = zeros(xml.num_events,1);
        locations = zeros(xml.num_events,4);
        for i=1:xml.num_events
            xml.CellSearchIds(i)=str2num(xml.archive{2}.events.record{i}.eventnum.Text); %#ok<*ST2NM>
            tempstr=xml.archive{2}.events.record{i}.location.Text;
            start=strfind(tempstr,'(');
            finish=strfind(tempstr,')');
            to=str2num(tempstr(start(1)+1:finish(1)-1));
            from=str2num(tempstr(start(2)+1:finish(2)-1));
            locations(i,:)=[from,to];
        end
        xml.columns=str2num(xml.archive{2}.runs.record.numcols.Text);
        xml.rows=str2num(xml.archive{2}.runs.record.numrows.Text);
        xml.camYSize=str2num(xml.archive{2}.runs.record.camysize.Text);
        xml.camXSize=str2num(xml.archive{2}.runs.record.camxsize.Text);
    elseif isfield(xml, 'export')
        xml.num_events = size(xml.export{2}.events.record,2);
        xml.CellSearchIds = zeros(xml.num_events,1);
        locations = zeros(xml.num_events,4);
        for i=1:xml.num_events
            xml.CellSearchIds(i)=str2num(xml.export{2}.events.record{i}.eventnum.Text);
            tempstr=xml.export{2}.events.record{i}.location.Text;
            start=strfind(tempstr,'(');
            finish=strfind(tempstr,')');
            to=str2num(tempstr(start(1)+1:finish(1)-1));
            from=str2num(tempstr(start(2)+1:finish(2)-1));
            locations(i,:)=[from,to];
        end
        xml.columns=str2num(xml.export{2}.runs.record.numcols.Text);
        %     rows=str2num(xml.export{2}.runs.record.numrows.Text);
        xml.camYSize=str2num(xml.export{2}.runs.record.camysize.Text);
        xml.camXSize=str2num(xml.export{2}.runs.record.camxsize.Text);
    else
        Success_out='unable to read xml';
        return
    end
end


%% see if we can find a cellsearch id to assossiate.
if NoXML==0 && size(res.Msr,1) > 0
%     Msr = [res.Msr array2table(zeros(size(res.Msr,1),1),'VariableNames',{'CellSearchID'})];
    CellSearchID{size(res.Msr,1),1} = '--';
    Msr = [res.Msr cell2table(CellSearchID, 'VariableNames',{'CellSearchID'})];


    for jj = 1:size(res.Msr,1)
        
        xdim = res.Msr.BoundingBox(jj,4);
        ydim = res.Msr.BoundingBox(jj,5);
        lower_x = res.Msr.BoundingBox(jj,1);
        lower_y = res.Msr.BoundingBox(jj,2);
        higher_x = lower_x+xdim;
        higher_y = lower_y+ydim;
        
        minloc=pixelsToCoordinates([lower_x, lower_y], res.Msr.ImgNum(jj), xml.columns, xml.camXSize, xml.camYSize);
        maxloc=pixelsToCoordinates([higher_x, higher_y], res.Msr.ImgNum(jj), xml.columns, xml.camXSize, xml.camYSize);
        
        overlaps = 0;
        overlap=[];
        for i=1:size(locations,1)
            if ~(locations(i,1)>maxloc(1)||locations(i,2)>maxloc(2)||locations(i,3)<minloc(1)||locations(i,4)<minloc(2))
                overlaps = 1;
                overlap(i)=(min(locations(i,3),maxloc(1))-max(locations(i,1),minloc(1)))*(min(locations(i,4),maxloc(2))-max(locations(i,2),minloc(2)))/((maxloc(1)-minloc(1))*(maxloc(2)-minloc(2)));
            end
        end
        if overlaps
            [a,kk]=max(overlap);
            Msr.CellSearchID(jj)=num2cell(xml.CellSearchIds(kk));
            Msr.CellSearchIDOverlap(jj)=a;
        else
            Msr.CellSearchID(jj)=cellstr('--');
            Msr.CellSearchIDOverlap(jj)=0;
            
        end
    end
end
end
    
