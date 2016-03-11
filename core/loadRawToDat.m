

function dataSummary = loadRawToDat(ops, vidNum)
% converts a set of tif files in a directory (specified by ops.fileBase) to a
% flat binary (dat) file in datPath. While doing so,

theseFiles = ops.vids(vidNum).theseFiles;
datPath = ops.vids(vidNum).thisDatPath;

frameNumbers = [];
timeStamps = [];
imageMeans = [];

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
                    
                    inclFrames = mod(thisFN, ops.vids(vidNum).frameMod(1))==ops.vids(vidNum).frameMod(2);
                    
                    nfr = sum(inclFrames);
                    
                    frameNumbers(frameIndex+1:frameIndex+nfr) = thisFN(inclFrames);
                    timeStamps(frameIndex+1:frameIndex+nfr) = thisTS(inclFrames)-firstTS;
                    
                    if ops.vids(vidNum).frameMod(1)>1
                        if ops.verbose
                            fprintf(ops.statusDestination, '  selecting correct frames\n');
                        end
                        imstack = imstack(:,:,inclFrames);
                    end
                    
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
            if ops.verbose
                fprintf(ops.statusDestination, '  binning image\n');
            end
            imstack = binImage(imstack, ops.binning);            
        end                
        
        if fileInd==1
            sz = size(imstack);
            imageSize = sz(1:2);
            sumImage = zeros(imageSize);
        end
        
        if ops.verbose
            fprintf(ops.statusDestination, '  computing image means\n');
        end
        imageMeans(frameIndex+1:frameIndex+nfr) = squeeze(mean(mean(imstack,1),2));
                                
        
        if ops.verbose
            fprintf(ops.statusDestination, '  computing mean image\n');
        end
        sumImage = sumImage+sum(double(imstack),3);
        
        if ops.verbose
            fprintf(ops.statusDestination, '  saving to dat\n');
        end
                
        fwrite(fid, imstack, class(imstack));
        
        frameIndex = frameIndex+nfr;
        
    end
    
catch me
    fclose(fid);
    rethrow(me)
end
fclose(fid);

timeStamps = timeStamps*24*3600; % convert to seconds from days

nFrames = numel(frameNumbers);
meanImage = sumImages/nFrames;

dataSummary.frameNumbers = frameNumbers;
dataSummary.imageMeans = imageMeans;
dataSummary.timeStamps = timeStamps;
dataSummary.meanImage = meanImage;
dataSummary.imageSize = imageSize;
dataSummary.dataType = class(imstack);
dataSummary.nFrames = nFrames;

if ops.verbose
    fprintf(ops.statusDestination, '  done\n');
end
