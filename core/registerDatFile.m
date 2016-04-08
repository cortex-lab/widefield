

function registerDatFile(datPath, outFile, ds, imageSize, nFr, ops)

batchSize = ops.nRegisterBatchLimit; % images at once
numBatches = ceil(nFr/batchSize);
fid = fopen(datPath);
fidOut = fopen(outFile, 'w');

try
    for b = 1:numBatches
        imstack = fread(fid,  imageSize(1)*imageSize(2)*batchSize, '*int16');
        imstack = single(imstack);
        imstack = reshape(imstack, imageSize(1), imageSize(2), []);
        regFrames = register_movie(imstack, ops, ds);

        fwrite(fidOut, int16(regFrames), 'int16');
    end
catch me
    
    fclose(fid);
    fclose(fidOut);
    
    rethrow(me);
end
fclose(fid);
fclose(fidOut);
    
    