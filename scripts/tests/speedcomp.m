

% Speed comparison between dat and tif
clear all
% fileBase = 'j:/fileTest/';
fileBase = 'L:\data\Dale\2016-01-21\';
% fileBase = 'W:\GCAMP\Dale\2016-01-14\1\';



%% pcoraw

clearvars -except fileBase
fprintf(1, 'testing pcoraw (imread)...\n');

nfr = 3718;
thisFile = dir([fileBase '*.pcoraw']);

tic
for nn=1:nfr
    data = imread(thisFile.name,'Index',nn);
end
    
toc

%% dat

fprintf(1, 'testing dat...\n');

thisFile = dir([fileBase '*.dat']);

tic
ySz = 720; xSz = 800; nfr = 3718;
fid = fopen(fullfile(fileBase, thisFile.name), 'r');
for nn = 1:nfr
    data = fread(fid,  ySz*xSz, '*uint16');
    data = reshape(data, ySz, xSz);
end
fclose(fid);

toc


%% tif (imread)
clearvars -except fileBase
fprintf(1, 'testing tif (imread)...\n');

theseFiles = dir([fileBase '*.tif']);

tic
for fileInd = 1%:length(theseFiles)
    
    tiffFilename = fullfile(fileBase, theseFiles(fileInd).name);
    
    InfoImage=imfinfo(tiffFilename);
    nImagesThisFile=length(InfoImage);
    
    for nn=1:nImagesThisFile
        data = imread(tiffFilename,nn);
    end
    
end
toc

%% tif (tiff object)
clearvars -except fileBase
fprintf(1, 'testing tif (Tiff object)...\n');

theseFiles = dir([fileBase '*.tif']);

tic
for fileInd = 3%:length(theseFiles)
    
    tiffFilename = fullfile(fileBase, theseFiles(fileInd).name);
    
    InfoImage=imfinfo(tiffFilename);
    nImagesThisFile=length(InfoImage);
    
    t = Tiff(tiffFilename,'r');

    for nn=1:nImagesThisFile
        t.setDirectory(nn);
        data = t.read();
    end
    t.close();

    
end
toc

%% tif (tifflib direct)
clearvars -except fileBase
fprintf(1, 'testing tif (tifflib direct)...\n');

theseFiles = dir([fileBase '*.tif']);

tic
for fileInd = 2%:length(theseFiles)
    
    tiffFilename = fullfile(fileBase, theseFiles(fileInd).name);

    InfoImage=imfinfo(tiffFilename);
    mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height;
    NumberImages=length(InfoImage);
    oneImage=zeros(nImage,mImage,'uint16');
    FileID = tifflib('open',tiffFilename,'r');
    rps = tifflib('getField',FileID,Tiff.TagID.RowsPerStrip);

    for i=1:NumberImages
       tifflib('setDirectory',FileID,i-1);
       % Go through each strip of data.
       rps = min(rps,nImage);
       for r = 1:rps:nImage
          row_inds = r:min(nImage,r+rps-1);
          stripNum = tifflib('computeStrip',FileID,r);
          oneImage(row_inds,:) = tifflib('readEncodedStrip',FileID,stripNum-1);
       end
    end
    tifflib('close',FileID);

end

toc


%% b16 individual 

tic
for fileInd = 1:3718
    filename = sprintf('test/test8_%.4d.b16', fileInd);
    imdat = svdVid.readB16(filename, 500, 688);
end
toc

%% TIFFStack

clearvars -except fileBase
fprintf(1, 'testing tif (TIFFStack)...\n');

theseFiles = dir([fileBase '*.tif']);

tic
for fileInd = 1:length(theseFiles)
    
    tiffFilename = fullfile(fileBase, theseFiles(fileInd).name);

    t = TIFFStack(tiffFilename);
%     mImage=size(t,1);
%     nImage=size(t,2);
%     NumberImages=size(t,3);
%     oneImage=zeros(nImage,mImage,'uint16');
    
%     for i=1:NumberImages
%        oneImage = t(:,:,i);
%        w = warning ('off','all');
%     end    

    allImages = t(:,:,:);
    w = warning ('off','all');
end
warning(w);
toc



