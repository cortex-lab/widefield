function rV = SubSampleShift(V, p, q)
% function rV = SubSampleShift(V, p, q)
%
% delays the vector time series V by p qths of a sample
% (used to overlap signals from alternating colors)

%%%% NEW (interp)
rV = interp1(1:size(V,2),V',[1:size(V,2)]+(p/q))';
rV(:,end) = V(:,end);

%%%% OLD (resample: could introduce large error on last sample)
% % Transpose V to allow for conventional nSVs x nTimes input
% V = V';
% 
% meanV = mean(V);
% 
% upV = resample(double(bsxfun(@minus,V, meanV)), q, 1) ;
% 
% deciV = upV(p+1:q:end,:);
% 
% %rV = bsxfun(@plus, resample(deciV, 1, q), meanV);
% rV = bsxfun(@plus,deciV, meanV);
% 
% rV = rV';

return
