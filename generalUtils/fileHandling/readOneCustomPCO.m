

function thisFrame = readOneCustomPCO(filename, frameIndex)

fid = fopen(filename, 'r');
if fid == -1, error(['Unable to open file: ' filename]); end
nRows   = fread(fid, 1, 'uint32'); % spatial resolution, n rows
nCols   = fread(fid, 1, 'uint32'); % spatial resolution, n columns
nFrames = fread(fid, 1, 'uint32');
fclose(fid);

format = { ...
    'uint32' 1 'nRows';...                % Number of rows.
    'uint32' 1 'nCows';...                % Number of columns.
    'uint32' 1 'nFrames';...              % Number of frames.
    'double' 1 'startTime';...            % Time of first frame in UNIX format.
    'uint16' [nRows nCols nFrames] 'imagedata';... % Image data.
    'double', [nFrames 1], 't'};           % Time of each frame in seconds.
m = memmapfile(filename, 'Format', format);

thisFrame = m.Data(1).imagedata(:,:,frameIndex);

end