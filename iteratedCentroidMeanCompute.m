function [maskedMeans,maskedStds] = iteratedCentroidMeanCompute(subjectLayersCSVpath,centroidXYVal,visFieldRadiusLimit,meanShape,smoothParam,threshFloor)
%[maskedMeans,maskedStds] = iteratedCentroidMeanCompute(subjectLayersCSVpath,centroidXYVal,visFieldRadiusLimit,smoothParam,threshFloor)
%iteratedCentroidMeanCompute(subjectLayersCSVpath,centroidXVal,centroidYVal,visFieldRadiusLimit)
%
%This function takes in a single subject's CSV output from
%createCSVsumOutputFiles/parseCsvExport for a specific layer amalgum and
%iteratively computes the mean across each degree of ecentricity.  Options
%for smoothing and thresholding to be implemented later
%
% INPUTS:
%
% subjectLayersCSVpath= path to an output csv from
% createCSVsumOutputFiles/parseCsvExport.  Will load a path as csv if
% passed.  Will skip this if a numeric array is passed.
%
%  centroidXYVal: Two integers.  The X, Y index of the foveal point within
%  the <subjectLayersCSVpath> CSV data.  Also referred to as the centroid
%  throughout.
%
%  visFieldRadiusLimit:  the putative maximum eccentricity of visual anglecovered by the
%  csv data object.  NOT THE DEGREE SPAN (i.e. diameter), but rather the
%  maximal degree itself.
%
%  meanShape:  either "rings" or "full".  This indicates whether the
%  mean of the visual field should be computed as hollow, cocentric, 1mm
%  rings (think dart board) or as a full circle/elipsoid.
%
%  smoothParam:  smoothing kernel to apply to <subjectLayersCSVpath> data.
%  If variable is empty, no smoothing is applied.
%
%  threshFloor:  floor threshold value for data in <subjectLayersCSVpath>
%  data.  Values below floor are set to NaN and not computed in averages.
%
% Adapted from code produced by Dan Bullock and Jasleen Jolley 05 Nov 2019
% Extensive rewrite/functionalization by Dan Bullock 22 Jan 2020

%% Begin Code
%set variables and perform checks

%extract the x and y centroid coordinates
centroidXVal=centroidXYVal(1);
centroidYVal=centroidXYVal(2);

% if a string is passed, load the file, if a numeric array is passed,
% assume it is the relevant data structure.
if ischar(subjectLayersCSVpath)
    currentAnalysisData=csvread(subjectLayersCSVpath);
elseif isnumeric(subjectLayersCSVpath)
    currentAnalysisData=subjectLayersCSVpath;
end

%quick implementation of thresholding
if ~isempty(threshFloor)
    currentAnalysisData(currentAnalysisData<threshFloor)=NaN;
else
    %do nothing, no thresholding
end

%extract array size of data
currentDataSize=size(currentAnalysisData);


%% implement img resize here
%imresize


%note the flipped weirdness of 2 corresponding to x and 1 corresponding to
%y
conversionResizeX=floor(currentDataSize(2)/(visFieldRadiusLimit*2));
conversionResizeY=floor(currentDataSize(1)/(visFieldRadiusLimit*2));

for iAngles=1:visFieldRadiusLimit

    %obtains x and y index range for current visual field angle
    [xRange, yRange] = computeIndexRangeForElipsoidEccDegree(centroidXYVal,[currentDataSize(2),currentDataSize(1) ],visFieldRadiusLimit,iAngles);
    
    %create mask of elipsoid using previous values
    elipsoidMask=elipsoidMaskFromRangeIndexes(xRange,yRange,centroidXYVal,[conversionResizeX,conversionResizeY],iAngles);
    
    if strcmp(meanShape,'rings')
        %only need to do this for angles greater than one.
        if iAngles>1
        
        %get dimensions of current mask     
        maskDim=size(elipsoidMask);
        
        %recompute range from previous angle
        [previousXRange, previousYRange] = computeIndexRangeForElipsoidEccDegree(centroidXYVal,[currentDataSize(2),currentDataSize(1) ],visFieldRadiusLimit,iAngles-1);
        
        %reobtain mask from previous angle
        previousElipsoidMask= elipsoidMaskFromRangeIndexes(previousXRange,previousYRange,centroidXYVal,[conversionResizeX,conversionResizeY],iAngles-1);
        
        %compute dimesnions of previous mask
        prevMaskDim=size(previousElipsoidMask);
        
        %find the difference between the dimension sizes.  Should be an
        %even number for oth values.
        dimDiff=maskDim-prevMaskDim;
        
        %compute padding needed by dividing dimDiff in half
        padVals=dimDiff/2;
        
        %pad the array with the info obtained
        expandPreviousMask= padarray(previousElipsoidMask,[padVals]);
        
        %hollow out the mask
        elipsoidMask=and(elipsoidMask,~expandPreviousMask);
        
        else
            %dont do anything different, there's no inner range of values
            %to remove.
        end
    else
        %do nothing, you're computing the mean over the entire elipsoid
        %shape.
    end
        
    %Technically at this point we no longer care where they are, just that
    %they meet the criteria for us being interested in them.  Thus create a
    %new data object from <currentAnalysisData> only containing the values
    %of interest, which also happens to correspond to the size of <elipsoidMask>
    dataSubset=currentAnalysisData(yRange,xRange);
    
    
    %from this subset, computes the mean and standard deviation
    maskedMeans(iAngles)=nanmean(dataSubset(elipsoidMask));
    maskedStds(iAngles)=nanstd(dataSubset(elipsoidMask));
end

end