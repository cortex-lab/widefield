

function [fitKernels, predictedSignals] = kernelRegression(inSignal, t, eventTimes, eventValues, windows)
% function [fitKernels, predictedSignals] = kernelRegression(inSignal, t, eventTimes, eventValues, windows)
%
% Fits the "toeplitz regression" from Kenneth. 
%
% -- inSignal is nS by nTimePoints, any number of signals to be fit
% -- t is 1 by nTimePoints
% -- eventTimes is a cell array of times of each event
% -- eventValues is a cell array of "values" for each event, like if you want
% different instances of the event to be fit with a scaled version of the
% kernel. E.g. contrast of stimulus or velocity of wheel movement.
% -- windows is a cell array of 2 by 1 windows, [startOffset endOffset]
%
% fit_kernels is a cell array of nS by nW fit kernels
%
% Some future version of this function could allow uneven sampling of the
% input signal, but this one doesn't. 
%
% TODO: 
% - implement ridge regression with added data at the end
% - for cases in which the events have values, should also fit an
% "intercept" for the same event with values 1
% - Some future version could also allow for fitting as a sum of basis
% functions rather than this simplified "1's" method
% - test pinv as well
% - add cross-validation

Fs = 1/mean(diff(t));
nT = length(t);

lambda = 0.1; % if this is non-zero, does ridge regression
cvFold = 10; % number of folds of cross-validation to do
cvEvalFunc = @(pred, actual)var(pred-actual);

for w = 1:length(windows)
    startOffset(w) = round(windows{w}(1)*Fs);
    nWinSamps(w) = round(diff(windows{w})*Fs);
end
nWinSampsTotal = sum(nWinSamps);
csWins = cumsum([0 nWinSamps]);


A = zeros(nT,nWinSampsTotal);

for ev = 1:length(eventTimes)
    [theseET, sortI] = sort(eventTimes{ev}(:)');
    [tp, ii] = findNearestPoint(theseET, t);
    eventFrames = ii+startOffset(ev); % the "frames", i.e. indices of t, at which the start of each event's window occurs
    
    if isempty(eventValues{ev})
        theseEventValues = ones(size(eventFrames));
    else
        theseEventValues = eventValues{ev}(sortI);
    end
    
    for w = 1:nWinSamps(ev)
        theseSamps = eventFrames+w;
        inRange = theseSamps>0&theseSamps<=size(A,1);
        A(theseSamps(inRange),csWins(ev)+w) = theseEventValues(inRange);
    end
    
    if lambda>0
        inSignal(:,end+1:end+nWinSamps(ev)) = 0;
        A(end+1:end+nWinSamps(ev),csWins(ev)+1:nWinSamps(ev)) = diag(lambda*ones(1,nWinSamps(ev)));
    end
    
end

if cvFold>0
    
    cvp = cvpartition(nT,'KFold', cvFold);
    
    for k = 1:cvFold
        
        if lambda>0
            % if using regularization, you want the regularization rows to
            % always be part of training
            trainInds = [cvp.training(k) true(1, size(inSignal,2)-nT)];
        else
            trainInds = cvp.training(k);
        end
        
        testInds = cvp.test(k);
        
        trainSetObservations = inSignal(:,trainInds);
        trainSetPredictors = A(trainInds,:);
        X = trainSetPredictors\trainSet'; % X becomes nWinSampsTotal by nS 
    
        predictedSignals = (A(testInds,:)*X)';
        
        cvErr(k) = cvEvalFunc(predictedSignals, inSignal(:,testInds)');
    end
    
else
    X = A\inSignal'; % X becomes nWinSampsTotal by nS
    cvErr = [];
end

for ev = 1:length(eventTimes)
    fitKernels{ev} = X(csWins(ev)+1:csWins(ev+1),:);
end

predictedSignals = [];
if nargout>1
    % return the predicted signal, given the kernels
    predictedSignals = (A*X)';
end


