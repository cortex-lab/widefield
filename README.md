# widefield
Image processing and tools for widefield imaging


# Usage

Open pipelineScript.m, edit variables in the first cell appropriately. datPath should be on a local drive. Shouldn't need to touch anything after the first cell. 

Run that script. It will show you a plot of how the registration went; make sure it looks sensible. 

Then run: 

```svdViewer(U, Sv, V, Fs, totalVar)```

Where you have to specify Fs (the sampling rate) but the other variables are all created by the script. Use left/right arrow keys to switch which component you're looking at. Click around. 

If you're happy with all that, then you're home free.

If at any time you'd like to see the reconstruction of the raw image for a certain frame or group of frames - i.e. you'd like to go back to a yPix x xPix x nFrames stack - then:

```oneFrame = svdFrameReconstruct(U,V(:,myFrameIndex));```

```stack = svdFrameReconstruct(U,V(:,myFrameIndices));```

You can also now, e.g.:

```pixelCorrelationViewerSVD(U, V)```

If some of your SVD components had very slow timecourses (like bleaching), then you could high pass filter them at 0.01Hz or something first, sometimes this helps. 

```filtV = hpFilt(V, Fs, 0.01);```

You may also try excluding the first singular value - for me this produced the best results of the correlation map. U is yPix x xPix x nSV and V is nSV x nTimepoints so that's just:

```pixelCorrelationViewerSVD(U(:,:,2:end), V(2:end,:))```




