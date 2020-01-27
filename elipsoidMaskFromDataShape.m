function elipsoidMask=elipsoidMaskFromDataShape(dataShape,centroidXYVal,fieldProportion)
%elipsoidMask=elipsoidMaskFromDataShape(dataShape,centroidXYVal,fieldProportion)
%
%
%  INPUTS
%
%  dataShape:  The x and y dimensions of the relevant dataframe.  In
%  essence these will be converted to degree measures that will be assumed
%  to be equal to oneanother such that x_d=y_d.  In the event that x = y ,
%  this is simply a circular mask.
%
%  centroidXYVal:  The x and y indicies of the centroid of the elipse.
%
%  Field Proportion:  the proportion of the radius that this mask is to be
%  extended to
%
%  OUTPUTS
%
%  elipsoidMask:  an elipsoidal mask, with 1s and 
%
%  Created by Dan Bullock 24 Jan 2020
%%  begin code

desiredXRadius=

