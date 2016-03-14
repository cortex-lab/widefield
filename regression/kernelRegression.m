

function [fitKernels, predictedSignals, cvErr] = kernelRegression(inSignal, t, eventTimes, eventValues, windows, lambda, cvFold)
% function [fitKernels, predictedSignals] = kernelRegression(inSignal, t, eventTimes, eventValues, windows, lambda, cvFold)
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
% -- lambda is a scalar, the regularization amount. 0 to do no
% regularization
% -- cvFold is 2 by 1, [foldSize, nToCalculate]. So [5 5] does 5-fold CV
% and calculates the error on all five of the test sets. [5 1] still holds
% out 20% but only does this once. 
%
% fit_kernels is a cell array of nS by nW fit kernels
%
% Some future version of this function could allow uneven sampling of the
% input signal, but this one doesn't. 
%
% TODO: 
% - for cases in which the events have values, should also fit an
% "intercept" for the same event with values 1
% - Some future version could also allow for fitting as a sum of basis
% functions rather than this simplified "1's" method

Fs = 1/mean(diff(t));
nT = length(t);
nSig = size(inSignal,1);

if nargin<6
    lambda = 0; % if this is non-zero, does ridge regression
    cvFold = [0 0]; % number of folds of cross-validation to do
end

% this is the function used to evaluate the cross validated error. Should
% return nSig x 1, the performance on each signal to be predicted.
% cvEvalFunc = @(pred, actual)1-mean(mean((pred-actual).^2))/mean(mean(actual.^2));
cvEvalFunc = @(pred, actual)1- var(pred-actual); % here assume variance of actual is 1 - it is (or is close) if data were zscored. Otherwise you'd want to divide by it

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
        A(end+1:end+nWinSamps(ev),csWins(ev)+1:csWins(ev)+nWinSamps(ev)) = diag(lambda*ones(1,nWinSamps(ev)));
    end
    
end

if cvFold(1)>0
    
    cvp = cvpartition(nT,'KFold', cvFold(1));
    cvErr = zeros(nSig,cvFold(2));
    for k = 1:cvFold(2)
        fprintf(1, 'cvFold %d/%d\n', k, cvFold(2))
        if lambda>0
            % if using regularization, you want the regularization rows to
            % always be part of training
            trainInds = vertcat(cvp.training(k), true(size(inSignal,2)-nT,1));
        else
            trainInds = cvp.training(k);
        end
        
        testInds = cvp.test(k);
        
        trainSetObservations = inSignal(:,trainInds);
        trainSetPredictors = A(trainInds,:);
        X = solveLinEq(trainSetPredictors,trainSetObservations'); % X becomes nWinSampsTotal by nS 
    
        predictedSignals = (A(testInds,:)*X);
        testSetObservations = inSignal(:,testInds)';
        cvErr(:,k) = cvEvalFunc(predictedSignals, testSetObservations);
    end
    
else
    X = solveLinEq(A,inSignal'); % X becomes nWinSampsTotal by nS
    cvErr = [];
end

for ev = 1:length(eventTimes)
    fitKernels{ev} = X(csWins(ev)+1:csWins(ev+1),:);
end

predictedSignals = [];
if nargout>1
    % return the predicted signal, given the kernels
    predictedSignals = (A(1:nT,:)*X)';
end


function X = solveLinEq(A, B)
% This is just mldivide, but it turns out to be faster, empirically, to
% make the variables gpuArrays and use pinv instead. 

gA = gpuArray(single(A));
gB = gpuArray(single(B));
X = gather(pinv(gA)*gB);

% X = A\B;

