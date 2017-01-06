clc, clear all;

fileId = fopen('..\data\RS_matv_50mm_02.bin');

stat = cell(32, 1);
while ~feof(fileId)
    sfrbxPacket = readNextPacket(fileId, ubx.Message.RXM_SFRBX);
    if ~isempty(fieldnames(sfrbxPacket))
        if isempty(stat{sfrbxPacket.svId})
            stat{sfrbxPacket.svId} = { { sfrbxPacket } };
        else
            lastGroup = stat{sfrbxPacket.svId}{end};
            sfId = gps.getSubframeId(sfrbxPacket.words);
            lastSfId = gps.getSubframeId(lastGroup{end}.words);
            
            if lastSfId < sfId && sfId <= 5
                stat{sfrbxPacket.svId}{end} = [ lastGroup, {sfrbxPacket} ];
            else
                stat{sfrbxPacket.svId} = [ stat{sfrbxPacket.svId}, { { sfrbxPacket } } ];
            end
        end
    end
end

fclose all;

svNumbers = find(~cellfun(@isempty, stat));
lineCount = max(cellfun(@numel, stat));

fprintf('|% 7u', svNumbers);
fprintf('|\n');

for ln = 1:lineCount
    for sv = svNumbers.'
        pageStat = '-----';
        
        if ln <= numel(stat{sv})
            page = stat{sv}{ln};

            if ~isempty(page)
                for i = 1:numel(page)
                    sfId = gps.getSubframeId(page{i}.words);
                    pageStat(sfId) = '+';
                end
            end
        end
        
        fprintf('| %5s ', pageStat);
    end
    fprintf('|\n');
end