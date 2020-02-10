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

%quick implementation of smooth
if ~isempty(smoothParam)
    %apparently this can be a non isometric gaussian.  It was there the
    %whole time!
    currentAnalysisData=imgaussfilt(currentAnalysisData,'FilterSize',smoothParam);
else
    %do nothing, no smooth
end

%extract array size of data
currentDataSize=size(currentAnalysisData);

%we need to interpolate the new centroid as well
centerTrue=false(currentDataSize);
centerTrue(centroidXYVal(2),centroidXYVal(1))=true;

largestDimSize=currentDataSize(max(currentDataSize)==currentDataSize);
%% implement img resize here
imageSquareForm=imresize(currentAnalysisData,[largestDimSize,largestDimSize]);

%also resize the centerTrue to find the resized centroid
centerSquareForm=imresize(centerTrue,[largestDimSize,largestDimSize]);
[centerResizeY,centerResizeX]=find(centerSquareForm);
%We get multiple returns for centerResizeY, but only one for centerResizeX
%because that dimension of the data didn't change.  Here we impliment a
%heuristic for choosing the appropriate Y value.  Given that matlab is a 1
%indexed system and thus, data in the x indexed spot in in array is mapped
%to anything corresponding to x:x-1 (but exclusive to x-1).
centerYIndexResize=ceil(mean(centerResizeY));

%just pick the first centerResizeX because they should all be the same
resizeXYCentroid=[centerResizeX(1),centerYIndexResize];

%note the flipped weirdness of 2 corresponding to x and 1 corresponding to
%y
degreeWidth=floor(largestDimSize/[visFieldRadiusLimit*2]);
ringBorders=degreeWidth:degreeWidth:[largestDimSize/2];


%doing this a bit differently to avoid asymetry issues, taking code
%from the mask creation function

initialMarginsX=[resizeXYCentroid(1)-1,largestDimSize-resizeXYCentroid(1)];
initialMarginsY=[resizeXYCentroid(2)-1,largestDimSize-resizeXYCentroid(2)];

for iAngles=1:visFieldRadiusLimit
    
    %compute mask for current degree
    
    %when the centroid is sufficiently off center, and the degree is
    %sufficiently high, these will start getting negative
    currentMarginsX=initialMarginsX-ringBorders(iAngles);
    currentMarginsY=initialMarginsY-ringBorders(iAngles);
    
    %this is setting a 50% threshold on the asymetry value, you could play
    %with it if you wanted by adjusting the quantity represnted by [degreeWidth/2]
    halfTestX=currentMarginsX+[degreeWidth/2];
    halfTestY=currentMarginsY+[degreeWidth/2];
    
    %  implement check for 50% asymetry and enter NaN value if detected
    if any(halfTestX<0)
        warning('50 percent or greater asymetry detected in X dimension for angle %i in subject \n %s \n entering NaN value in mean table',iAngles,subjectLayersCSVpath)
        maskedMeans(iAngles)=NaN;
        maskedStds(iAngles)=NaN;
    elseif any(halfTestY<0)
        warning('50 percent or greater asymetry detected in X dimension for angle %i in subject \n %s \n entering NaN value in mean table',iAngles,subjectLayersCSVpath)
        maskedMeans(iAngles)=NaN;
        maskedStds(iAngles)=NaN;
    else
        
        %just make a warning if an asymetry is detected
        if any(currentMarginsX<0)
            warning('asymetry less than 50 percent detected in X dimension for angle %i in subject \n %s \n computing mean despite asymetry',iAngles,subjectLayersCSVpath)
        elseif any(currentMarginsY<0)
            warning('asymetry detected less than 50 percent in X dimension for angle %i in subject \n %s \n computing mean despite asymetry',iAngles,subjectLayersCSVpath)
        end
        
        
        currentMask=createGaussianMask(largestDimSize,[ringBorders(iAngles)/largestDimSize],resizeXYCentroid);
        
        
        if strcmp(meanShape,'rings')
            %only need to do this for angles greater than one.
            if iAngles>1
                
                
                %reobtain mask from previous angle
                previousMask= createGaussianMask(largestDimSize,[ringBorders(iAngles-1)/largestDimSize],resizeXYCentroid);
                
                
                %hollow out the mask
                currentMask=and(currentMask,~previousMask);
                
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
        
        
        
        %from this subset, computes the mean and standard deviation
        maskedMeans(iAngles)=nanmean(imageSquareForm(currentMask));
        maskedStds(iAngles)=nanstd(imageSquareForm(currentMask));
        
    end
end

end