

function data = removeStamps(data, hasASCIIstamp, hasBinaryStamp)
% remove time/frame stamps from pco edge 5.5 cameras
% TODO: give an option to make this continuous with the surrounding data,
% so as not to generate an edge feature. Possibly multiply the next row
% with the next column so both of those edges are [likely] continuous. 

if hasASCIIstamp
    % remove the timestamp data
    data(1:8,1:292,:) = 0;
elseif hasBinaryStamp
    % remove the timestamp data
    data(1,1:20,:) = 0;
end