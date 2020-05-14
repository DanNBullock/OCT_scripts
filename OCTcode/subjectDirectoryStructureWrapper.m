%a wrapper for creating a group directory structure, such that all
%information necssary to perform analysis on one subject is contained
%within that subject's directory

if ~isdeployed
   addpath(genpath('/N/dc2/projects/lifebid/HCP/Dan/GitStoreDir/OCT_scripts'))
   %or an equivalent repository on brainlife should one come to exist
end

%% create directory structure
%RUN THIS IN ANOTHER SCRIPT
%the directory for the project containing all subjects
inputSubjectDirectory='/N/u/dnbulloc/Carbonate/OCT_Data/Data';
%path to file specifying centroid data
centroidCSVPath='/N/u/dnbulloc/Carbonate/OCT_Data/Location';
%temporary path for storage
targetOutputDir='/N/u/dnbulloc/Carbonate/OCT_Data/PrimaryData';
if ~isfolder(targetOutputDir)
    mkdir(targetOutputDir)
end

% create subject directory structure
createRawOCTSubjectDirectoryStructure(inputSubjectDirectory,targetOutputDir, centroidCSVPath)