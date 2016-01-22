

function [targetImg, nFr] = generateRegistrationTarget(fileBase, ops)

% fileBase is a directory with a bunch of tif files. 
theseFilesDir = dir(fullfile(fileBase, '*.tif'));
theseFiles = cellfun(@(x)fullfile(fileBase,x),{theseFilesDir.name},'UniformOutput', false);

[nFr, nFrPerFile] = getNFramesFromTifFiles(theseFiles);

imgInds = 1:ceil(nFr/ops.NimgFirstRegistration):nFr; % want these frames, evenly distributed from the recording

firstFrame = imread(theseFiles{1}, 1);

firstRegFrames = zeros(size(firstFrame,1), size(firstFrame,2), numel(imgInds));
firstRegFrames(:,:,1) = firstFrame;

cumFrameCount = [0; cumsum(nFrPerFile)];
if ops.verbose
    fprintf(1, 'loading test frames for identifying registration target\n');
end

for ind = 2:length(imgInds)
    fileInd = find(cumFrameCount<imgInds(ind),1,'last');
    frInd = imgInds(ind)-cumFrameCount(fileInd);
    thisFrame = imread(theseFiles{fileInd}, frInd);
    firstRegFrames(:,:,ind) = thisFrame;
end

firstRegFrames = removeStamps(firstRegFrames, ops.hasASCIIstamp, ops.hasBinaryStamp);
     
if ops.verbose
    fprintf(1, 'identifying registration target\n');
end
[AlignNanThresh, ErrorInitialAlign, dsprealign, targetImg] = align_iterative(firstRegFrames, ops);

if ops.verbose
    f = figure; set(f, 'Name', 'initial registration results');
    subplot(1,2,1); plot(dsprealign);
    title('dsprealign');
    subplot(1,2,2); plot(ErrorInitialAlign);
    title('ErrorInitialAlign');
end