

function binnedImage = binImage(origImage, binFactor)
% function binnedImage = binImage(origImage, binFactor)
%
% Bins image (e.g. 2x2 or 4x4) by taking the average of given pixels. Input
% image size should be Ypix x Xpix x nFrames. For binFactor B, performs BxB
% binning and returns an image with nPix/B^2 pixels. Only works for
% integer B, probably.

cFilt = ones(binFactor, binFactor)/(binFactor^2);
q = convn(origImage, cFilt, 'same');
binnedImage = q(1:binFactor:end,1:binFactor:end,:);
