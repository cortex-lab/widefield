

function ops = svdConfig(varargin)
% function ops = svdConfig(baseOps, userName)
%
% If you have specific settings, you want to customize, add them in the
% switch/case block at the end. 

if numel(varargin)==1
    baseOps = varargin{1};
elseif numel(varargin)==2
    baseOps = varargin{1};
    userName = varargin{2};
else
    ops = [];
    userName = [];
end


% defaults
ops.verbose = true; % whether it will output messages

ops.saveAsNPY = true; % set as false if you want the output on zserver to be mat files instead                                                      
                           
ops.rawDataType = 'tif'; % 'tif' or 'customPCO'
ops.hasASCIIstamp = true; % if your movie has legible timestamps in the corner
ops.hasBinaryStamp = true; % if the binary time stamps were turned on

ops.binning = 1; % set to 2 for 2x2 binning, 3 for 3x3, etc. Setting to 1 skips this.

ops.NavgFramesSVD = 7500; % number of frames to include in this computation
ops.nSVD = 2000; % number of SVD components to keep

ops.Fs = 35; % sampling rate of the movie

ops.useGPU = false;

% registration parameters
ops.doRegistration = false;
ops.NimgFirstRegistration  = 750; % could use a smaller value if your movie is short? probably this is fine
ops.NiterPrealign          = 10; % increase this if "ErrorInitialAlign" doesn't go to zero
ops.SubPixel               = Inf; % leave alone
ops.RegPrecision = 'same'; % leave alone
ops.phaseCorrelation = true; % controls whitening - seems to work better with this on
ops.nRegisterBatchLimit = 750; % won't try to register more than this at once - for me I get memory errors with more than 750. 


switch lower(userName)
    
    case 'nick'
        
    case 'daisuke'
        
    case 'elina'
        
    case 'mika'
        
    case 'andy'
        
end

ops = mergeStructs(baseOps, ops); % override these settings with anything that was passed in
