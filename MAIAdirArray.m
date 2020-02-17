function [outTable] = MAIAdirArray(subjectDir)
% [outTable] = MAIAdirArray(subjectDir)
%
%  This functon reads in all of the MAIA device outputs from a directory
%  and outputs a table displaying the data for the all subjects
%
%  INPUTS
%
%  subjectDir:  directory containing all subjects' data from MAIA device
%
%  OUTPUTS
% 
%  outTable=A table containg subjectID, eye, and all index info for all subjects in
%  the input directory
%
%  Adapted from Jasleen Jolly by Dan Bullock 16 Feb 2020
%
%% Begin code

%extract directory contents
inputDirContents=dir(subjectDir);

%extract the files of interest

%find all files that end with .txt
allFileNamesInput={inputDirContents(contains({inputDirContents(:).name},'.txt')).name};
%create paths to all of these files
allFilePathsInput=fullfile(subjectDir,allFileNamesInput);

%creat a blank structure to hold info about eye and subjectID
namePartsStorage=cell(length(allFilePathsInput),2);

for iEntries=1:length(allFileNamesInput)
    currentSplit = split(allFileNamesInput{iEntries},'_');
    %awkward, but quick fix
    %store info about subjectID
    namePartsStorage{iEntries,1}=currentSplit{1};
    %store info about eyeID
    namePartsStorage{iEntries,2}=currentSplit{2};
end

%create blank object
blankArray=[];

for iOutputs=1:length(allFilePathsInput)
    %read the current table data in
    currentdataTable=readtable(allFilePathsInput{iOutputs},'delimiter','\t');
    
    %initialize vec
    indexVec=[];
    %insert NaN for 1
    indexVec=[currentdataTable.Threshold(1), NaN,currentdataTable.Threshold(2:end)' ];
    
    %if the array is empty, first line becomes array, otherwise vertcat
    if isempty(blankArray)
        blankArray=indexVec;
    else
        blankArray=vertcat(blankArray,indexVec);
    end
end

%add the subject and eye information to the array
tableData=horzcat(namePartsStorage,num2cell(blankArray));

%get the size of the data array created by the loop
dataSize=size(blankArray);

%create a cell array of strings from 1 to max lenght of dataArray
numCellString=cellfun(@num2str,(num2cell(0:dataSize(2)-1)),'UniformOutput',false);
% set the variable/ column names for the table
varNames=horzcat({'subjectID'},{'eye'},strcat('index',numCellString));

%make the table

outTable=cell2table(tableData,'VariableNames',squeeze(varNames));
 
end
        
        
        
        