function result = parseNavPosLlh(bufer)
    structure = { 
        { 0, 'U4', 'iTow' };
        { 4, 'I4', 'lon' };
        { 8, 'I4', 'lat' };
        { 12, 'I4', 'height' };
        { 16, 'I4', 'hMSL' };
        { 20, 'U4', 'hAcc' };
        { 24, 'U4', 'vAcc' };
    };
    
    result = parse(structure, bufer);
end

