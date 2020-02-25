%%MAIAwrapper
%
%  USER NOTE:  Change the directory paths to the paths that are appropriate
%  for your local setup and then run this script to generate group level
%  analysis.
%
%  See https://github.com/DanNBullock/OCT_scripts/blob/master/readme.md for
%  more details
% 
%  Dan Bullock 17 Feb 2020
%% Subfunctions
%
% computeGroupMAIAmeans.m
% (other subfunctions used within this one)
%
%% Begin setup
%  Here we set the variables that will be used in the subsequent pipeline
%
%  subjectDir:  directory containing all subjects' data from MAIA device
subjectDir='/N/u/dnbulloc/Carbonate/OCT_Data/threshold_stan';
%
%  keyFile:  Path to the file/directory containing information about group
%  membership.  Currently, due to how this project has been set up, these
%  are stored as N number of excel files which contain a single column of
%  subject IDs corresponding to group membership in the group sharing the
%  title of the file itself.  I suspect there are other schemas for doing
%  this, and the function that parses this ought to be able to contend with
%  this.  Eventually.  Not currently though.
keyFile='/N/u/dnbulloc/Carbonate/OCT_Data/Groups';
%
%  meanMethod: either "rings" or "full".  This indicates whether the
%  mean of the visual field should be computed as hollow, cocentric, 1mm
%  rings (think dart board) or as a full circle/elipsoid
%  NOTE:  No longer used
%
%  outputDir:  directory in which to save the output group analysis
outputDir='/N/u/dnbulloc/Carbonate/OCT_Data/MAIAoutput';
%
%  sectionIndexes:  A cell array with integer sequences indicating which
%  indexes (from the MAIA reading) that you would like to have iteratively
%  averaged.  Must be a cell array in order to handle sequences of
%  different lenths.  EACH set sequence (i.e. a set of indexes to average
%  over) should be either by indicating a range (i.e 2:5) or enumeration
%  (i.e. 2,3,4,5) and should be terminated by a ;
sectionIndexes={2:5;6:17;18:37};
%  
computeGroupMAIAmeans(subjectDir,keyFile,sectionIndexes,outputDir);
% end of wrapper