function result = computeDifferences(groupA, groupB)

    % Assume that the groups synchronized in time
    % and they have the same length
    length = numel(groupA);
    result = cell(length, 1);
    
    for i = 1:length
        x = groupA(i).ecef.ecefX - groupB(i).ecef.ecefX;
        y = groupA(i).ecef.ecefY - groupB(i).ecef.ecefY;
        z = groupA(i).ecef.ecefZ - groupB(i).ecef.ecefZ;

        mesA = prepareMeasurments(groupA(i).raw.measurments);
        mesB = prepareMeasurments(groupB(i).raw.measurments);
        
        [commonSv, ia, ib] = intersect([mesA.svId], [mesB.svId]);
        commonSvLength = numel(commonSv);
        svA = mesA(ia);
        svB = mesB(ib);
       
        dphi = zeros(commonSvLength - 1, 1);
        dphiBase = svA(1).cpMes - svB(1).cpMes;
        
        for k = 2:commonSvLength
            dphi(k - 1) = dphiBase - svA(k).cpMes - svB(k).cpMes;
        end
        
        result{i} = [x; y; z; dphi];
    end
    
end

function result = prepareMeasurments(measurments)
    gps = [measurments.gnssId] == 0;
    tmp = cell(32, 1);
    tmp([measurments(gps).svId]) = num2cell(measurments(gps));
    result = cell2mat(tmp(~cellfun(@isempty, tmp)));
end