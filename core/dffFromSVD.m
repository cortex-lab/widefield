function [newU, newV] = dffFromSVD(U, V, meanImage)
% function [newU, newV] = dffFromSVD(U, V, meanImage)
% Function by K. Harris, edited by N. Steinmetz
% (and later by AP)

assert(nargout==2, 'behavior of dffFromSVD has changed, you must take new U and new V\n');

% Get the mean image in U-space (meanV)
[nX, nY, nSVD] = size(U);
flatU = reshape(U, nX*nY,nSVD);
meanV = flatU'*meanImage(:);

% Define the baseline V as the reconstructed mean (meanV) + mean activity
V0 = meanV + mean(V,2);

% Define the new V as the old V with a zero-mean
newV= bsxfun(@minus,V,mean(V,2));

% Get (soft) dF/F in U-space by dividing U by average + soft
df_softnorm = median(meanImage(:))*1;
nonnormU = reshape(bsxfun(@rdivide,flatU,reshape(meanImage,[],1)+df_softnorm), [nX nY nSVD]);

% New df/f U's aren't orthonormal: re-cast df/f V's into old U space
newV = ChangeU(nonnormU,newV,U);
newU = U;

        



