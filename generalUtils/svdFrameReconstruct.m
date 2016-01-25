

function frameRecon = svdFrameReconstruct(U, V)
% function frameRecon = svdFrameReconstruct(U, V)
% U is Y x X x nSVD
% V is nSVD x nFrames

% reshape U to be nPix x nSVD
Ur = reshape(U, size(U,1)*size(U,2), size(U,3));

% multiply and reshape back into Y x X
frameRecon = reshape(Ur*V, size(U,1), size(U,2), size(V,2));