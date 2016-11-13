function result = parseRxmRawx(bufer)
    structure = { 
        { 0, 'R8', 'rcvTow' };
        { 8, 'U2', 'week' };
        { 10, 'I1', 'leapS' };
        { 11, 'U1', 'numMeas', 2 }; % This field will be placed into the ref.
        { 12, 'X1', 'recStat' };
    };
    measurmentStructure = { 
        { 16, 'R8', 'prMes' }; 
        { 24, 'R8', 'cpMes' }; 
        { 32, 'R4', 'doMes' }; 
        { 36, 'U1', 'gnssId' }; 
        { 37, 'U1', 'svId' }; 
        { 39, 'U1', 'freqId' }; 
        { 40, 'U2', 'locktime' }; 
        { 42, 'U1', 'cno' }; 
        { 43, 'X1', 'prStdev' }; 
        { 44, 'X1', 'cpStdev' }; 
        { 45, 'X1', 'doStdev' }; 
        { 46, 'X1', 'trkStat' };
    };
    
    [result, ref] = parse(structure, bufer);
   
    for i = 1:ref.numMeas
        [result.measurments(i)] = parse(measurmentStructure, bufer, 32*(i - 1));
    end
end