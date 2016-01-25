

% script to run Marius's SVD

mouseName = 'Dale'; 
thisDate = '2016-01-23';

fileBase = fullfile('L:\data\', mouseName, thisDate); % where the raw tif files are

datPath = fullfile('J:\', mouseName, thisDate, [thisDate '.dat']); % file to create. 
% should be a fast, local drive. Need disk space equal to the size of the
% raw tif files. 

savePath = fullfile('J:\', mouseName, thisDate); % where to put results. 
mkdir(savePath);

ops.verbose = true;

ops.rawDataType = 'tif'; % or 'customPCO'
ops.hasASCIIstamp = true;
ops.hasBinaryStamp = true;

ops.NavgFramesSVD = 7500; % number of frames to include in this computation
ops.nSVD = 3000; % number of SVD components to keep

ops.useGPU = true;

ops.RegFile = datPath;

% registration parameters
ops.doRegistration = true;
ops.NimgFirstRegistration  = 750;
ops.NiterPrealign          = 10;
ops.SubPixel               = Inf;
ops.RegPrecision = 'same';
ops.phaseCorrelation = true; % controls whitening - seems to work better with this on
ops.nRegisterBatchLimit = 750; % won't try to register more than this at once - for me I get memory errors with more than 750. 


%% First step, convert the tif files into a binary file. 
% Along the way we'll compute timestamps, meanImage, etc. 
% This is also the place to do image registration if desired, so that the
% binary file will contain the registered images.

if ~exist(datPath)
    
    if ops.doRegistration
        % if you want to do registration, we need to first determine the
        % target image. 
        
        fprintf(1, 'determining target image\n');
        [targetFrame, nFr] = generateRegistrationTarget(fileBase, ops);
        ops.Nframes = nFr;
        
    else
        targetFrame = [];
    end    
    
    [frameNumbers, imageMeans, timeStamps, meanImage, imageSize, regDs] = loadRawToDat(fileBase, datPath, ops, targetFrame);
    save(fullfile(savePath, 'dataSummary.mat'), 'frameNumbers', 'imageMeans', 'timeStamps', 'meanImage', 'imageSize', 'regDs');
else
    load(fullfile(savePath, 'dataSummary.mat'));
end

%% Second step, compute and save SVD
ops.Ly = imageSize(1); ops.Lx = imageSize(2); % not actually used in SVD function, just locally here

if ops.doRegistration
    minDs = min(regDs, [], 1);
    maxDs = max(regDs, [], 1);

    ops.yrange = ceil(maxDs(1)):floor(ops.Ly+minDs(1));
    ops.xrange = ceil(maxDs(2)):floor(ops.Lx+minDs(2));    
else
    ops.yrange = 1:ops.Ly; % subselection/ROI of image to use
    ops.xrange = 1:ops.Lx;
end
ops.Nframes = numel(timeStamps); % number of frames in whole movie

ops.mimg = meanImage;
if ops.hasASCIIstamp
    % remove the timestamp data
    ops.mimg(1:8,1:292) = 0;
elseif ops.hasBinaryStamp
    % remove the timstamp data
    ops.mimg(1,1:20) = 0;
end

ops.ResultsSaveFilename = fullfile(savePath, 'SVDresults.mat');

tic
[ops, U, Sv, V, totalVar] = get_svdcomps(ops);
toc