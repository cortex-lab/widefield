

function targetFrame = determineTargetFrame(datFile, imageSize, nFr, regOps)


imgInds = 1:ceil(nFr/regOps.NimgFirstRegistration):nFr; % want these frames, evenly distributed from the recording

m = memmapfile(datFile, 'Format', {'int16' [imageSize(1) imageSize(2) nFr] 'd'});

[AlignNanThresh, ErrorInitialAlign, dsprealign, targetFrame] = align_iterative(single(m.Data.d(:,:,imgInds)), regOps);

