

function dataSummary = loadRawToDat(ops)
% converts a set of tif files in a directory (specified by ops.fileBase) to a
% flat binary (dat) file in datPath. While doing so,

theseFiles = ops.theseFiles;
datPath = ops.thisDatPath;

frameNumbers = [];
timeStamps = [];
imageMeans = [];

try
    fid = fopen(datPath, 'w');
    frameIndex = 0;
    for fileInd = 1:length(theseFiles)
        
        thisFile = theseFiles{fileInd};
        
        if ops.verbose
            fprintf(1, 'loading file: %s (%d of %d)\n', thisFile, fileInd, length(theseFiles));
        end
        
        clear imstack
        switch ops.rawDataType
            case 'tif'
                imstack = loadTiffStack(thisFile, 'tiffobj', ops.verbose);
            case 'customPCO'
                [~,~,~,imstack] = LoadCustomPCO(thisFile, false, true);
        end
        
        
        
        if ops.hasBinaryStamp
            if ops.verbose
                fprintf(1, '  computing timestamps\n');
            end
            
            switch ops.rawDataType
                case 'tif'
                    records = squeeze(imstack(1,1:14,:));
                    [thisFN, thisTS] = timeFromPCOBinaryMulti(records);
                    if fileInd==1
                        firstTS=thisTS(1);
                    end
                    
                    inclFrames = mod(thisFN, ops.frameMod(1))==ops.frameMod(2);
                    
                    nfr = sum(inclFrames);
                    
                    frameNumbers(frameIndex+1:frameIndex+nfr) = thisFN(inclFrames);
                    timeStamps(frameIndex+1:frameIndex+nfr) = thisTS(inclFrames)-firstTS;
                    
                    if ops.frameMod(1)>1
                        if ops.verbose
                            fprintf(1, '  selecting correct frames\n');
                        end
                        if ops.flipudVid
                            imstack = imstack(end:-1:1,:,inclFrames);
                        else
                            imstack = imstack(:,:,inclFrames);
                        end
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
                fprintf(1, '  binning image\n');
            end
            imstack = binImage(imstack, ops.binning);            
        end                
        
        if fileInd==1
            sz = size(imstack);
            imageSize = sz(1:2);
            sumImage = zeros(imageSize);
        end
        
        if ops.verbose
            fprintf(1, '  computing image means\n');
        end
        imageMeans(frameIndex+1:frameIndex+nfr) = squeeze(mean(mean(imstack,1),2));
                                
        
        if ops.verbose
            fprintf(1, '  computing mean image\n');
        end
        sumImage = sumImage+sum(double(imstack),3);
        
        if ops.verbose
            fprintf(1, '  saving to dat\n');
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
meanImage = sumImage/nFrames;

dataSummary.frameNumbers = frameNumbers;
dataSummary.imageMeans = imageMeans;
dataSummary.timeStamps = timeStamps;
dataSummary.meanImage = meanImage;
dataSummary.imageSize = imageSize;
dataSummary.dataType = class(imstack);
dataSummary.nFrames = nFrames;

if ops.verbose
    fprintf(1, '  done\n');
end
