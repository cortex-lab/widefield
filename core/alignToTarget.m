

function allDs = alignToTarget(datPath, targetFrame, imageSize, nFr, ops)

batchSize = ops.nRegisterBatchLimit; % images at once
numBatches = ceil(nFr/batchSize);
fid = fopen(datPath);
ind = 1;
allDs = zeros(nFr, 2);
try
    for b = 1:numBatches
        imstack = fread(fid,  imageSize(1)*imageSize(2)*batchSize, '*int16');
        imstack = single(imstack);
        imstack = reshape(imstack, Ly, Lx, []);
        [ds, ~]  = registration_offsets(imstack, ops, targetFrame, 0);

        allDs(ind:ind+size(imstack,3)-1,:) = ds;
        ind = ind+size(imstack,3);
    end
catch me
    
    fclose(fid);
    rethrow(me);
end

fclose(fid);    
    