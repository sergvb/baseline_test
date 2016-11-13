function packet = readPacket(fileID)
    packet = struct();
    if synchronise(fileID) == 1
        [headerBufer, count] = fread(fileID, 4, '*uint8');
        
        if count ~= 4
            fprintf('Can not read the packet''s header\n');
            return
        end
        
        length = typecast(headerBufer(3:4), 'uint16');
        [payloadBufer, count] = fread(fileID, length, '*uint8');
        
        if count ~= length
            fprintf('Can not read the packet''s payload\n');
            return
        end
        
        [checksumBufer, count] = fread(fileID, 2, '*uint8');
        
        if count ~= 2
            fprintf('Can not read the packet''s checksum\n');
            return
        end
        
        checksum = typecast(checksumBufer, 'uint16');
        
        if checksum ~= calculateChecksum(vertcat(headerBufer, payloadBufer))
            fprintf('Bad packet\n');
            return
        end
        
        id = typecast(headerBufer(1:2), 'uint16');
        payload = parsePayload(id, payloadBufer);
        
        if isempty(fieldnames(payload))
            % fprintf('Can not parse the packet''s payload\n');
            return
        end
        
        packet = payload;
        packet.Id = id;
    else
        fprintf('Not synchronised\n');
    end
end

function payload = parsePayload(id, bufer)
    switch id
        case ubx.Message.RXM_RAWX
            payload = parseRxmRawx(bufer);
        case ubx.Message.RXM_SFRBX
            payload = parseRxmSfrbx(bufer);
        case ubx.Message.NAV_POSECEF
            payload = parseNavPosEcef(bufer);
        case ubx.Message.NAV_POSLLH
            payload = parseNavPosLlh(bufer);
        otherwise
            payload = struct();
    end
end

function checksum = calculateChecksum(bufer)
    ckA = uint32(0);
    ckB = uint32(0);
    
    for i = 1:numel(bufer)
        ckA = mod(ckA + uint32(bufer(i)), 256);
        ckB = mod(ckB + ckA, 256);
    end
    
    checksum = typecast(uint8([ckA, ckB]), 'uint16');
end

function result = synchronise(fileID)
    syncChar1 = fread(fileID, 1, 'uint8');
    
    while ~feof(fileID)
        syncChar2 = fread(fileID, 1, 'uint8');
        
        if syncChar1 == 181 && syncChar2 == 98
            result = 1;
            return
        end
        
        syncChar1 = syncChar2;
    end
    
    result = 0;
end

