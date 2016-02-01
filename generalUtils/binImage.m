

function binnedImage = binImage(origImage, binFactor)
% function binnedImage = binImage(origImage, binFactor)
%
% Bins image (e.g. 2x2 or 4x4) by taking the average of given pixels. Input
% image size should be Ypix x Xpix x nFrames. For binFactor B, performs BxB
% binning and returns an image with nPix/B^2 pixels. Only works for
% integer B, probably.


cFilt = ones(1, binFactor)/binFactor;
for im = 1:size(origImage,3)
    q = conv2(cFilt, cFilt, origImage(:,:,im), 'same');
    b = q(1:binFactor:end,1:binFactor:end);
    if im==1
        binnedImage = zeros(size(b,1), size(b,2), size(origImage,3), 'like', origImage);
    end
    binnedImage(:,:,im) = b;
end


% % Somehow this algorithm with convn is not faster, despite seeming more
% % natural to me. 
% cFilt = ones(binFactor, binFactor)/(binFactor^2);
% q = convn(origImage, cFilt, 'same');
% binnedImage = q(1:binFactor:end,1:binFactor:end,:);
