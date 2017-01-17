clc, clear all;

fileId = fopen('..\data\RS_matv_50mm_01.bin');

rawxPacket = readNextPacket(fileId, ubx.Message.RXM_RAWX);
gpsMeasIndex = find([rawxPacket.measurments.gnssId] == 0);
gpsSv = [rawxPacket.measurments(gpsMeasIndex).svId];

sfData = zeros(11, numel(gpsSv), 'uint32');
sfData(1, :) = gpsSv;

notBindedSv = gpsSv;
while ~isempty(notBindedSv) && ~feof(fileId)
    sfrbxPacket = readNextPacket(fileId, ubx.Message.RXM_SFRBX);
    
    if ~isempty(fieldnames(sfrbxPacket)) && sfrbxPacket.gnssId == 0
        notBindedsSvIndex = find(notBindedSv == sfrbxPacket.svId);
        svIndex = find(gpsSv == sfrbxPacket.svId);

        if ~isempty(notBindedsSvIndex)
            sfData(2 : end, svIndex) = sfrbxPacket.words;
            notBindedSv(notBindedsSvIndex) = [];
        end
    end
end

fclose all;