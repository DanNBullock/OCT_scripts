function fullPad =createGaussianMask(squareDim,dimProportion,centroidXYIndx)

%  squareDim:  the size of the diameter of the gaussian mask.  Assumes a square frame
%  of reference.
%
%  dimProportion:  0<x<1, indicates what proportion of the RADIUS (i.e. half the DIAMETER/<squareDim>) that you would like to be computed,
%
%  centroidIndx:  the X and y index of the centroid for this mask, relative
%  to the 

%% begin code


%create blank mask
blankMask=zeros(squareDim,squareDim);

%there is already weirdness in the input, because the input data is even,
%and thus the notion of a centroid is already offbase, because there are an
%even number of indexes.  How do we choose which index would be the
%centroid of the source dataArray?
inputCenter=blankMask;

%REMEMBER TO FLIP THESE
marginsX=[centroidXYIndx(1)-1,squareDim-centroidXYIndx(1)];
marginsY=[centroidXYIndx(2)-1,squareDim-centroidXYIndx(2)];

%compute radius, (just arbitraily using floor for now).
curRadius=floor(dimProportion*squareDim/2);

%set the centroid to true
blankMask([centroidXYIndx(2),centroidXYIndx(1)])=true;

rawMask=fspecial('disk',curRadius);
rawMask=rawMask>0;

padMarginsX=marginsX-curRadius;
padMarginsY=marginsY-curRadius;

beforePad=padarray(rawMask,[padMarginsY(1),padMarginsX(1)],'pre');
fullPad=padarray(beforePad,[padMarginsY(2),padMarginsX(2)],'post');
end