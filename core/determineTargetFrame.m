

function targetFrame = determineTargetFrame(datFile, imageSize, nFr, regOps)


if ops.verbose
    fprintf(1, 'determining target image\n');
end

imgInds = 1:ceil(nFr/regOps.NimgFirstRegistration):nFr; % want these frames, evenly distributed from the recording

m = memmapfile(datFile, 'Format', {'int16' [imageSize(1) imageSize(2) nFr] 'd'});

[AlignNanThresh, ErrorInitialAlign, dsprealign, targetFrame] = align_iterative(m.Data.d(:,:,imgInds), regOps);

