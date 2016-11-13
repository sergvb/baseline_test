clc, clear all;

fileID = fopen('..\data\RS_matv_50mm_01.bin');

while ~feof(fileID)
    packet = ubx.readPacket(fileID);
    if ~isempty(fieldnames(packet)) && packet.Class == 2 && packet.MessageID == 21
        disp(packet);
    end
end

fclose(fileID);