
addpath(genpath('C:\Users\Nick\Documents\GitHub\widefield'))

fileBase = 'L:\data\Dale\2016-01-21\';
datPath = 'J:\Dale\2016-01-21\1\2016-01-21_1.dat';
savePath = 'J:\Dale\2016-01-21\1\'; 
load(fullfile(savePath, 'dataSummary.mat'));

% script for image registration

%% set parameters
ops.NimgFirstRegistration  = 750;
ops.NiterPrealign          = 10;
ops.SubPixel               = Inf;
ops.useGPU = true;
ops.RegPrecision = 'same';
ops.phaseCorrelation = true; % controls whitening - seems to work better with this on

ops.hasASCIIstamp = true;
ops.hasBinaryStamp = true;

%% initial pre-alignment

nFr = length(frameNumbers);

% load data
fprintf(1, 'loading frames for pre-registration\n');

dat = memmapfile(datPath, 'Format', {'uint16', [imageSize(1) imageSize(2) nFr],'d'});

firstRegImages = dat.Data.d(:,:,1:ceil(nFr/ops.NimgFirstRegistration):nFr);

% if necessary remove stamps
fprintf(1, 'determining target image\n');
firstRegImages = removeStamps(firstRegImages, ops.hasASCIIstamp, ops.hasBinaryStamp);

[AlignNanThresh, ErrorInitialAlign, dsprealign, targetImg] = align_iterative(firstRegImages, ops);

%% 

% get the registration offsets
dsall = zeros(nFr, 2);
allCorr = zeros(nFr,1);

batchSize = 500;

fid = fopen(fullfile(savePath, 'testReg.dat'), 'w');

for fr = 1%:ceil(nFr/batchSize)
    fprintf('aligning %d/%d\n', fr, ceil(nFr/batchSize));
    theseFrameInds = (fr-1)*batchSize+1:min(fr*batchSize,nFr);
    theseFrames = dat.Data.d(:,:,theseFrameInds);
    
    theseFrames = removeStamps(theseFrames, ops.hasASCIIstamp, ops.hasBinaryStamp);
    
    [ds, Corr]  = registration_offsets(theseFrames, ops, targetImg, 0);
    dsall(theseFrameInds,:)  = ds;
    allCorr(theseFrameInds) = Corr;
	regFrames = register_movie(theseFrames, ops, ds);

%     fwrite(fid, regFrames, 'uint16');
    
end

fprintf('done\n');

%% determine range of movie that can be used
minDs = min(dsall, [], 1);
maxDs = max(dsall, [], 1);
disp([minDs(1) maxDs(1) minDs(2) maxDs(2)])

yrange = ceil(maxDs(1)):floor(Ly+minDs(1));
xrange = ceil(maxDs(2)):floor(Lx+minDs(2));