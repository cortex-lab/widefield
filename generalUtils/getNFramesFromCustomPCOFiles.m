


function [nFrames, nFrPerFile] = getNFramesFromCustomPCOFiles(theseFiles, statusDest)

nFrPerFile = zeros(length(theseFiles),1);

if ~isempty(statusDest)
    fprintf(statusDest, 'determining number of images in %d files\nfile: ', length(theseFiles));
end
nFrames = 0;
for fileInd = 1:length(theseFiles)
    if ~isempty(statusDest)
        fprintf(statusDest, '%d...', fileInd);
    end
    [~, ~, TimeStamps] = LoadCustomPCO(theseFiles{fileInd}, false, true);
    nImagesThisFile = numel(TimeStamps);
    nFrames = nFrames+nImagesThisFile;
    nFrPerFile(fileInd) = nImagesThisFile;
end
if ~isempty(statusDest)
    fprintf(statusDest, '\n%d total frames acquired\n', nFrames);
end