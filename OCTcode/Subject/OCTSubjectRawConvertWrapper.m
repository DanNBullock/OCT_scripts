%% Begin Wrapper script
%
%  USER NOTE:  Change the directory paths to the paths that are appropriate
%  for your local setup and then run this script to generate a conversion
%  from a group directory structure to a subject wise directory structure
%
%  See https://github.com/DanNBullock/OCT_scripts/blob/master/readme.md for
%  more details for the overall pipeline.
%


%% generate primary data derivative
% directory containing raw data from Voxelron device
rawSubjDataDir = '/N/u/dnbulloc/Carbonate/OCT_Data/Data';
% directory to output OD and OS eye data for this subject, along with
% centroid data from next inut
targetOutputDir='/N/u/dnbulloc/Carbonate/OCT_Data/PrimaryData';
% path to file specifying centroid data for this group
centroidCSVPath='/N/u/dnbulloc/Carbonate/OCT_Data/Location/Location.csv';

if ~isfolder(targetOutputDir)
    mkdir(targetOutputDir)
end

%perform conversion
createRawOCTSubjectDirectoryStructure(rawSubjDataDir,targetOutputDir, centroidCSVPath);

%END OF Conversion CODE
