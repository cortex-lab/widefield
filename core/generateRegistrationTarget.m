

function [targetImg, nFr] = generateRegistrationTarget(fileBase, ops)

% fileBase is a directory with a bunch of tif files. 
switch ops.rawDataType
    case 'tif'
        theseFilesDir = dir(fullfile(fileBase, '*.tif'));
    case 'customPCO'
        theseFilesDir = dir(fullfile(fileBase, '*.mat'));
        [~,ii] = sort([theseFilesDir.datenum]);
        theseFilesDir = theseFilesDir(ii);
end
theseFiles = cellfun(@(x)fullfile(fileBase,x),{theseFilesDir.name},'UniformOutput', false);

switch ops.rawDataType
    case 'tif'
        [nFr, nFrPerFile] = getNFramesFromTifFiles(theseFiles);
        firstFrame = imread(theseFiles{1}, 1);
    case 'customPCO'
        [nFr, nFrPerFile] = getNFramesFromCustomPCOFiles(theseFiles);
        firstFrame = readOneCustomPCO(theseFiles{1}, 1);
end

imgInds = 1:ceil(nFr/ops.NimgFirstRegistration):nFr; % want these frames, evenly distributed from the recording

firstRegFrames = zeros(size(firstFrame,1), size(firstFrame,2), numel(imgInds));
firstRegFrames(:,:,1) = firstFrame;

cumFrameCount = [0; cumsum(nFrPerFile)];
if ops.verbose
    fprintf(1, 'loading test frames for identifying registration target\n');
end

for ind = 2:length(imgInds)
    fileInd = find(cumFrameCount<imgInds(ind),1,'last');
    frInd = imgInds(ind)-cumFrameCount(fileInd);
    switch ops.rawDataType
        case 'tif'
            thisFrame = imread(theseFiles{fileInd}, frInd);
        case 'customPCO'
            thisFrame = readOneCustomPCO(theseFiles{fileInd}, frInd);
    end
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
    drawnow;
end