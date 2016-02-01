

function V = readVfromNPY(vFilePath, varargin)
% function readVfromNPY(vFilePath[, nSVtoRead])
% Reads a V matrix from an NPY file, optionally reads just a certain number
% of components
% Expects that V has been written with "writeUVtoNPY", which is to say,
% that the array shape is nTimePoints x nSV

if isempty(varargin)
    V = readNPY(vFilePath)';
else
    nSVtoRead = varargin{1};
    [arrayShape, dataType, fortranOrder, littleEndian, totalHeaderLength, npyVersion] = readNPYheader(vFilePath);
    
    nTimePoints = arrayShape(1);
    
    fid = fopen(vFilePath, 'r');
    try
        header = fread(fid, totalHeaderLength, '*char');
        V = fread(fid, nTimePoints*nSVtoRead, ['*' dataType]);
        fclose(fid);
    catch me
        fclose(fid);
        rethrow(me);
    end
        
    V = reshape(V, nTimePoints, nSVtoRead)';
end
        

