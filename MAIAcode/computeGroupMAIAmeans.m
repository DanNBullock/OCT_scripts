function computeGroupMAIAmeans(subjectDir,keyFile,sectionIndexes,outputDir)

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
%  sectionIndexes:  A cell array with integer sequences indicating which
%  indexes (from the MAIA reading) that you would like to have iteratively
%  averaged.  Must be a cell array in order to handle sequences of
%  different lenths.
%
%  meanMethod: either "rings" or "full".  This indicates whether the
%  mean of the visual field should be computed as hollow, cocentric, 1mm
%  rings (think dart board) or as a full circle/elipsoid
%  NOTE:  this input is now depricated and no longer used as the user
%  directly inputs these values in sectionIndexes
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
[meanDegreesTable, stdDegreesTable ]=computeMAIAgroupMeansDegrees(indexMeanTable, indexStdTable,sectionIndexes);

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
