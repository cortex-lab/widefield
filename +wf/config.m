

function [dirs, ops] = config(rig)

if nargin < 1 || isempty(rig)
    rig = hostname; % default rig is hostname
end

dirs.record = 'J:\';
dirs.archive = 'Q:\';

ops.NavgFramesSVD = 500; % number of frames to include in this computation
ops.nSVD = 100; % number of SVD components to keep
ops.useGPU = false;



                
switch rig
    case 'zamera1'
        
        
    case 'zamera2'
        
        
end
