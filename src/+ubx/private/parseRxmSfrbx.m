function result = parseRxmSfrbx(bufer)
    structure = { 
        { 0, 'U1', 'gnssId' };
        { 1, 'U1', 'svId' };
        { 3, 'U1', 'freqId' };
        { 4, 'U1', 'numWords', 2 }; % This field will be placed into the ref.
        { 6, 'U1', 'version' };
    };
    wordStructure = { 
        { 8, 'U4', 'dwrd' };
    };
    
    [result, ref] = parse(structure, bufer);
    result.words = zeros(ref.numWords, 1, 'uint32');
    
    for i = 1:ref.numWords
        res = parse(wordStructure, bufer, 4*(i - 1));
        result.words(i) = res.dwrd;
    end
end

