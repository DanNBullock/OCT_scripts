%% Begin Wrapper script
%
%  USER NOTE:  Change the directory paths to the paths that are appropriate
%  for your local setup and then run this script to generate group level
%  analysis.
%
%  See https://github.com/DanNBullock/OCT_scripts/blob/master/readme.md for
%  more details
%
%% Subfunctions
%
% createCSVsumOutputFiles.m
% analyzeOCTDataWrapper.m
% OCTGroupAnalysisWrapper.m
%

%% generate primary data derivative
%directory containing data from device?
rawSubjDataDir = '/N/u/dnbulloc/Carbonate/OCT_Data/Data';
%directory to output layer-parsed output
targetOutputDir='/N/u/dnbulloc/Carbonate/OCT_Data/PrimaryData';
%these are the layers we want to analyse with the associated names
%These are specified by user
layerIndexSequences={1:7,1:4,5,6};
%Is there a better way to obtanin thse?
%these are the given layer combination names
analysesNames={'TT','NL','ONL','PROS'};

createCSVsumOutputFiles(rawSubjDataDir,targetOutputDir,layerIndexSequences,analysesNames)

%% create iterative, subject level means
%path to output subject+layer level analysis to
analysisMeanDir='/N/u/dnbulloc/Carbonate/OCT_Data/subjectLayerAnalyses';
%path to file specifying centroid data
centroidCSVPath='/N/u/dnbulloc/Carbonate/OCT_Data/Location/Location.csv';
%visual field width in degrees, i.e. diameter of visual field measured
%currently specified by user, but maybe there is a better way to infer this
%from the centroid csv data?
visFieldDiam=20;
%specify how you would like the iterative mean computed, either as either "rings" or "full".  This indicates whether the
%  mean of the visual field should be computed as hollow, cocentric, 1mm
%  rings (think dart board) or as a full circle/elipsoid.
%
%  smoothParam:  smoothing kernel to apply to <subjectLayersCSVpath> data.
%  If variable is empty, no smoothing is applied.
%
%  threshFloor:  floor threshold value for data in <subjectLayersCSVpath>
%  data.  Values below floor are set to NaN and not computed in averages.
theshFloor=20
gaussKernel=3

meanShape='rings';


analyzeOCTDataWrapper(targetOutputDir,analysisMeanDir,centroidCSVPath,visFieldDiam,meanShape,gaussKernel,theshFloor)

%% perform group level analysis

%specify directory containing group membership files
groupKeyDir='/N/u/dnbulloc/Carbonate/OCT_Data/Groups';
%specify desired directory for output of group analysis
groupAnalysisDir='/N/u/dnbulloc/Carbonate/OCT_Data/GroupAnalysis/';

OCTGroupAnalysisWrapper(analysisMeanDir,groupKeyDir,groupAnalysisDir)

%END OF PIPELINE CODE