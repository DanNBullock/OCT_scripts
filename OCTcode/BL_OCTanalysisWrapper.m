%a main.m wrapper for OCT data analysis on brainlife

if ~isdeployed
   addpath(genpath('/N/dc2/projects/lifebid/HCP/Dan/GitStoreDir/OCT_scripts'))
   %or an equivalent repository on brainlife should one come to exist
end

% Load the files from config.json
config = loadjson('config.json');

%% create layer amalgums

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

%input data directory for current subject
%example input data dir
inputDataDir=config.inputData;

%temporary path for storage for secondary data product
secondaryOutputDir=fullfile(pwd,'secondaryData');
if ~isfolder(secondaryOutputDir)
    mkdir(secondaryOutputDir)
end

%parse the input data directory and content
inputDataDirContent=dir(inputDataDir);
inputFileNames={inputDataDirContent(~[inputDataDirContent.isdir]).name};
rawFiles=inputFileNames(contains(subjectLabels,'Raw'));


%run it twice, no need to make a loop
createLayerAmalgumOutputs(fullfile(inputDataDir,rawFiles{1}),secondaryOutputDir, layerIndexSequences,analysesNames)
createLayerAmalgumOutputs(fullfile(inputDataDir,rawFiles{2}),secondaryOutputDir, layerIndexSequences,analysesNames)

%% do layer based analysis
%visual field width in degrees, i.e. diameter of visual field measured
%currently specified by user, but maybe there is a better way to infer this
%from the centroid csv data?
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
theshFloor=config.theshFloor;
gaussKernel=config.gaussKernel;

meanShape=config.meanShape;

%final output dir
finalOutputDir=fullfile(pwd,'finalOutput');
if ~isfolder(finalOutputDir)
    mkdir(finalOutputDir)
end
analyzeSubjectOCTDataWrapper(secondaryOutputDir,finalOutputDir, inputDataDir,visFieldDiameterLimit, retinaMeanToggle,[],[])



