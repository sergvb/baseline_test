function [varargout] = parse(structure, bufer, origin)
    rows = size(structure, 1);
    varargout = cell(1, nargout);
    
    if nargin < 3
        origin = 0;
    end
    
    % TODO: Move this code to somewhere.
    ubxTypes.U1 = { 1, 'uint8' };
    ubxTypes.I1 = { 1, 'int8' };
    ubxTypes.X1 = { 1, 'uint8' };
    ubxTypes.U2 = { 2, 'uint16' };
    ubxTypes.I2 = { 2, 'int16' };
    ubxTypes.X2 = { 2, 'uint16' };
    ubxTypes.U4 = { 4, 'uint32' };
    ubxTypes.I4 = { 4, 'int32' };
    ubxTypes.X4 = { 4, 'uint32' };
    ubxTypes.R4 = { 4, 'single' };
    ubxTypes.R8 = { 8, 'double' };
    ubxTypes.CH = { 1, 'int8' };
    
    for i = 1:rows
        defaults = {0, '', '', 1};
        entry = structure{i};
        ncols = min(size(entry, 2), 4);
        [defaults{ 1:ncols }] = entry{ 1:ncols };
        [offset, ubxType, fieldName, category] = defaults{ 1:4 };
        [fieldSize, type] = ubxTypes.(ubxType){1:2};
        
        if category > 0 && category <= nargout
            varargout{category}.(fieldName) = typecast(bufer(uint32(origin) + uint32(offset) + uint32(1:fieldSize)), type);
        end
    end
end