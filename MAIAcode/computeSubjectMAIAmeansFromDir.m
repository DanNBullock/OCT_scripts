function computeSubjectMAIAmeansFromDir(MAIAdataDir,sectionIndexes,keyfile,outputDir)

%  INPUTS
%
%  MAIAdataDir:  path to a directory containing MAIA data
%
%  sectionIndexes:  A cell array with integer sequences indicating which
%  indexes (from the MAIA reading) that you would like to have iteratively
%  averaged.  Must be a cell array in order to handle sequences of
%  different lenths.
%
%  keyfile:  an optional input which indicates group membership.  If not
%  input, will not be include in output table.  This can be a path to the
%  file/directory containing information about group membership.
%  Currently, due to how this project has been set up, these are stored as
%  N number of excel files which contain a single column of subject IDs
%  corresponding to group membership in the group sharing the title of the
%  file itself.  I suspect there are other schemas for doing this, and the
%  function that parses this ought to be able to contend with this.
%  Eventually.  Not currently though.
%
%  outputDir:  directory in which to save the output group analysis
%
%  OUTPUTS
%  none, saves down output
%
%  Dan Bullock  15 Feb 2020 
%  Edited to provide intermediary subject-level output Dan Bullock 13 May
%  2020
%%  Begin Code

%make the output dir if it doesn't exist
if ~isfolder(outputDir)
    mkdir(outputDir)
end
%% get directory level table
%get the group level data table
[MAIAdirTable] = MAIAdirArray(MAIAdataDir);

%% compute subject wise means
%compute the iterative means for each individual
meansTable =computeMAIAsubjectMeansDegrees(MAIAdirTable,sectionIndexes);

%% augment with keyfile
%augment table with group membership if available
if ~isempty(keyfile)
    %create a blank vector
    groupLabel=[];
    %parse the keyfile/keydirectory
    [subjectID, indexVec, groupNames]=parseInputGroupKey_v1(keyfile);
    %extract the subject vector from the mean table
    tableSubjects=meansTable.SubjectID;
    %loop over the subjects to fill in the group column
    for iSubjects=1:length(tableSubjects)
        %find the row that corresponds to this subject
        currentSubjectGroupIndex=find(strcmp(tableSubjects{iSubjects},subjectID));
        %if its not empty, input the group label, otherwise input unknown
        if ~isempty(currentSubjectGroupIndex)            
            currentSubjectGroupLabel=groupNames{indexVec(currentSubjectGroupIndex)};
        else 
           currentSubjectGroupLabel='Unknown';
        end
        %build the column vector
        groupLabel{iSubjects}=currentSubjectGroupLabel;       
    end
    %add it to the table
    meansTable=addvars(meansTable,groupLabel','After','SubjectID','NewVariableNames','groupLabel');
end

%% merge across eyes
%find the number of unique subjects
totalSubjects=unique(meansTable.SubjectID);

%determine size of current meansTable
tableSize=size(meansTable);

%crate cell array for the output
mergedEyesTable=cell(length(totalSubjects),tableSize(2));
%loop over the subjects
for iSubjects=1:length(totalSubjects)
    %find subject index in mean table
    subjectIndexes=find(strcmp(totalSubjects{iSubjects},meansTable.SubjectID));
    
    %find index for name var
    subjecIDColumnIndex=find(strcmp(meansTable.Properties.VariableNames,'SubjectID'));
    %copy over the subject name, if applicable
    mergedEyesTable{iSubjects,subjecIDColumnIndex}=meansTable.SubjectID{subjectIndexes(1)};
    
    %find index for name var
    groupColumnIndex=find(strcmp(meansTable.Properties.VariableNames,'groupLabel'));
    %copy over the group membership, if applicable
    if ~isempty(groupColumnIndex)
    mergedEyesTable{iSubjects,groupColumnIndex}=meansTable.groupLabel{subjectIndexes(1)};
    else
        %do nothing
    end
    
    %find index for eye
    eyeColumnIndex=find(strcmp(meansTable.Properties.VariableNames,'Eye'));
    %copy over the subject name, if applicable
    mergedEyesTable{iSubjects,eyeColumnIndex}='both';
    
    %find indexes for the means and standard deviations
    for iSequences=1:length(sectionIndexes)
        %establish labels for current sequence
        currMeanSequenceLabel=strcat('sequence_',num2str(iSequences),'_mean');
        currStdSequenceLabel=strcat('sequence_',num2str(iSequences),'_std');
        
        %find indexes for the current columns
    currentMeanIndex=find(strcmp(meansTable.Properties.VariableNames,currMeanSequenceLabel));
    currentStdIndex=find(strcmp(meansTable.Properties.VariableNames,currStdSequenceLabel));  
    
    %find the mean of both eyes
    mergedEyesTable{iSubjects,currentMeanIndex}=mean(meansTable.(currMeanSequenceLabel)(subjectIndexes));
    mergedEyesTable{iSubjects,currentStdIndex}=mean(meansTable.(currStdSequenceLabel)(subjectIndexes));
    end  %end sequence loop
end  %end subject eye merge loop
    
    

%% save output

%write the tables
writetable(meansTable,fullfile(outputDir,'meansTable.csv'))
writetable(mergedEyesTable,fullfile(outputDir,'mergedEyeMeansTable.csv'))
end
