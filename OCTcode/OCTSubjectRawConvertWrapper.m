%% Begin Wrapper script
%
%  USER NOTE:  Change the directory paths to the paths that are appropriate
%  for your local setup and then run this script to generate a conversion
%  from a group directory structure to a subject wise directory structure
%
%  See https://github.com/DanNBullock/OCT_scripts/blob/master/readme.md for
%  more details for teh overall pipeline.
%


%% generate primary data derivative
%directory containing data from device?
rawSubjDataDir = '/N/u/dnbulloc/Carbonate/OCT_Data/Data';
%directory to output layer-parsed output
targetOutputDir='/N/u/dnbulloc/Carbonate/OCT_Data/PrimaryData';
%path to file specifying centroid data
centroidCSVPath='/N/u/dnbulloc/Carbonate/OCT_Data/Location/Location.csv';

createRawOCTSubjectDirectoryStructure(rawSubjDataDir,targetOutputDir, centroidCSVPath);


%END OF Conversion CODE

