

function stack = loadTiffStack(tiffFilename, mode)

% mode = 'tiffobj'; % options are 'imread', 'tiffobj'
% tiffobj is faster for USB-attached hard drive. 
% imread is faster for local hard drive (I think!)
% use speedcomp.m to compare

InfoImage=imfinfo(tiffFilename);
nImagesThisFile=length(InfoImage);

switch mode
    case 'imread'
    case 'tiffobj'
        t = Tiff(tiffFilename,'r');
end

stack = zeros(InfoImage(1).Height, InfoImage(1).Width, nImagesThisFile, 'uint16');

for i=1:nImagesThisFile
    if mod(i,100)==0
        fprintf(1, '  image %d\n', i);
    end
    
    switch mode
        case 'imread'
            stack(:,:,i) = imread(tiffFilename,i);
        case 'tiffobj'
            t.setDirectory(i);
            stack(:,:,i)=t.read();
    end
    w = warning ('off','all');
end

switch mode
    case 'imread'
    case 'tiffobj'
        t.close();
end


warning(w);