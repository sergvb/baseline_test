function data = readData(fileName, ids)

    fileId = fopen(fileName);

    i = 1;
    while ~feof(fileId)
        packet = ubx.readPacket(fileId);
        packetFilter = ~isempty(fieldnames(packet)) ...
            && ~isempty(find(ids == packet.Id));

        if packetFilter
            data{i} = packet;
            i = i + 1;
        end
    end
    
    fclose(fileId);

end