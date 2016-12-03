function result = groupPackets(data)
    length = numel(data);
    resultLength = length/2;
    
    raw = cell(resultLength, 1);
    rawIdx = 1;
    
    for i = 1:length
        if data{i}.Id == ubx.Message.RXM_RAWX
            raw{rawIdx} = data{i};
            rawIdx = rawIdx + 1;
        end
    end

    ecef = cell(resultLength, 1);
    ecefIdx = 1;
    
    for i = 1:length
        if data{i}.Id == ubx.Message.NAV_POSECEF
            ecef{ecefIdx} = data{i};
            ecefIdx = ecefIdx + 1;
        end
    end
    
    result = struct('raw', raw, 'ecef', ecef);
end