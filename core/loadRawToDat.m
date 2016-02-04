

function [frameNumbers, imageMeans, timeStamps, meanImage, imageSize, regDs] = loadRawToDat(fileBase, datPath, ops, targetFrame)
% converts a set of tif files in a directory (specified by fileBase) to a
% flat binary (dat) file in datPath. While doing so,

switch ops.rawDataType
    case 'tif'
        theseFilesDir = dir(fullfile(fileBase, '*.tif'));
    case 'customPCO'
        theseFilesDir = dir(fullfile(fileBase, '*.mat'));
        [~,ii] = sort([theseFilesDir.datenum]);
        theseFilesDir = theseFilesDir(ii);
end
theseFiles = cellfun(@(x)fullfile(fileBase,x),{theseFilesDir.name},'UniformOutput', false);


if ~isfield(ops, 'Nframes') || isempty(ops.Nframes)
    if ops.verbose
        statusDest = ops.statusDestination;
    else
        statusDest = [];
    end
    switch ops.rawDataType
        case 'tif'
            nFrames = getNFramesFromTifFiles(theseFiles, statusDest);
        case 'customPCO'
            nFrames = getNFramesFromCustomPCOFiles(theseFiles, statusDest);
    end

else
    nFrames = ops.Nframes;
end

frameNumbers = zeros(1,nFrames);
timeStamps = zeros(1,nFrames);
imageMeans = zeros(1,nFrames);

try
    fid = fopen(datPath, 'w');
    frameIndex = 0;
    for fileInd = 1:length(theseFiles)
        
        thisFile = theseFiles{fileInd};
        
        if ops.verbose
            fprintf(ops.statusDestination, 'loading file: %s (%d of %d)\n', thisFile, fileInd, length(theseFiles));
        end
        
        clear imstack
        switch ops.rawDataType
            case 'tif'
                if ops.verbose
                    statusDest = ops.statusDestination;
                else
                    statusDest = [];
                end
                imstack = loadTiffStack(thisFile, 'tiffobj', statusDest);
            case 'customPCO'
                [~,~,~,imstack] = LoadCustomPCO(thisFile, false, true);
        end
        
        nfr = size(imstack,3);
        
        if ops.hasBinaryStamp
            if ops.verbose
                fprintf(ops.statusDestination, '  computing timestamps\n');
            end
            
            switch ops.rawDataType
                case 'tif'
                    records = squeeze(imstack(1,1:14,:));
                    [thisFN, thisTS] = timeFromPCOBinaryMulti(records);
                    if fileInd==1
                        firstTS=thisTS(1);
                    end
                    frameNumbers(frameIndex+1:frameIndex+nfr) = thisFN;
                    timeStamps(frameIndex+1:frameIndex+nfr) = thisTS-firstTS;
                case 'customPCO'
                    frameNumbers(frameIndex+1:frameIndex+nfr) = NaN;
                    [~,~,thisTS] = LoadCustomPCO(thisFile, false, true);
                    if fileInd==1
                        firstTS=thisTS(1);
                    end
                    timeStamps(frameIndex+1:frameIndex+nfr) = thisTS-firstTS;
            end
        end
        
        imstack = removeStamps(imstack, ops.hasASCIIstamp, ops.hasBinaryStamp);
        
        if ops.binning>1
            imstack = binImage(imstack, ops.binning);
        end                
        
        if fileInd==1
            sz = size(imstack);
            imageSize = sz(1:2);
            meanImage = zeros(imageSize);
        end
        
        if ops.verbose
            fprintf(ops.statusDestination, '  computing image means\n');
        end
        imageMeans(frameIndex+1:frameIndex+nfr) = squeeze(mean(mean(imstack,1),2));
        
                
        if ops.doRegistration && ~isempty(targetFrame)
            if ops.verbose
                fprintf(ops.statusDestination, '  registering frames\n');
            end
            
            if fileInd==1
                regDs = zeros(nfr,2);
            end                        
            
            [ds, ~]  = registration_offsets(imstack, ops, targetFrame, 0);
            regDs(frameIndex+1:frameIndex+nfr,:)  = ds;
            
            batchInds = 1:ops.nRegisterBatchLimit:nfr;
            regFrames = zeros(size(imstack));
            for b = batchInds
                theseFrInds = b:min(nfr, b+ops.nRegisterBatchLimit-1);
                regFrames(:,:,theseFrInds) = register_movie(imstack(:,:,theseFrInds), ops, ds);
            end
        else
            regFrames = imstack;
            if fileInd==1
                regDs = zeros(nfr,2);
            end
        end
        
        if ops.verbose
            fprintf(ops.statusDestination, '  computing mean image\n');
        end
        meanImage = meanImage+double(mean(regFrames,3))*(nfr/nFrames);
        
        if ops.verbose
            fprintf(ops.statusDestination, '  saving to dat\n');
        end
        fwrite(fid, regFrames, 'uint16');
        
        frameIndex = frameIndex+nfr;
        
    end
    
catch me
    fclose(fid);
    rethrow(me)
end
fclose(fid);

timeStamps = timeStamps*24*3600; % convert to seconds from days

if ops.verbose
    fprintf(ops.statusDestination, '  done\n');
end
