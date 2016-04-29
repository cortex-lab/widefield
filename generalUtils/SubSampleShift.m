function rV = SubSampleShift(V, p, q);
% function Vs = SubSampleShift(V, p, q)
%
% delays the vector time series V by p qths of a sample, using MATLAB's resample
% function. Note that p and q should be positive integers (it doesn't do
% negative shifts (yet))

% Transpose V to allow for conventional nSVs x nTimes input
V = V';

meanV = mean(V);

upV = resample(double(bsxfun(@minus,V, meanV)), q, 1) ;

deciV = upV(p+1:q:end,:);

%rV = bsxfun(@plus, resample(deciV, 1, q), meanV);
rV = bsxfun(@plus,deciV, meanV);

rV = rV';

return
