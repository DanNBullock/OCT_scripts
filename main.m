%a main.m wrapper for OCT data analysis on brainlife

if ~isdeployed
   addpath(genpath('/N/dc2/projects/lifebid/HCP/Dan/GitStoreDir/OCT_scripts'))
   %or an equivalent repository on brainlife should one come to exist
end

% Load the files from config.json
config = loadjson('config.json');

%these are the layers we want to analyse with the associated names
%These are specified by user
%layerIndexSequences={1:7,1:4,5,6};
layerIndexSequences=config.layerIndexSequences;

%Is there a better way to obtain these?
%these are the given layer combination names
%perhaps we could just assign them arbitrary numerical names in order to
%reduce the number of user inputs?
%analysesNames={'TT','NL','ONL','PROS'};
analysesNames=config.analysesNames;

%check for input length agreement
if ~length(layerIndexSequences)==length(analysesNames)
    error('layerIndexSequences and analysesNames are of different lenghts')
else
    fprintf('\n %i output analsis files to create per subject')
end

%this is just a guess, maybe soichi has a better preference
targetOutputDir=pwd;

%previously it was thought that this would need to be composed to be
%applied on a single subject basis, however, because eyes were essentially
%treatated as separate subjects, it was robust against this, and no
%decomposition is necessary.  Just ensure the [rawSubjDataDir] has both raw
%eye csv data files in it.  Heck, you don't even need both, it'd be fine
%with just one.

createCSVsumOutputFiles(rawSubjDataDir,targetOutputDir,layerIndexSequences,analysesNames)


%visual field width in degrees, i.e. diameter of visual field measured
%currently specified by user, but maybe there is a better way to infer this
%from the centroid csv data?
%visFieldDiam=20;
visFieldDiam=config.visFieldDiam;

%specify how you would like the iterative mean computed, either as either "rings" or "full".  This indicates whether the
%  mean of the visual field should be computed as hollow, cocentric, 1mm
%  rings (think dart board) or as a full circle/elipsoid.
%
%  smoothParam:  smoothing kernel to apply to <subjectLayersCSVpath> data.
%  If variable is empty, no smoothing is applied.
%
%  threshFloor:  floor threshold value for data in <subjectLayersCSVpath>
%  data.  Values below floor are set to NaN and not computed in averages.
%theshFloor=20;
theshFloor=config.theshFloor;

%gaussKernel=3;
gaussKernel=config.gaussKernel;

%meanShape='rings';
meanShape=config.meanShape;

%figure out what to do about centroidCSVPath
analyzeOCTDataWrapper(outdir,targetOutputDir,centroidCSVPath,visFieldDiam,meanShape,gaussKernel,theshFloor)


