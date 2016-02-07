

function data = removeStamps(data, hasASCIIstamp, hasBinaryStamp)
% remove time/frame stamps from pco edge 5.5 cameras
%
% ASCII stamp is at data(1:8,1:292)
% Binary stamp is at data(1,1:20)
%
% Case is handled where image is not 292 pixels wide, but image must be at
% least 9 pixels tall and at least 20 wide

if hasASCIIstamp
    % remove the timestamp data
    if size(data,2)<=292
        data(1:8,:,:) = repmat(data(9,:,:),8,1,1);
    else        
        
        % logic here is to make a smooth extrapolation of the stamp
        % location based on the next row and next column of the image; it
        % will not be any kind of estimate of real data, the only point is
        % so there's no feature there for image registration to grab onto
        
        % how to vectorize this? 
        for fr = 1:size(data,3)
            nextCol = single(data(1:8,293,fr));
            nextRow = single(data(9,1:292,fr));
            data(1:8,1:292,fr) = uint16(nextCol*nextRow/single(data(9,293,fr)));
        end
    end
elseif hasBinaryStamp
    % remove the timestamp data. same logic as above but much simplified
    data(1,1:20,:) = data(2,1:20,:);
end