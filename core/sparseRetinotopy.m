

function signMap = sparseRetinotopy(U, V, t, stimPositions, stimTimes, mimg)
% TODO:
% - add plot of peak RF locations


nSV = min(100, size(U,3));
win = [0 0.18];
Fs = 1/mean(diff(t));
binSize = 1/Fs;
trf = win(1):binSize:win(2);
peakInds = trf>0.08 & trf<0.18; 
bslInd = 1;
resizeScale = 3;
filterSigma = 1.5*resizeScale;

V = V(1:nSV,:);

sp = stimPositions;
st = stimTimes;

xPos = unique(sp(:,1)); nX = length(xPos);
yPos = unique(sp(:,2)); nY = length(yPos);

% get the map in V space
fprintf(1, 'computing map in V space...\n');
rfMap = zeros(nX, nY, nSV, numel(trf));
for x = 1:nX
    for y = 1:nY
        theseStims = sp(:,1)==xPos(x) & sp(:,2)==yPos(y);
        
        periEventTimes = bsxfun(@plus, st(theseStims), trf);
        periEventV = zeros(nSV, sum(theseStims), numel(trf));
        for s = 1:nSV
            periEventV(s,:,:) = interp1(t, V(s,:), periEventTimes);
        end        
        
        mnV = squeeze(nanmean(periEventV, 2));
        rfMap(x,y,:,:) = mnV;
    end
end
%%



fprintf(1, 'computing map for each pixel...\n');
flatU = reshape(U(:,:,1:nSV), [size(U,1)*size(U,2) nSV]); % size is nPix x nSV
nPix = size(flatU,1);
flatPeakMap = reshape(mean(rfMap(:,:,:,peakInds),4), [size(rfMap,1)*size(rfMap,2) nSV])'; % size nSV x nStimLocations
flatBslMap = reshape(rfMap(:,:,:,bslInd), [size(rfMap,1)*size(rfMap,2) nSV])'; % size nSV x nStimLocations

rfMapPix = flatU*flatPeakMap - flatU*flatBslMap; % nPix x nStimLocations
rfMapPix = reshape(permute(rfMapPix, [2 1]), [nX nY nPix]); 

% Upsample each pixel's response map and find maximum

gaussFilt = fspecial('gaussian',[nY,nX],filterSigma);
tic
fprintf(1, 'upsamp ...\n');
rfMapPixUp = imresize(rfMapPix,resizeScale,'bilinear');
fprintf(1, '...and filtering...\n');
try
    fprintf(1, '  trying on gpu\n');
    rfMapPixSm = gather(imfilter(gpuArray(rfMapPixUp),gaussFilt));
catch
    fprintf(1, '  got an error, computing without gpu\n');
    rfMapPixSm = imfilter(rfMapPixUp,gaussFilt);
end
toc

%%
% fprintf(1, 'finding max...\n');
% [mc,mi] = max(reshape(rfMapPixSm,[],nPix),[],1);
% [xMax, yMax] = ind2sub(size(rfMapPixSm), mi);
% 
% xMap = reshape(xMax, [size(U,1) size(U,2)]);
% yMap = reshape(yMax, [size(U,1) size(U,2)]);

fprintf(1, 'finding center of mass...\n'); 
rfMapPixSmFlat = reshape(permute(rfMapPixSm, [3 1 2]), nPix, []);
% [xx,yy] = meshgrid(1:size(rfMapPixSm,1), 1:size(rfMapPixSm,2));
[xx,yy] = meshgrid(linspace(min(xPos), max(xPos),size(rfMapPixSm,1)), ...
    linspace(min(yPos), max(yPos),size(rfMapPixSm,2)));
xx = reshape(xx', [],1); yy = reshape(yy', [],1);


rfMapPixSmFlat = rfMapPixSmFlat.^2;

cy = bsxfun(@rdivide, rfMapPixSmFlat*xx, sum(rfMapPixSmFlat,2));
cx = bsxfun(@rdivide, rfMapPixSmFlat*yy, sum(rfMapPixSmFlat,2));
xMap = reshape(cx, [size(U,1) size(U,2)]);
yMap = reshape(cy, [size(U,1) size(U,2)]);

figure;
subplot(1,2,1); 
imagesc(xMap);
title('horizontal RF position');
colorbar
axis off
subplot(1,2,2); 
imagesc(yMap);
title('vertical RF position');
colorbar
axis off
% ok, finally this looks pretty ok

%% Calculate and plot sign map (do this just with dot product between horz / vert grad?)
% This cell, code by A. Peters

% 1) get gradient direction
% [Vmag,Vdir] = imgradient(imgaussfilt(yMap,1));
% [Hmag,Hdir] = imgradient(imgaussfilt(xMap,1));
[Vmag,Vdir] = imgradient(yMap);
[Hmag,Hdir] = imgradient(xMap);

% 3) get sin(difference in direction) if retinotopic, H/V should be
% orthogonal, so the closer the orthogonal the better (and get sign)
angle_diff = sind(Vdir-Hdir);

signMap = imgaussfilt(angle_diff,1);

f = figure;set(f, 'Color', 'w');
subplot(1,2,1)
imagesc(signMap);
axis off;
title('Visual sign field');

ax = subplot(1,2,2);

im = imagesc(signMap);
set(im, 'AlphaData', mimg, 'AlphaDataMapping', 'scaled');
set(ax, 'Color', 'k');
set(ax, 'XTickLabel', '', 'YTickLabel', '');
box off