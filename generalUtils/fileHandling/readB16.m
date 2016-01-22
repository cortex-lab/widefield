

function imdat = readB16(filename, varargin)

fid = fopen(filename, 'r');

if ~isempty(varargin)
    % assume they passed in the image size, so skip the header
    
    ySize = varargin{1}; xSize = varargin{2};
    [~] = fread(fid, 1024, 'uint8=>uint8'); % skip the header
    imdat = fread(fid, [ySize xSize], 'uint16=>uint16')';
    
else
    
    headerDat = fread(fid, 5, 'int32=>int32');
%     pcoID = headerDat(1); % should be 760169296 == 'PCO-'
%     fileSize = headerDat(2);
%     headerLen = headerDat(3);
    width = headerDat(4);
    height = headerDat(5);
    
    [~] = fread(fid, 1004, 'uint8=>uint8');
    imdat = fread(fid, [width height], 'uint16=>uint16')';
    
end
    
fclose(fid);


% you can concatenate files with:
% system(sprintf('copy /b %s+%s %s', file1, file2, outFilename));
% (building a string that includes all files in the correct order)
% then you can read the whole stack like this:
% fid = fopen(filename, 'r');
% firstHeader = fread(fid, 256, 'int32=>int32');
% imstack = fread(fid, imageYsize*imageXsize*nImagesToRead, sprintf('%d*uint16=>uint16', imageYsize*imageXsize), 1024); 
% fclose(fid)
% imstack = reshape(imstack, imageYsize, imageXsize, nImagesToRead);
% but this doesn't gain you 