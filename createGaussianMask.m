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
%set the centroid to true
blankMask([centroidXYIndx(1),centroidXYIndx(2)])=true;


%REMEMBER TO FLIP THESE
marginsX=[centroidXYIndx(1)-1,squareDim-centroidXYIndx(1)];
marginsY=[centroidXYIndx(2)-1,squareDim-centroidXYIndx(2)];

%compute radius, (just arbitraily using floor for now).
curRadius=floor(dimProportion*squareDim);

rawMask=fspecial('disk',curRadius);
rawMask=rawMask>0;

padMarginsX=marginsX-curRadius;
padMarginsY=marginsY-curRadius;

marginSumX=sum(padMarginsX)+[2*curRadius];
marginSumY=sum(padMarginsY)+[2*curRadius];

%only one of these can logically be negative
xNegatives=padMarginsX<0;
yNegatives=padMarginsY<0;

%complex check and modification of raw mask
%essentially we are shaving off part of the raw mask, which will then be
%added back on by the pad operation later, but will add zeros instead.
%also have to adjust the padMargins after this
resizeMask=rawMask;

if yNegatives(1)
    resizeDim=size(resizeMask);
    %shouldn't matter where you do this because it only alters the one that
    %isn't being used
    padMarginsY(~yNegatives)=padMarginsY(~yNegatives)+padMarginsY(yNegatives);
    resizeMask(:,1:abs(padMarginsY(1)))=[];
end

if yNegatives(2)
    resizeDim=size(resizeMask);
    %shouldn't matter where you do this because it only alters the one that
    %isn't being used
    padMarginsY(~yNegatives)=padMarginsY(~yNegatives)+padMarginsY(yNegatives);
    %you have to add one to ensure correct indexing?
    %Coder's note:  this was SHOCKINGLY difficult to diagnose
    resizeMask(:,[[resizeDim(2)-abs(padMarginsY(2))]+1]:end)=[];
end

if xNegatives(1)
    %shouldn't matter where you do this because it only alters the one that
    %isn't being used
    padMarginsX(~xNegatives)=padMarginsX(~xNegatives)+padMarginsX(xNegatives);
    resizeMask(1:abs(padMarginsX(1)),:)=[];
end

if xNegatives(2)
    %shouldn't matter where you do this because it only alters the one that
    %isn't being used
    padMarginsX(~xNegatives)=padMarginsX(~xNegatives)+padMarginsX(xNegatives);
    resizeDim=size(resizeMask);
    %you have to add one to ensure correct indexing?
    %Coder's note:  this was SHOCKINGLY difficult to diagnose
    resizeMask([[resizeDim(1)-abs(padMarginsX(2))]+1]:end,:)=[]; 
end

%are the x and y conventions right for this?
beforePad=padarray(resizeMask,[abs(padMarginsX(1)),abs(padMarginsY(1))],'pre');
fullPad=padarray(beforePad,[abs(padMarginsX(2)),abs(padMarginsY(2))],'post');

end