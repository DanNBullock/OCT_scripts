function [xRange, yRange] = computeIndexRangeForElipsoidEccDegree(centroidXYVal,dataSize,maxDegree,currDegree)
%[xRange, yRange] =
%computeIndexRangeForElipsoidEccDegree(centroidXYVal,currentDataSize,maxDegree,currDegree)
%
%This function computes the indexes of the bounding box (from within a
%larger data array) for a 2d elipsoid.  The center of the elipsoid is
%specified by centroidXYVal and is presumed to be orthogonally oriented
%relative to the data structure
%
%  INPUTs:
%
%  centroidXYVal: Two integers.  The X, Y index of the elipsoid's centroid
%  within the data frame.
%
%  currentDataSize:  Two integers.  The X and Y dimensions of the current
%  data frame.
%
%  maxDegree:  the stipulated maximum degree associated with the borders of
%  the data frame.  Alternatively, index 1 (in either dimension),
%  currentDataSize(1), and currentDataSize(2) are all presumed to
%  correspond to this same degree of ecentricity.
%
%  currDegree: integer (for now).  The current degree of ecentricity for
%  which the range is being querried
%
%  Outputs:
%
%  xRange: the range of X coordinates spanned by the elipsoid circumscribed
%  by currDegree
%
%  yRange: the range of Y coordinates spanned by the elipsoid circumscribed
%  by currDegree
%
% Adapted from code produced by Dan Bullock and Jasleen Jolley 05 Nov 2019
% Extensive rewrite/functionalization by Dan Bullock 22 Jan 2020
%% Begin Code
%  setting variables and performing checks

%extract degree index iteration conversion from input data
conversionResizeX=floor(dataSize(1)/(maxDegree*2));
conversionResizeY=floor(dataSize(2)/(maxDegree*2));

%extract centroid values
centroidXVal=centroidXYVal(1);
centroidYVal=centroidXYVal(2);

%extract dataframe dimensions
dataXSize=dataSize(1);
dataYSize=dataSize(2);


%%  Begin conversion computations
xRadius=conversionResizeX*currDegree;

%computes the disparity between our ability to index in to the data
%structure at regularly spaced integer values and and the assumption that
%the dimensions of <currentDataSize> correspond EXACTLY to 20 degrees of
%visual angle
xRemainder=currDegree*[1/[maxDegree*2]]*dataXSize-conversionResizeX*currDegree;
%this condition will likely never occur in the X dimension, but it is
%included here just for the sake of symmetry IT MAY ACTUALLY BE MORE
%STATISTICALLY VALID TO DO THIS WHEN xRemainder >= .5*conversionResizeX, as
%this would indicate that more is in the next degree of visual angle than
%the current one.
if xRemainder >= conversionResizeX %if the remainder is larger than the size of a degree of visual angle
    xRadius=xRadius+floor(xRemainder/conversionResizeX); %Go ahead and iterate upto the next ring %
end

%same for y.
yRadius=conversionResizeY*currDegree;
yRemainder=currDegree*[1/[maxDegree*2]]*dataYSize-conversionResizeY*currDegree;
%IT MAY ACTUALLY BE MORE STATISTICALLY VALID TO DO THIS WHEN yRemainder >=
%.5*conversionResizeY, as this would indicate that more of the pixels being
%averaged across are in the next degree of visual angle than the current
%one.

%THIS IS A FIX FOR THE LACK OF GRANULARITY IN THE Y DIMENSION.  We probably
%dont encounter this issue in the x dimension
if yRemainder >= conversionResizeY
    yRadius=yRadius+floor(yRemainder/conversionResizeY);
end

%sets the indexes for the y and x ranges, using the radius and the centroid
%values
yRange=[centroidYVal-yRadius:centroidYVal+yRadius];
xRange=[centroidXVal-xRadius:centroidXVal+xRadius];


%implement check here, this is to compensate for extreme eccentricity of
%centroid.  Resets boundaries if they are too extreme.  Note, this results
%in an asymetric mean being computed.
if or(any(xRange<0),any(xRange>dataXSize))
    warning('\n angle %i for current data structure exceeds range -- check centroid eccentricity for x',currDegree)
    xRange=xRange(and(xRange>0,xRange<dataXSize));
else
    %do nothing
end

if or(any(yRange<0),any(yRange>dataYSize))
    warning('\n angle %i for current data structure exceeds range -- check centroid eccentricity for y',currDegree)
    yRange=yRange(and(yRange>0,yRange<dataYSize));
else
    %do nothing
end

end