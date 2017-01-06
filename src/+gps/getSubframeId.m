function sfId = getSubframeId( sfData )
    binWord = bitget(sfData(2), 30 : -1 : 1, 'uint32');
    sfId = bin2dec(num2str(binWord(20 : 22)));
end