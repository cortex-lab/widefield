

function [outData, frNames] = frameGen_divide(U, V, thisData, mode)

switch mode
    case 'frames'
        % here, thisData is the current frame number
        
        outData{1} = svdFrameReconstruct(U, V{1}(:,thisData));
        outData{2} = svdFrameReconstruct(U, V{2}(:,thisData));
        outData{3} = outData{1}./outData{2};
        
    case 'pixel'
        % here, thisData is the pixel coordinates
        
        outData{1} = squeeze(U(thisData(1), thisData(2), :))' * V{1};
        outData{2} = squeeze(U(thisData(1), thisData(2), :))' * V{2};
        outData{3} = outData{1}./outData{2};
end

if nargout>1
    frNames = {'1', '2', '1./2'};
end