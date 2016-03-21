function [V, Wts] = HemoCorrectNonlocal(V1, V2, fS, FreqRange)
% function V = HemoCorrect(V1, V2, fS, FreqRange)
% 
% predicts the vector timeseries V1 from the vector timeseries V2, then
% removes this prediction.
%
% Use this to correct widefield imaging from hemodynamics.
%
% If you supply fS and FreqRange, it will compute the prediction in this
% frequency range. (But apply the prediction it to all frequencies).
%
% note that if you need to resample them, you have to do that yourself
% use the function SubSampleShift

% first subtract out means - we are not going to predict those.
zV1 = bsxfun(@minus, V1, mean(V1));
zV2 = bsxfun(@minus, V2, mean(V2));

if nargin>=4 % filter if parameters supplied
    [b, a] = butter(2,FreqRange/(fS/2));

    fV1 = filter(b,a,zV1);
    fV2 = filter(b,a,zV2);
else
    fV1 = zV1;
    fV2 = zV2;
end

Wts = fV2\fV1;

V = V1 - zV2*Wts;