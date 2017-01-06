function packet = readNextPacket(fileID, packetID)
    while ~feof(fileID)
        packet = ubx.readPacket(fileID);

        if ~isempty(fieldnames(packet)) && packetID == packet.Id
            return;
        end
    end
end