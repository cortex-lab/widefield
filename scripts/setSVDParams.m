

function ops = setSVDParams()

ops.mouseName = 'EJ010'; 
ops.thisDate = '2016-02-03';

ops.rigName = 'bigrig';

% ops.fileBase = fullfile('L:\data\', ops.mouseName, ops.thisDate); % where the raw tif files are
ops.fileBase = fullfile('L:\data\', ops.mouseName);

ops.datPath = fullfile('J:\', ops.mouseName, ops.thisDate, [ops.thisDate '.dat']); % file to create. 
% should be a fast, local drive. Need disk space equal to the size of the
% raw tif files. 

ops.localSavePath = fullfile('J:\', ops.mouseName, ops.thisDate); % where to put results temporarily on a local disk. 

ops.verbose = true;
ops.statusDestination = 1; % set this to 1 for status messages to appear on the screen. 
                           % set it to a filepath to write them to a file

ops.saveAsNPY = true; % set as false if you want the output on zserver to be mat files instead                           
                           
if ops.statusDestination~=1 
    % open the file
    fid = fopen(ops.statusDestination, 'w');
    ops.statusDestination = fid;
end
                           
ops.rawDataType = 'tif'; % 'tif' or 'customPCO'
ops.hasASCIIstamp = true; % if your movie has legible timestamps in the corner
ops.hasBinaryStamp = true; % if the binary time stamps were turned on

% ops.rawDataType = 'customPCO'; % 'tif' or 'customPCO'
% ops.hasASCIIstamp = false; % if your movie has legible timestamps in the corner
% ops.hasBinaryStamp = true; % if the binary time stamps were turned on (true for customPCO)

ops.binning = 4; % set to 2 for 2x2 binning, 3 for 3x3, etc. Setting to 1 skips this.

ops.NavgFramesSVD = 7500; % number of frames to include in this computation
ops.nSVD = 2000; % number of SVD components to keep

ops.Fs = 50; % sampling rate of the movie

ops.useGPU = true;

ops.RegFile = ops.datPath;

% registration parameters
ops.doRegistration = true;
ops.NimgFirstRegistration  = 750; % could use a smaller value if your movie is short? probably this is fine
ops.NiterPrealign          = 10; % increase this if "ErrorInitialAlign" doesn't go to zero
ops.SubPixel               = Inf; % leave alone
ops.RegPrecision = 'same'; % leave alone
ops.phaseCorrelation = true; % controls whitening - seems to work better with this on
ops.nRegisterBatchLimit = 750; % won't try to register more than this at once - for me I get memory errors with more than 750. 


