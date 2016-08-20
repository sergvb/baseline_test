function res = ubxdump_new(filename)
    res = zeros();
    fileID = fopen(filename, 'r');
    
    if fileID == -1
        return;
    end
    
    while ~feof(fileID)
        if isSync(fileID) == 1
            readPacket(fileID);
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

function readPacket(fileID)
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
        parsePayload(fileID, class, id, payloadLength);
        fseek(fileID, 2, 'cof');
    else
        fprintf('Bad packet. Start: %d, L: %d\n', packetStart, payloadLength);
    end
end

function parsePayload(fileID, class, id, length)
    switch class
        case 1 % NAV
            parseNavClass(fileID, id, length);
        case 2 % RXM
            parseRxmClass(fileID, id, length);
        otherwise
            fprintf('Parser for class: %X not implemented\n', class);
    end
end

function parseNavClass(fileID, id, length)
    fprintf('NAV Class. Message ID: %X L:%d\n', id, length);
end

function parseRxmClass(fileID, id, length)
    switch id
        case 19 % RXM-SFRBX
            parseRxmSfrbxMessage(fileID, length);
        case 21 % RXM-RAWX
            parseRxmRawxMessage(fileID, length);
        otherwise
            fprintf('Parser for message ID: %X not implemented\n', id);
    end
end

function parseRxmSfrbxMessage(fileID, length)
    fprintf('RXM-SFRBX Message. L:%d\n', length);
end

function parseRxmRawxMessage(fileID, length)
    fprintf('RXM-RAWX Message. L:%d\n', length);
end