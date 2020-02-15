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

%extract directory contents
inputDirContents=dir(subjectDir);

%extract the files of interest
%  GET THIS INFO FROM Jasleen
allFileNamesinput=''

namePartsStorage=cell(length(allFileNamesinput),2);

for iEntries=1:length(allFileNamesinput)
    currentSplit = split(allFileNamesinput{iEntries},'_');
    %awkward, but quick fix
    namePartsStorage{iEntries,1}=currentSplit{1};
    namePartsStorage{iEntries,2}=currentSplit{2};
end

%three vectors with unique entries to extract subject and eye info for the
%file paths
uniqueSubjs=unique({namePartsStorage{:,1}});
uniqueEyes=unique({namePartsStorage{:,2}});

allSubjectsMeanVec=[];
for iDataFiles=1:length(allFileNamesinput)
[currMeanVec]=MAIAsubjectMeanGen(subjectFilePath,meanMethod);

%potentially a problem if you run it manually but fine if you run it as a function
if isempty(allSubjectsMeanVec)
    allSubjectsMeanVec=currMeanVec;
else
    allSubjectsMeanVec=vertcat(allSubjectsMeanVec,currMeanVec);
end

end

% now compute the means here

end
