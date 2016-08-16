function [U, Sv, V, totalVar] = get_svdcomps(ops)
% function [U, Sv, V, totalVar] = get_svdcomps(ops)
% Computes SVD of data that's too large to compute directly by using
% "frames" that are averages of several true frames for estimating the
% covariance matrix. Assumes data are 3D (Y x X x Frames), in a file of the
% format described below.
%
% ops contains:
% ---
%
% ops.RegFile % raw data file. Format is flat binary, int16 data type,
% nPixels by nFrames
%
% ops.mimg % mean image, size Ly x Lx
%
% ops.Nframes  % number of frames in whole movie
%
% ops.NavgFramesSVD % number of frames to include in this computation. Each
% will be an average over approximately Nframes/NavgFramesSVD frames of the
% original movie
%
% ops.nSVD % number of SVD components to keep
% 
% ops.useGPU
%
% ops.yrange % subselection/ROI of image to use
% ops.xrange 
%
% ops.verbose % whether to output updates about progress


[Ly, Lx] = size(ops.mimg);

if ~isfield(ops, 'verbose')
    ops.verbose = false;
end

rawDType = 'int16';

ntotframes          = ceil(sum(ops.Nframes));
ops.NavgFramesSVD   = min(ops.NavgFramesSVD, ntotframes);
nt0 = ceil(ntotframes / ops.NavgFramesSVD);


ops.NavgFramesSVD = floor(ntotframes/nt0);
nimgbatch = nt0 * floor(1000/nt0);

ix = 0;

mov = zeros(Ly, Lx, ops.NavgFramesSVD, 'single');

if ops.verbose
    fprintf(1, 'loading data\n');
end

try 
    fid = fopen(ops.RegFile, 'r');
    while 1
        if ops.verbose
            fprintf(1, '   frame %d out of %d\n', ix*nt0, ops.Nframes);
        end
        
        data = fread(fid,  Ly*Lx*nimgbatch, ['*' rawDType]);
        if isempty(data)
            break;
        end
        data = single(data);
        data = reshape(data, Ly, Lx, []);      
    
        irange = 1:nt0*floor(size(data,3)/nt0);
        data = data(:,:, irange);

        data = reshape(data, Ly, Lx, nt0, []);
        davg = single(squeeze(mean(data,3)));

        mov(:,:,ix + (1:size(davg,3))) = davg;

        ix = ix + size(davg,3);
    end
catch me
    fclose(fid);
    rethrow(me);
end
fclose(fid);
toc
mov(:, :, (ix+1):end) = [];

% subtract mean here % TODO: compute the mean in the loop above rather than
% requiring it be passed in
mov = bsxfun(@minus, mov, single(ops.mimg));

mov = mov(ops.yrange, ops.xrange, :);


if ops.verbose
    fprintf(1, 'computing SVD\n');
end

ops.nSVD = min(ops.nSVD, size(mov,3));
mov             = reshape(mov, [], size(mov,3));

% If an ROI for the brain was selected, zero all outside pixels
% (AP 160804)
if isfield('roi',ops) && ~isempty(ops.roi)
    mov(~ops.roi(:),:) = 0;
end

% mov             = mov./repmat(mean(mov.^2,2).^.5, 1, size(mov,2));
COV             = mov' * mov/size(mov,1);

% total variance of data. If you ask for all Svs back then you will see
% this is equal to sum(Sv). In this case Sv are the singular values *of the
% covariance matrix* not of the original data - they are equal to the Sv of
% the original data squared (the variances per dimension). 
totalVar = sum(diag(COV)); 
                            

ops.nSVD = min(size(COV,1)-2, ops.nSVD);
toc
if ops.nSVD<1000 || size(COV,1)>1e4
    [V, Sv]          = eigs(double(COV), ops.nSVD);
else
    if ops.useGPU
        [V, Sv]         = svd(gpuArray(double(COV)));
        V = gather(V);
        Sv = gather(Sv);
    else
         [V, Sv]         = svd(COV);
    end
    V               = V(:, 1:ops.nSVD);
    Sv              = Sv(1:ops.nSVD, 1:ops.nSVD);
end

clear COV
U               = normc(mov * V);
clear mov
U               = single(U);
Sv              = single(diag(Sv));
toc
try
    fid = fopen(ops.RegFile, 'r');
    
    ix = 0;
    Fs = zeros(ops.nSVD, sum(ops.Nframes), 'single');
    
    if ops.verbose
        fprintf(1, 'applying SVD to data\n');
    end
    
    while 1
        
        if ops.verbose
            fprintf(1, '   frame %d out of %d\n', ix, ops.Nframes);
        end
        
        data = fread(fid,  Ly*Lx*nimgbatch, ['*' rawDType]);
        if isempty(data)
            break;
        end
        data = single(data);
        data = reshape(data, Ly, Lx, []);
                
        % subtract mean as we did before
        data = bsxfun(@minus, data, single(ops.mimg));
        
        data = data(ops.yrange, ops.xrange, :);
        Fs(:, ix + (1:size(data,3))) = U' * reshape(data, [], size(data,3));
        
        ix = ix + size(data,3);
    end
catch me
    fclose(fid);
    rethrow(me)
end

fclose(fid);
toc


V = Fs; clear Fs

U = reshape(U, numel(ops.yrange), numel(ops.xrange), []);

if ops.verbose
    fprintf(1, 'done.\n');
end
