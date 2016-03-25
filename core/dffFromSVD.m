

function newV = dffFromSVD(U, V, meanImage)
% function newV = dffFromSVD(U, V, meanImage)
% Function by K. Harris, edited by N. Steinmetz


[nX, nY, nSVD] = size(U);
flatU = reshape(U, nX*nY,nSVD);
meanV = flatU'*meanImage(:);

V0 = meanV + mean(V,2);

newV= bsxfun(@minus,V,mean(V,2));

% Here the "simpler way" produces a new U and new V, where as "cleverer
% way" produces just a new V that keeps the old U. As this function is
% currently only returning new V, you MUST use cleverer way. In my test,
% they came roughly equal. 
simplerWay = false; 
if simplerWay
        
    newU = reshape(bsxfun(@rdivide,flatU,(flatU*V0)), [nX nY nSVD]);

else
    
    % "the cleverer way" (get to use the old U?)
    normalizeMat = bsxfun(@rdivide,flatU,flatU*V0)'*flatU;
    newV = normalizeMat*newV;
    %newU = U;
    
end