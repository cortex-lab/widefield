

function [newU, newV] = dffFromSVD(U, V, meanImage)
% function [newU, newV] = dffFromSVD(U, V, meanImage)
% Function by K. Harris, edited by N. Steinmetz

assert(nargout==2, 'behavior of dffFromSVD has changed, you must take new U and new V\n');
   

[nX, nY, nSVD] = size(U);
flatU = reshape(U, nX*nY,nSVD);
meanV = flatU'*meanImage(:);

V0 = meanV + mean(V,2);

newV= bsxfun(@minus,V,mean(V,2));

% Here the "simpler way" produces a new U and new V, where as "cleverer
% way" produces just a new V that keeps the old U. We've decided that the
% cleverer way generally adds more noise than you'd like to an
% already-noise-amplifying computation. 
simplerWay = true; 
if simplerWay
        
    newU = reshape(bsxfun(@rdivide,flatU,(flatU*V0)), [nX nY nSVD]);

else
    
    % "the cleverer way" (get to use the old U?)
    test = bsxfun(@rdivide,flatU,flatU*V0); %DS
    test(isnan(test(:))) = 0; %DS
    normalizeMat = test'*flatU;
    newV = normalizeMat*newV;
    %newU = U;
    
end