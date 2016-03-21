function newV = ChangeU(U, V, newU)
% newV = ChangeU(U, V, newU)
%
% given a SVD-compressed movie (U,V), and a new set of basis functions newU,
% find newV such that (newU, newV) represents the same movie.

[ySize, xSize, nSVD] = size(U);
Uflat = reshape(U, [ySize*xSize, nSVD]);
newUflat = reshape(newU, [ySize*xSize, nSVD]);
newV = Uflat'*newUflat*V;
