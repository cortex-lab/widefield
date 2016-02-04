


function [nFrames, nFrPerFile] = getNFramesFromTifFiles(theseFiles, statusDest)

nFrPerFile = zeros(length(theseFiles),1);

if ~isempty(statusDest)
    fprintf(statusDest, 'determining number of images in %d files\nfile: ', length(theseFiles));
end
nFrames = 0;
w = warning ('off','all'); % tiffs throw weird warnings we'd rather ignore...
for fileInd = 1:length(theseFiles)
    if ~isempty(statusDest)
        fprintf(statusDest, '%d...', fileInd);
    end
    tiffFilename = theseFiles{fileInd};
    InfoImage=imfinfo(tiffFilename);
    nImagesThisFile=length(InfoImage);
    nFrames = nFrames+nImagesThisFile;
    nFrPerFile(fileInd) = nImagesThisFile;
end
warning(w);
if ~isempty(statusDest)
    fprintf(statusDest, '\n%d total frames acquired\n', nFrames);
end