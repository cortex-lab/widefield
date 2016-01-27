function [U1, V1] = reSVD(U, V)
% function [U1, V1] = reSVD(U, V)
%
% recomputes an SVD for a matrix factorized matrix X = U*V
% assuming U is orthogonal, but not V. 
%
% use this after doing something like time-filtering a SVD-compressed movie.
%
% U can have more than 2 dimensions, but the last one should have the
% same size as the first dimension of V

% first do a SVD on V
[u2, s2, v2] = svd(V,'econ');

% now create the new V
V1 = s2*v2';

% for U it is a bit more complicated since we need to resize it:
sizeU = size(U);
newSizeU = [prod(sizeU(1:end-1)), sizeU(end)];

reshapeU = reshape(U, newSizeU);
reshapeU1 = reshapeU*u2;

U1 = reshape(reshapeU1, sizeU);