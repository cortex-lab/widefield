

function ops = setSVDParams()

% ops.mouseName = 'Dale'; 
% ops.thisDate = '2016-01-24';

ops.mouseName = 'M150416_MK020'; 
ops.thisDate = '2015-08-03';
ops.iSeries = 20150803;
ops.iExp = 1;
ops.ExpRef = dat.constructExpRef(ops.mouseName, ops.thisDate, ops.iExp);

ops.rigName = 'bigrig';

% ops.fileBase = fullfile('L:\data\', ops.mouseName, ops.thisDate); % where the raw tif files are
ops.fileBase = fullfile('\\zserver2\Data\GCAMP\', ops.mouseName, num2str(ops.iSeries), num2str(ops.iExp));

ops.datPath = fullfile('G:\WF', ops.mouseName, ops.thisDate, [ops.ExpRef, '.dat']); % file to create. 
% should be a fast, local drive. Need disk space equal to the size of the
% raw tif files. 

ops.localSavePath = fullfile('G:\WF', ops.mouseName, ops.thisDate, ops.ExpRef); % where to put results temporarily on a local disk. 

ops.verbose = true;

% ops.rawDataType = 'tif'; % 'tif' or 'customPCO'
% ops.hasASCIIstamp = true; % if your movie has legible timestamps in the corner
% ops.hasBinaryStamp = true; % if the binary time stamps were turned on

ops.rawDataType = 'customPCO'; % 'tif' or 'customPCO'
ops.hasASCIIstamp = false; % if your movie has legible timestamps in the corner
ops.hasBinaryStamp = false; % if the binary time stamps were turned on

ops.NavgFramesSVD = 7500; % number of frames to include in this computation
ops.nSVD = 1000; % number of SVD components to keep

ops.Fs = 50; % sampling rate of the movie

ops.useGPU = false;

ops.RegFile = ops.datPath;

% registration parameters
ops.doRegistration = true;
ops.NimgFirstRegistration  = 750; % could use a smaller value if your movie is short? probably this is fine
ops.NiterPrealign          = 10; % increase this if "ErrorInitialAlign" doesn't go to zero
ops.SubPixel               = Inf; % leave alone
ops.RegPrecision = 'same'; % leave alone
ops.phaseCorrelation = true; % controls whitening - seems to work better with this on
ops.nRegisterBatchLimit = 750; % won't try to register more than this at once - for me I get memory errors with more than 750. 


