function computeGroupMAIAmeans(subjectDir,keyFile,meanMethod,outputDir)

%  INPUTS
%
%  subjectDir:  directory containing all subjects' data from MAIA device
%
%  keyFile:  Path to the file/directory containing information about group
%  membership.  Currently, due to how this project has been set up, these
%  are stored as N number of excel files which contain a single column of
%  subject IDs corresponding to group membership in the group sharing the
%  title of the file itself.  I suspect there are other schemas for doing
%  this, and the function that parses this ought to be able to contend with
%  this.  Eventually.  Not currently though.
%
%  meanMethod: either "rings" or "full".  This indicates whether the
%  mean of the visual field should be computed as hollow, cocentric, 1mm
%  rings (think dart board) or as a full circle/elipsoid
%
%  outputDir:  directory in which to save the output group analysis
%
%  Dan Bullock  15 Feb 2020 
%%  Begin Code

%make the output dir if it doesn't exist
if ~isfolder(outputDir)
    mkdir(outputDir)
end

%derive table for entire input directory
[MAIAdirTable] = MAIAdirArray(subjectDir);

%compute indexwise means for each group in the input directory
[indexMeanTable, indexStdTable]=computeMAIAgroupMeansIndexes(MAIAdirTable,keyFile);

%compute the iterative means for each group
[meanDegreesTable, stdDegreesTable ]=computeMAIAgroupMeansDegrees(indexMeanTable, indexStdTable,meanMethod);

%now we save the tables
outputFileNames={'indexMeanTable.csv','indexStdTable.csv','meanDegreesTable.csv','stdDegreesTable.csv'};

%generate the paths for those files
outputFilePaths=fullfile(outputDir,outputFileNames);

%write the tables
writetable(indexMeanTable,outputFilePaths{1})
writetable(indexStdTable,outputFilePaths{2})
writetable(meanDegreesTable,outputFilePaths{3})
writetable(stdDegreesTable,outputFilePaths{4})

end
