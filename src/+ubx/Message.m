classdef Message
    properties(Constant)
        % Constants have a format: hex2dec('<MessageID><Class>')
        % Class 0x01 - NAV
        NAV_POSECEF = hex2dec('0101');
        NAV_POSLLH = hex2dec('0201');
        
        % Class 0x02 - RXM
        RXM_RAWX = hex2dec('1502');
        RXM_SFRBX = hex2dec('1302');
    end
end