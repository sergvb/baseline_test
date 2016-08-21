function result = ubxdump_new(filename)
    result = cell(0, 1);
    fileID = fopen(filename, 'r');
    i = 1;
    
    if fileID == -1
        return;
    end
    
    while ~feof(fileID)
        if isSync(fileID) == 1
            result{i} = readPacket(fileID);
            i = i + 1;
        else
            % log
        end
    end
    
    fclose(fileID);
end

function flag = isSync(fileID)
    flag = 0;
    
    syncChar1 = fread(fileID, 1, 'uint8');
    
    if syncChar1 ~= 181
        return
    end
    
    syncChar2 = fread(fileID, 1, 'uint8');
    
    if syncChar2 ~= 98
        return
    end
    
    flag = 1;
end

function result = readPacket(fileID)
    result = {};
    packetStart = ftell(fileID);
    
    class = fread(fileID, 1, 'uint8');
    id = fread(fileID, 1, 'uint8');
    payloadLength = fread(fileID, 1, 'uint16', 0, 'ieee-le');
    payloadStart = ftell(fileID);
    
    fprintf('Paket header. Class: %X, ID: %X, L:%d\n', class, id, payloadLength);
    
    if feof(fileID)
        fprintf('Can not properly read the packet. End.\n');
        return;
    end
    
    % Read the range over which the checksum is to be calculated
    fseek(fileID, packetStart, 'bof');
    [crcBody, crcBodyLength] = fread(fileID, payloadLength + 4, 'uint8');
    
    % Calculate the checksum
    ckACalc = 0;
    ckBCalc = 0;

    for i = 1:crcBodyLength
        ckACalc = mod(ckACalc + crcBody(i), 256);
        ckBCalc = mod(ckBCalc + ckACalc, 256);
    end

    % Read the checksum from the file then compare with calculated one
    ckA = fread(fileID, 1, 'uint8');
    ckB = fread(fileID, 1, 'uint8');

    if ckA == ckACalc && ckB == ckBCalc
        fseek(fileID, payloadStart, 'bof');
        result = parsePayload(fileID, class, id, payloadLength);
        fseek(fileID, 2, 'cof');
    else
        fprintf('Bad packet. Start: %d, L: %d\n', packetStart, payloadLength);
    end
end

function result = parsePayload(fileID, class, id, length)
    switch class
        case 1 % NAV
            result = parseNavClass(fileID, id, length);
        case 2 % RXM
            result = parseRxmClass(fileID, id, length);
        otherwise
            fprintf('Parser for class: %X not implemented\n', class);
    end
end

function result = parseNavClass(fileID, id, length)
    fprintf('NAV Class. Message ID: %X L:%d\n', id, length);
    result = {};
end

function result = parseRxmClass(fileID, id, length)
    switch id
        case 19 % RXM-SFRBX
            result = parseRxmSfrbxMessage(fileID, length);
        case 21 % RXM-RAWX
            result = parseRxmRawxMessage(fileID, length);
        otherwise
            fprintf('Parser for message ID: %X not implemented\n', id);
    end
end

function result = parseRxmSfrbxMessage(fileID, length)
    fprintf('RXM-SFRBX Message. L:%d\n', length);
    result = {};
end

function result = parseRxmRawxMessage(fileID, length)
    fprintf('RXM-RAWX Message. L:%d\n', length);
    result = {};
    result.rcvTow = fread(fileID, 1, 'double');
    result.week = fread(fileID, 1, 'uint16');
    result.leapS = fread(fileID, 1, 'int8');
    numMeas = fread(fileID, 1, 'uint8');
    result.recStat = fread(fileID, 1, 'uint8');
    result.reserved1 = fread(fileID, 3, 'uint8');
    measurments = cell(numMeas, 1);
    for i = 1:numMeas
        meas = {};
        meas.prMes = fread(fileID, 1, 'double');
        meas.cpMes = fread(fileID, 1, 'double');
        meas.doMes = fread(fileID, 1, 'single');
        meas.gnssId = fread(fileID, 1, 'uint8');
        meas.svId = fread(fileID, 1, 'uint8');
        meas.reserved2 = fread(fileID, 1, 'uint8');
        meas.freqId = fread(fileID, 1, 'uint8');
        meas.locktime = fread(fileID, 1, 'uint16');
        meas.cno = fread(fileID, 1, 'uint8');
        meas.prStdev = fread(fileID, 1, 'uint8');
        meas.cpStdev = fread(fileID, 1, 'uint8');
        meas.doStdev = fread(fileID, 1, 'uint8');
        meas.trkStat = fread(fileID, 1, 'uint8');
        meas.reserved3 = fread(fileID, 1, 'uint8');
        measurments{i} = meas;
    end
    result.measurments = measurments;
end