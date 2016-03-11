

function ops = setSVDParams()

ops.mouseName = 'Domagk'; 
ops.thisDate = '2016-03-11';

ops.vids(1).fileBase = fullfile('/mnt/data/svdinput/', ops.mouseName, ops.thisDate, 'cam2');
ops.vids(1).frameMod = [2,0]; % specifies which frames are these. mod(frameNums,frameMod(1))==frameMod(2);
ops.vids(1).rigName = 'bigrig2';
ops.vids(1).name = 'green';

ops.vids(2).fileBase = fullfile('/mnt/data/svdinput/', ops.mouseName, ops.thisDate, 'cam2');
ops.vids(2).frameMod = [2,1];
ops.vids(2).rigName = 'bigrig2';
ops.vids(2).name = 'blue';

ops.vids(3).fileBase = fullfile('/mnt/data/svdinput/', ops.mouseName, ops.thisDate, 'cam1');
ops.vids(3).frameMod = [1,0];
ops.vids(3).rigName = 'bigrig1';
ops.vids(3).name = 'red';

ops.localSavePath = '/mnt/data/svdinput/temp/'; % where to put results temporarily on a local disk. 

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

ops.binning = 3; % set to 2 for 2x2 binning, 3 for 3x3, etc. Setting to 1 skips this.

ops.NavgFramesSVD = 7500; % number of frames to include in this computation
ops.nSVD = 2000; % number of SVD components to keep

ops.Fs = 35; % sampling rate of the movie

ops.useGPU = true;

% registration parameters
ops.doRegistration = false;
ops.NimgFirstRegistration  = 750; % could use a smaller value if your movie is short? probably this is fine
ops.NiterPrealign          = 10; % increase this if "ErrorInitialAlign" doesn't go to zero
ops.SubPixel               = Inf; % leave alone
ops.RegPrecision = 'same'; % leave alone
ops.phaseCorrelation = true; % controls whitening - seems to work better with this on
ops.nRegisterBatchLimit = 750; % won't try to register more than this at once - for me I get memory errors with more than 750. 


