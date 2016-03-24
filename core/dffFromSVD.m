

function [newU, newV] = dffFromSVD(U, V, meanImage)

[nX, nY, nSVD] = size(U);
flatU = reshape(U, nX*nY,nSVD);
flatMean = meanImage;
meanV = flatU'*flatMean;

V0 = meanV + mean(V,2);

newV= bsxfun(@minus,V,mean(V,2));

if simplerWay
        
    newU = reshape(bsxfun(@rdivide,flatU,(flatU*V0)), [nX nY nSVD]);

else
    
    % "the cleverer way" (get to use the old U?)
    normalizeMat = bsxfun(@rdivide,flatU,flatU*V0)'*flatU;
    newV = normalizeMat*newV;
    newU = U;
    
end