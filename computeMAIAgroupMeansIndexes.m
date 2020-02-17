function[indexMeanTable, indexStdTable]=computeMAIAgroupMeansIndexes(MAIAdirTable,keyFile)
%[indexMeanTable]=computeMAIAgroupMeansIndexes(MAIAdirTable,keyFile)
%
%  This function computes the index-wise mean and standard deviation for
%  each group indicated in the keyFile
%
%  INPUTS
%
%  MAIAdirTable=A table containg subjectID, eye, and all index info for all subjects in
%  the input directory.  Obtained from MAIAdirArray.m
%
%  keyFile:  Path to the file/directory containing information about group
%  membership.  Currently, due to how this project has been set up, these
%  are stored as N number of excel files which contain a single column of
%  subject IDs corresponding to group membership in the group sharing the
%  title of the file itself.  I suspect there are other schemas for doing
%  this, and the function that parses this ought to be able to contend with
%  this.  Eventually.  Not currently though.
%
%  OUTPUTS
%
%  indexMeanTable:  A groupwise table for the mean values from the input
%  table and keyfile
%
%  indexStdTable:  a corresponding table for the standard deviation
%
%  Dan Bullock 16 Feb 2020
%%  Begin code

[subjectID, indexVec, groupNames]=parseInputGroupKey_v1(keyFile);

outMeanDataArray=[];
outStdDataArray=[];
groupLabels=[];
eyeLabels=[];

dataSize=size(MAIAdirTable);


for iGroups=1:length(groupNames)
    %get the current group name
    currentGroup=groupNames{iGroups};
    
    %find the subject IDs corresponding to this group
    currentSubjects=subjectID(indexVec==iGroups);
    
    %find the indexes in the data Table corresponding to these subjects
    tableIndexes=ismember(MAIAdirTable.subjectID,currentSubjects);
    
    %Lets be agnostic,because why not
    curUniqueEyeIDs=unique({MAIAdirTable.eye{tableIndexes}});
    
    %same method for generating string nums as before, except -3 because of
    %name and eye addition
    numCellString=cellfun(@num2str,(num2cell(0:dataSize(2)-3)),'UniformOutput',false);
    %create vector for node names
    nodeNames=strcat('index',numCellString);
    
    %initialize vector for current group
    currentGroupMeanArray=zeros(length(curUniqueEyeIDs),length(nodeNames));
    currentGroupStdArray=currentGroupMeanArray;
    
    %loop across nodes
    for iNodes=1:length(nodeNames)
        %extract the current column
        currentIndexColumn=MAIAdirTable.(nodeNames{iNodes});
        
        %iterate over eyes.  You know, in case there are people with three
        %eyes.
        %just in case eye stuff gets strange
        EyeNodeMean=[];
        EyeNodeStd=[];
        for iEyes=1:length(curUniqueEyeIDs)
            %find indexes for current eye
            curEyeIndexes=strcmp(MAIAdirTable.eye,curUniqueEyeIDs{iEyes});
            
            %for debugging and readability we create this intermediry
            curRowIndexes=find(curEyeIndexes&tableIndexes);
            currEyeValues=currentIndexColumn(curRowIndexes);
            
            %find mean and std for current subjects, eye, and node
            
            EyeNodeMean(iEyes)=nanmean(currentIndexColumn(curEyeIndexes&tableIndexes));
            EyeNodeStd(iEyes)=nanstd(currentIndexColumn(curEyeIndexes&tableIndexes));
        end
    %place results in current array
    currentGroupMeanArray(:,iNodes)=EyeNodeMean';
    currentGroupStdArray(:,iNodes)=EyeNodeStd';
    end

        %if its the first group and its empty, set it, otherwise, cat it
    if isempty(outMeanDataArray)
        outMeanDataArray=currentGroupMeanArray;
        outStdDataArray=currentGroupStdArray;
        groupLabels={currentGroup,currentGroup};
        eyeLabels=curUniqueEyeIDs;
    else
        outMeanDataArray=vertcat(outMeanDataArray,currentGroupMeanArray);
        outStdDataArray=vertcat(outStdDataArray,currentGroupStdArray);
        groupLabels=horzcat(groupLabels,{currentGroup,currentGroup});
        eyeLabels=horzcat(eyeLabels,curUniqueEyeIDs);
    end
    clear currentGroupMeanArray
    clear currentGroupStdArray
    clear currentGroup
    clear curUniqueEyeIDs
end

%set them to cell array objects
meanDataCellArray=num2cell(outMeanDataArray);
stdDataCellArray=num2cell(outStdDataArray);

%copy off the input table
inputTableVarNames=MAIAdirTable.Properties.VariableNames;
outputTableVarNames=inputTableVarNames;
%reset the subjects column name
outputTableVarNames{1}='Group';

%set the table content
meanTableContent=horzcat(groupLabels',eyeLabels',meanDataCellArray);
stdTableContent=horzcat(groupLabels',eyeLabels',stdDataCellArray);

%set the output
indexMeanTable=cell2table(meanTableContent,'VariableNames',squeeze(outputTableVarNames));
indexStdTable=cell2table(stdTableContent,'VariableNames',squeeze(outputTableVarNames));
end