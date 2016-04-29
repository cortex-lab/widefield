function [Vout, T] = HemoCorrectLocal(U, V, Vaux, fS, FreqRange, pixSpace)
% function [Vout, T] = HemoCorrectLocal(U, V, Vaux, fS, FreqRange, pixSpace)
% 
% Does local hemodynamic correction for widefield imaging, in SVD space.
%
% U and V is an SVD representation of is the neural signal you are trying to correct
%
% Vaux is the other non-neural signals that you are using to measure hemodynmaics 
% (e.g. green channel reflectance). It should be compressed by the same U.
% Note that if these were recorded using alternating illumination, you will need to 
% resample them using SubSampleShift
%
% fS is sampling frequency. 
%
% FreqRange is the heartbeat range, in which the correction factors are estimated. 
% Default 9 to 13.
%
% pixSpace is the spacing between the pixel subgrid on which to compute the gain
% factors. Larger means faster but possibly less accurate. (Default 3)
%
% Outputs: Vout is corrected signal
% T is transformation matrix that predicts V from Vaux


% Transpose to allow for conventional nSVDs x nTimes input
V = V';
Vaux = Vaux';

if nargin<5
    FreqRange = [9 13];
end

if nargin<6
    pixSpace = 3;
end

% first subtract out means so the filters don't go nuts
zV = bsxfun(@minus, V, mean(V));
zVaux = bsxfun(@minus, Vaux, mean(Vaux));

% now filter for heart-frequency
[b, a] = butter(2,FreqRange/(fS/2));
fV = filter(b,a,zV);
fVaux = filter(b,a,zVaux);

% make the pixel subgrid and compute submatrices etc.
ySize = size(U,1); xSize = size(U,2);
Uflat = reshape(U, ySize*xSize,[]); % P x S
[pixY, pixX] = meshgrid(1:pixSpace:ySize, 1:pixSpace:xSize); 

pixInd = sub2ind([ySize, xSize], pixY, pixX);
Usub = Uflat(pixInd,:);


% compute single pixel time traces:
pixTrace = fV*Usub';
pixAux = fVaux*Usub';

% now compute regression coefficient for each pixel. Since they have mean 0, this is
% Cov(v1, v2)/var(v2), for each column

ScaleFactor = sum(pixTrace.*pixAux) ./ sum(pixAux.*pixAux);

% plot it
figure;
imagesc(1:pixSpace:xSize, 1:pixSpace:ySize,reshape(ScaleFactor, size(pixY)));
caxis([-1 1]*max(abs(ScaleFactor(:))));
colormap(colormap_blueblackred);
colorbar
title('Correction Scale factor');

% now compute the corresponding V-space transformation matrix

T = pinv(Usub)*diag(ScaleFactor)*Usub;
% clickable viewer for it
transformationViewerSVD(U,T);
caxis([-1 1]*3e-4); % you probably need to set this by hand, or add scale changing to the viewer
set(gcf, 'name', 'Hemodynamic correction transformation matrix');

% now make the prediction
Vout = V - zVaux*T';

% compute variance explained - first for heart signal
hPow = sum(fV(:).^2);
fVcor = fV - fVaux*T';
hPowcor = sum(fVcor(:).^2);
fprintf('Heart frequency: %f percent variance explained\n', 100*(hPow-hPowcor)/hPow);

% now for >.1Hz signal (because otherwise constant screws things up)
[b1 a1] = butter(2,.1/(fS/2), 'high');
f1V = filter(b1,a1,zV);
f1Vaux = filter(b1,a1,zVaux);
f1Pow = sum(f1V(:).^2);
f1Vout = f1V - f1Vaux*T';
f1Powcor = sum(f1Vout(:).^2);
fprintf('Above .1Hz: %f percent variance explained\n', 100*(f1Pow-f1Powcor)/f1Pow);

% Transpose to return conventional nSVs x nTimes output
Vout = Vout';
