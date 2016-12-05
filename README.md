# widefield
Image processing and tools for widefield imaging


# Usage

You can see an example of how you might pre-process data by looking in pipelineHere.m. The main thing is to load your imaging data into a "flat binary file" (as you'd make with matlab's fwrite) and then putting it into get_svdcomps.m.  See the help for that function for more details.

The "get_svdcomps" function is ultimately just doing the same thing that matlab's usual "svd" function would do on an nPixels x nFrames matrix, but does a couple of things to deal with the fact that our movies will not fit in RAM (like considering clumps of frames). 

Then the only other thing that we're doing special is that, whereas normal SVD would produce U, S, and V such that:

```M = U * S * V```

where M is your movie (nPixels x nFrames), U are "spatial components" (nPixels x nComponents), S are singular values that scale the components (diagonal matrix, nComp x nComp), and V are the "temporal components" (nComp x nFrames);

instead we fold the S * V part into V for simplicity, so what we call V in the rest of the code is really S * V, and the representation of the data is just: 

```M = U * V```

Then run: 

```svdViewer(U, Sv, V, Fs, totalVar)```

Where you have to specify Fs (the sampling rate) but the other variables come from get_svdcomps. Use left/right arrow keys to switch which component you're looking at. Click around. See the help for that function for more details.  

If you're happy with all that, then you're home free.

If at any time you'd like to see the reconstruction of the raw image for a certain frame or group of frames - i.e. you'd like to go back to a yPix x xPix x nFrames stack - then:

```oneFrame = svdFrameReconstruct(U,V(:,myFrameIndex));```

```stack = svdFrameReconstruct(U,V(:,myFrameIndices));```

You can also now, e.g.:

```pixelCorrelationViewerSVD(U, V)```

If some of your SVD components had very slow timecourses, then you could high pass filter them at 0.01Hz or something first, sometimes this helps. 

```filtV = hpFilt(V, Fs, 0.01);```




