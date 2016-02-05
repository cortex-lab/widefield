

function [nearest, inds] = findNearestPoint(ofThese, inThese)
% function [nearest, inds] = findNearestPoint(ofThese, inThese)
% 
% Finds the value of "inThese" closest to a value of "ofThese", and the
% index of it, for all "ofThese".
%
% inThese and ofThese must both already be sorted. 


[~,ii] = sort([inThese ofThese]);
[~,ii2] = sort(ii); 

prevInds = ii2(length(inThese)+1:end)-1-(0:length(ofThese)-1);

nearest = zeros(size(ofThese));
inds = zeros(size(ofThese));

tooEarly = prevInds<1;
nearest(tooEarly) = inThese(1);
inds(tooEarly) = 1;

tooLate = prevInds>=length(inThese);
nearest(tooLate) = inThese(end);
inds(tooLate) = length(inThese);

nextDiff = abs(ofThese(~tooEarly&~tooLate)-inThese(prevInds(~tooEarly&~tooLate)+1));
prevDiff = abs(ofThese(~tooEarly&~tooLate)-inThese(prevInds(~tooEarly&~tooLate)));

nextClosest = false(size(ofThese));
prevClosest = false(size(ofThese));
nextClosest(~tooEarly&~tooLate) = nextDiff<prevDiff;
nearest(nextClosest) = inThese(nextClosest);
inds(nextClosest) = prevInds(nextClosest)+1;

prevClosest(~tooEarly&~tooLate) = nextDiff>=prevDiff;
nearest(prevClosest) = inThese(prevClosest);
inds(prevClosest) = prevInds(prevClosest);


