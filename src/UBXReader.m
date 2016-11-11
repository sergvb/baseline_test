classdef(Sealed) UBXReader < handle

    properties(Access = private)
        FileID
    end
    
    methods 
        
        function this = UBXReader(fileName)
            this.FileID = fopen(fileName, 'r');
        end
        
        function delete(this)
            fclose(this.FileID);
        end
        
        function packet = ReadPacket(this)
            if this.Synchronise() == 1
                packet = this.CreatePacket();
            end
        end
        
    end
    
    methods(Access = private)
    
        function result = Synchronise(this)
            syncChar1 = fread(this.FileID, 1, 'uint8');
            
            while ~feof(this.FileID)
                syncChar2 = fread(this.FileID, 1, 'uint8');
                
                if syncChar1 == 181 && syncChar2 == 98
                   result = 1;
                   return;
                end
                
                syncChar1 = syncChar2;
            end
            
            result = 0;
        end
    
    end
    
end