

function dataSummary = loadRawToDat(ops)
% converts a set of tif files in a directory (specified by ops.fileBase) to a
% flat binary (dat) file in datPath. While doing so, extract the data from
% the image stamps about time and frame number, and compute the mean of
% each image and also the mean image. Bin data if requested. 
%
% Importantly, this function will try to identify locations of different
% recordings within the files. It does this by assuming any 2-second long
% gap is a break between recordings (the logic is: missed frames appear to
% be rare and just a few at a time so you shouldn't ever miss 2 seconds of
% frames in a row. On the other hand, timeline start/stop always takes at
% least two seconds so you will have at least that much time between
% recordings). 
%
% ops is a struct that includes:
% - theseFiles - a cell array of filenames
% - datPath - a filename where you would like to create the raw binary file
% - verbose - logical, whether to display status messages
% - rawDataType - can be "tif" or "customPCO", specifies how to load the
% images
% - hasBinaryStamps - specifies whether the raw images have data encoded in
% binary stamps (these are PCO Edge cameras)
% - hasASCIIstamp - specifies whether there are also ASCII stamps which
% will be removed before binning/saving
% - binning - an integer N that specifies to apply N x N binning first
% - 


theseFiles = ops.theseFiles;
datPath = ops.datPath;

frameNumbersFromStamp = [];
timeStampsFromStamp = [];
frameNumbersWithinRec = [];
frameFileIndex = [];
frameRecIndex = [];
imageMeans = [];

recIndex = 0;
lastFrameNum = 0;
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
                    thisTS = thisTS*24*3600; % convert to seconds from days
                    
                    clear theseFrameNumbersWithinRec;
                    if fileInd==1
                        firstTS=thisTS(1);
                        thisTS = thisTS-firstTS;
                        frameDiffs = diff([-10 thisTS]);  % so first frame is a "new rec"                                              
                    else
                        thisTS = thisTS-firstTS;
                        frameDiffs = diff([timeStampsFromStamp(end) thisTS]);
%                         theseRecIndex = frameRecIndex(end)+cumsum(frameDiffs>2);
                    end       
                    
                    newRecInds = find(frameDiffs>2); % any 2-second gaps between frames indicate a new recording
                    theseRecIndex = recIndex*ones(size(thisTS));       %default unless new recs present
                    theseFrameNumbersWithinRec = lastFrameNum+(1:length(thisTS)); %default unless new recs present
                    nFrThisFile = length(thisTS);
                    for n = 1:length(newRecInds)
                        recIndex = recIndex+1;
                        
                        theseFrameNumbersWithinRec(newRecInds(n):nFrThisFile) = 1:(nFrThisFile-newRecInds(n)+1);
                        theseRecIndex(newRecInds(n):nFrThisFile) = recIndex;
                        
                    end
                    
                    %inclFrames = mod(thisFN, ops.frameMod(1))==ops.frameMod(2);
                    inclFrames = mod(theseFrameNumbersWithinRec, ops.frameMod(1))==ops.frameMod(2);
                    
                    nfr = sum(inclFrames);
                    
                    frameNumbersFromStamp(frameIndex+1:frameIndex+nfr) = thisFN(inclFrames);
                    timeStampsFromStamp(frameIndex+1:frameIndex+nfr) = thisTS(inclFrames);
                    frameFileIndex(frameIndex+1:frameIndex+nfr) = fileInd;
                    frameRecIndex(frameIndex+1:frameIndex+nfr) = theseRecIndex(inclFrames);
                    frameNumbersWithinRec(frameIndex+1:frameIndex+nfr) = theseFrameNumbersWithinRec(inclFrames);
                    lastFrameNum = theseFrameNumbersWithinRec(end);
                    
                    if ops.frameMod(1)>1
                        if ops.verbose
                            fprintf(1, '  selecting correct frames\n');
                        end
                        
                    end
                    
                case 'customPCO'
                    frameNumbers(frameIndex+1:frameIndex+nfr) = NaN;
                    [~,~,thisTS] = LoadCustomPCO(thisFile, false, true);
                    thisTS = thisTS*24*3600; % convert to seconds from days
                    
                    if fileInd==1
                        firstTS=thisTS(1);
                    end
                    
                    timeStamps(frameIndex+1:frameIndex+nfr) = thisTS-firstTS;
            end
        else
            fprintf(1, '  options are set as though you don''t have binary stamps in your images. But you really need them!!! everything is going to fail here.');
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
        
        if ops.flipudVid
            imstack = imstack(end:-1:1,:,inclFrames);
        else
            imstack = imstack(:,:,inclFrames);
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


nFrames = numel(frameNumbers);
meanImage = sumImage/nFrames;

dataSummary.frameNumbersFromStamp = frameNumbersFromStamp;
dataSummary.timeStampsFromStamp = timeStampsFromStamp;
dataSummary.frameFileIndex = frameFileIndex;
dataSummary.frameRecIndex = frameRecIndex;
dataSummary.frameNumbersWithinRec = frameNumbersWithinRec;
dataSummary.imageMeans = imageMeans;
dataSummary.meanImage = meanImage;
dataSummary.imageSize = imageSize;
dataSummary.dataType = class(imstack);
dataSummary.nFrames = nFrames;

if ops.verbose
    fprintf(1, '  done, found and loaded %d images from %d recordings\n', nFrames, length(unique(dataSummary.frameRecIndex)));
end
