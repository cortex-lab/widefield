function [newU, newV] = dffFromSVD(U, V, meanImage)
% function [newU, newV] = dffFromSVD(U, V, meanImage)
% Function by K. Harris, edited by N. Steinmetz

assert(nargout==2, 'behavior of dffFromSVD has changed, you must take new U and new V\n');
   
[nX, nY, nSVD] = size(U);
flatU = reshape(U, nX*nY,nSVD);
meanV = flatU'*meanImage(:);

V0 = meanV + mean(V,2);

newV= bsxfun(@minus,V,mean(V,2));

% Soft df/f the fluorescence in U-space
% (by a factor of 1 * the average fluorescence value, looks ok)
df_softnorm = median(meanImage(:))*1;
nonnormU = reshape(bsxfun(@rdivide,flatU,(flatU*V0)+df_softnorm), [nX nY nSVD]);

% new df/f U's aren't orthonormal: re-cast df/f V's into old U space
newV = ChangeU(nonnormU,newV,U);
newU = U;

        



