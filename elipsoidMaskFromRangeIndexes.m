function elipsoidMask=elipsoidMaskFromRangeIndexes(xRange,yRange,centroidXYVal,conversionXYResize,currAngle)
%  elipsoidMask=elipsoidMaskFromRangeIndexes(xRange,yRange,centroidXYVal)
%
%  This function creates a elipsoid mask (i.e. Array of 1s and 0s) centered
%  around the centroidXYVal WHICH IS PRESUMED TO BE AMONGST BOTH THE <xRange>
%  AND <yRange> VALUES.
%
%  INPUTS:
%  centroidXYVal: Two integers.  The X, Y index of the elipsoid's centroid
%  within the source data frame.  Ought to correspond to the median value
%  of <xRange> and <yRange>
%
%  xRange: the range of X coordinates spanned by the elipsoid circumscribed
%  by currDegree.  Future versions could simply have this as 2 integers
%  (min/max) or even 1 (length).
%
%  yRange: the range of Y coordinates spanned by the elipsoid circumscribed
%  by currDegree.  Future versions could simply have this as 2 integers
%  (min/max) or even 1 (length).
%
%  conversionXYResize: Two integer values.  The conversion factor for the X and Y dimensions corresponding to a single degree of eccentricity
%
%  currAngle:  The current eccentricity value associated with this elipsoid
%  object.

% Adapted from code produced by Dan Bullock and Jasleen Jolley 05 Nov 2019
% Extensive rewrite/functionalization by Dan Bullock 22 Jan 2020


%% Begin code
% set variables and perform checks
%extract centroid values
centroidXVal=centroidXYVal(1);
centroidYVal=centroidXYVal(2);

%exctract resizeValues
conversionXResize=conversionXYResize(1);
conversionYResize=conversionXYResize(2);

%set mask as empty array of boolean 0
matrixMask=false(length(yRange),length(xRange));

%probably a better way to do this than double iteration, but effective
%NOTE, THIS IS A NEAT TRICK WHEREBY WE ONLY ITERATE WITHIN THE BOX
%CONTAINING THE DEGREE RADIUS OF INTEREST.  REDUCES COMPUTATIONAL LOAD.

%THERE'S A CLEVERER WAY TO DO THIS, THAT DOESN'T INVOLVE PASSING CONVERSION
%RESIZE OR CURRENT ANGLE DATA, I JUST CANT THINK OF IT RIGHT NOW.
for iYrange=1:length(yRange)
    for iXrange=1:length(xRange)
        %gets unit displacement
        xDisp=xRange(iXrange)-centroidXVal;
        yDisp=yRange(iYrange)-centroidYVal;
        %gets degree displacement
        xDispConvert=xDisp/conversionXResize;
        yDispConvert=yDisp/conversionYResize;
        %computes hypotenuse and thus distance from centroid NOTE, THE
        %REASON WE ARE DOING THIS IS BECAUSE WE CAN ONLY COMPUTE THE
        %HYPOTENUSE IF BOTH DIMENSIONS ARE USING THE SAME UNIT MEASURE
        %AS SUCH WE HAVE TO CONVERT BACK TO DEGREES
        hypot=sqrt(xDispConvert^2+yDispConvert^2);
        %sets entry in mask to 1 if it is within the boundary of
        %<iAngles>
        matrixMask(iYrange,iXrange)=hypot<=currAngle;
    end
end

elipsoidMask=matrixMask;
end