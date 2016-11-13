clc, clear all;

fileID = fopen('..\data\RS_matv_50mm_01.bin');

while ~feof(fileID)
    packet = ubx.readPacket(fileID);
    if ~isempty(fieldnames(packet)) && packet.Id == ubx.Message.NAV_POSECEF
        disp(packet);
    end
end

fclose(fileID);