function ops = svdROI(ops)
% ops = svdROI(ops)
%
% Makes average image from movie, promts for drawn ROI
% makes ops.roi field which is applied in SVD (outside ROI set to zero)

[im_file,im_path] = uigetfile('*.tif','Choose movie to draw ROI over');
im_filename = [im_path filesep im_file];

imageinfo=imfinfo(im_filename,'tiff');
numframes=length(imageinfo);
M=imageinfo(1).Height;
N=imageinfo(1).Width;

im_avg = zeros(M,N);
disp('Making average image...');
for frame = 1:numframes
    curr_frame = imread(im_filename,'tiff',frame,'Info',imageinfo);
    im_avg = im_avg +  double(curr_frame)./numframes;
end
disp('Done');

im_avg_binned = binImage(im_avg,ops.binning);

% Choose ROI
h = figure;
draw_roi = true;
while draw_roi;
    imagesc(im_avg_binned);
    set(gca,'YDir','normal');
    colormap(gray);
    caxis([0 std(im_avg_binned(:))]);
    roiMask = roipoly;
        
    hold on
    first_nonzero = find(roiMask > 0,1);
    [y_nonzero x_nonzero] = ind2sub([size(im_avg_binned,1), ...
        size(im_avg_binned,2)],first_nonzero);
    roi_perim = bwtraceboundary(roiMask,[y_nonzero x_nonzero],'N');
    roi = plot(roi_perim(:,2),roi_perim(:,1),'b','linewidth',2);
    
    keep_roi = input('Keep ROI (y/n)?','s');
    
    if strmatch(keep_roi,'y')
        close(h);
        draw_roi = false;
    else 
        delete(roi);
        hold off;
    end
    
end

ops.roi = roiMask;


