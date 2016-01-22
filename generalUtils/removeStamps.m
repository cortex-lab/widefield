

function data = removeStamps(data, hasASCIIstamp, hasBinaryStamp)
% remove time/frame stamps from pco edge 5.5 cameras

if hasASCIIstamp
    % remove the timestamp data
    data(1:8,1:292,:) = 0;
elseif hasBinaryStamp
    % remove the timstamp data
    data(1,1:20,:) = 0;
end