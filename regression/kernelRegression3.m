

function [fitKernels, predictedSignals] = kernelRegression3(inSignal, predictorMat, cvp, cvFold, lambda)
% function [fitKernels, predictedSignals, cvErr] = kernelRegression2(inSignal, predictorMat, cvpartitionObj, cvFold, lambda)
%
% Fits the "toeplitz regression" from Kenneth. 
%
% This version 2 expects you to provide the predictor matrix (A), size
% nTimePoints x nPredictors
%
% -- inSignal is nS by nTimePoints, any number of signals to be fit
% -- t is 1 by nTimePoints
% -- cvFold is 2 by 1, [foldSize, nToCalculate]. So [5 5] does 5-fold CV
% and calculates the error on all five of the test sets. [5 1] still holds
% out 20% but only does this once. 
%
% fit_kernels is a vector
%
% Some future version of this function could allow uneven sampling of the
% input signal, but this one doesn't. 
%
% TODO: 
% - for cases in which the events have values, should also fit an
% "intercept" for the same event with values 1
% - Some future version could also allow for fitting as a sum of basis
% functions rather than this simplified "1's" method
% - could hypothetically allow for a kernel that is super-sampled in time
% (would probably need to be using basis functions)
% - should add the ability to fit also a continuous signal, in the same way
% using a toeplitz version of the vector. Would first interpolate it to the
% frame times. 
% - need to take care of "unpredictable point" - out of range of anything -
% here rather than in inputs, since otherwise they artificially inflate cv
% scores (predict zero and get zero a lot). 

A = predictorMat; 
[nSig, nT] = size(inSignal);

if nargin<5
    lambda = 0; % if this is non-zero, does ridge regression
    cvFold = [0 0]; % number of folds of cross-validation to do
end

% if A is too long, pad inSignal with zeros (assume A has regularization
% rows)
nRowA = size(A,1);
if nRowA>nT
    inSignal(:,end+1:end+nRowA-nT) = 0;
end

if cvFold(1)>0
    
    allPred = zeros(size(inSignal));
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
        allPred(:,testInds) = predictedSignals';
    end
    
end
fprintf(1, 'all data, for kernels\n')
X = solveLinEq(A,inSignal'); % X becomes nWinSampsTotal by nS

predictedSignals = [];
if nargout>1
    if exist('allPred', 'var') % we have a cross-validated prediction
        predictedSignals = allPred(:,1:nT)';
    else
        % return the predicted signal, given the kernels
        predictedSignals = (A(1:nT,:)*X)';
    end    
    
end

fitKernels = X;

fprintf(1, 'done.\n');


function X = solveLinEq(A, B)
% equation is: A*X = B
% This is just mldivide, but it turns out to be faster, empirically, to
% make the variables gpuArrays and use pinv instead. 
X = A\B;
% try
%     gA = gpuArray(single(A));
%     gB = gpuArray(single(B));
%     X = gather(pinv(gA)*gB);
% catch 
%     fprintf('gpu didn''t work. trying without.\n');
%     X = A\B;
% end

