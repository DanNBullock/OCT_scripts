function [subjectID, indexVec, groupNames]=parseInputGroupKey(pathToKey)
%parseInputGroupKey(pathToKey)
%
%This function is an attempt at providing a robust parsing function for
%extracting subject group membership
%
%  INPUTS
%
% pathToKey:  a path to either a directory or file containing the group
% membership information stored as either a excel file or a csv.
%
% OUTPUTS:
%
% subjectID:  a vector containing all subject IDs
%
% indexVec:  A 1x[# of subjects] vector containing integers corresponding
% to the entry in the <groupNames> which indicates the group membership of
% this subject
%
% groupNames: a vector containing all group names
%
% by Dan Bullock 24 Jan 2020
%% Begin code

subjectID=[];
indexVec=[];
groupNames=[];

if isfile(pathToKey)  %single keyfile case
    [~,~,ext] = fileparts(pathToKey)
    if strcmp(ext,'xlsx')  %ignore xls case for now
          [~,holdText]=xlsread(pathToKey)
          %finish making this robust at some later point
          keyboard
    elseif strcmp(ext,'xlsx')  %csv case
        tableContents=readtable(pathToKey)
        %finish making this robust at some later point
        keyboard
    end %end extension casing

elseif isfolder(pathToKey)
    keyDirContents=dir(pathToKey);
    inputDirFileNames = {keyDirContents(~[keyDirContents(:).isdir]).name};
    
    for iInputKeyFiles=1:length(inputDirFileNames) %iuterate across input key files
        currentFileName=fullfile(pathToKey,inputDirFileNames{iInputKeyFiles});
        [~,curGroupLabel,ext] = fileparts(currentFileName);
        
        %append current group name
        groupNames=vertcat(groupNames,{curGroupLabel});
        if strcmp(ext,'.xlsx')  %ignore xls case for now
            [~,tableContents]=xlsread(currentFileName);
            
            %append current subjIds
            subjectID=vertcat(subjectID,tableContents);
            
            curIndexVec=ones(length(tableContents),1);
            curIndexVec(:)=iInputKeyFiles;
            indexVec=vertcat(indexVec,curIndexVec);
            
            %finish making this robust at some later point
        elseif strcmp(ext,'.csv')  %csv case
            tableContents=readtable(pathToKey);
            %finish making this robust at some later point
            keyboard
        end %end extension casing
        
    end
end

end
        
