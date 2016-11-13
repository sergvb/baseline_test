function result = parseNavPosEcef(bufer)
    structure = { 
        { 0, 'U4', 'iTow' };
        { 4, 'I4', 'ecefX' };
        { 8, 'I4', 'ecefY' };
        { 12, 'I4', 'ecefZ' };
        { 16, 'U4', 'pAcc' };
    };
    
    result = parse(structure, bufer);
end

