function elipsoidMask=elipsoidMaskFromProportion(XYproportion,MaxDimSize,fieldProportion,ClipArrayOut)
%elipsoidMask=elipsoidMaskFromDataShape(dataShape,centroidXYVal,fieldProportion)
%
%
%  INPUTS
%
%  XYproportion:  diameter of elipsoid's X dimension maximum, divided by
%  the diameter of elipsoid's Y dimension maximum
%
%  MaxDimSize:  Sets the ouput dimensions by pegging the <elipsoidMask> max
%  unit dimension at this value.  Must be a positive,ODD, non-zero integer.
%
%  Field Proportion:  the proportion of the radius that this mask is to be
%  extended to
%
%  ClipArrayOut:  boolean indicating whether or not to clip the minimum
%  axis such that there are no full row/columns without non-zero entries.
%
%  OUTPUTS
%
%  elipsoidMask:  an elipsoidal mask, with 1s and 
%
%  Created by Dan Bullock 24 Jan 2020
%%  begin code

if  ~isreal(MaxDimSize) && rem(MaxDimSize,1)==0 
    error('non integer input for MaxDimSize')
elseif MaxDimSize==0
    error('zero input for MaxDimSize')
elseif ~rem(MaxDimSize,2)==1
      error('even input for MaxDimSize, must input odd integer')
end

blankMask=zeros(MaxDimSize);

centroid(1:2)=ceil(MaxDimSize/2);

indexPairings= combnk(1:MaxDimSize,2);

appendIndexes=[];

for iAppends=1:MaxDimSize
appendIndexes(iAppends,:)=[1,1]*iAppends;
end

fullIndexPairings=vertcat(indexPairings,appendIndexes);

for 1:length(fullIndexPairings)
    currDistance=sqrt(())


if XYproportion>1 % x is greater than y
    
elseif XYproportion<1 %y is greater than x
    
elseif XYproportion=1 %why are you making a circle

