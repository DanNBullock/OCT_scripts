function OCTGroupAnalysisWrapper(inputDir,groupKeyDir,outputDir)
%function OCTgroupAnalysis(inputDir,groupKeyDir,outputDir)
%
%This function computes group means in accordance with the data structure
%of the previous analysis function (iteratedCentroidMeanCompute) and the
%file(s) indicating group membership.
%
%  INPUTS
%
%  inputDir:  path to the directory contining the multiple CSV outputs from
%  analyzeOCTDataWrapper
%
%  groupKeyDir:  Path to the directory containing information about group
%  membership.  Currently, due to how this project has been set up, these
%  are stored as N number of excel files which contain a single column of
%  subject IDs corresponding to group membership in the group sharing the
%  title of the file itself.  I suspect there are other schemas for doing
%  this, and the function that parses this ought to be able to contend with
%  this.
%
%  outputDir: Directory into which the output files are saved
%
%  OUTPUTS
%
%  none, outputs are saved into the specified output directory.
%
%
% Adapted from code produced by Dan Bullock and Jasleen Jolley 05 Nov 2019
% Extensive rewrite/functionalization by Dan Bullock 22 Jan 2020
%% Subfunctions
% 
% parseInputGroupKey.m
%
% 
%% Begin Code
%  set variables and perform checks

% set output directory to subdirectory of <subjDataDir> if it isn't defined, 
if isempty(outputDir)
    outputDir=fullfile(inputDir,'groupAnalysis');
else
    %do nothing
end

%create output directory if it doesnt exist
if ~isfolder(outputDir)
    mkdir(outputDir);
else
    %do nothing
end

%% Begin analysis

%extract input directory contents
inputDirContents = dir(inputDir);
inputDirFileNames = {inputDirContents(~[inputDirContents(:).isdir]).name};

for isecondaryOutputFiles=1:length(inputDirFileNames)
    currentFileName=inputDirFileNames{isecondaryOutputFiles};
    underscoreIndexes=strfind(currentFileName,'_');
    dotIndexes=strfind(currentFileName,'.');
    
    secondaryOutputSubjectID{isecondaryOutputFiles}=currentFileName(1:underscoreIndexes(1)-1);
    secondaryOutputEye{isecondaryOutputFiles}=currentFileName(underscoreIndexes(1)+1:underscoreIndexes(2)-1);
    secondaryOutputAnalysis{isecondaryOutputFiles}=currentFileName(underscoreIndexes(2)+1:dotIndexes-1);
end

%parse the group key
[subjectIDs, indexVec, groupNames]=parseInputGroupKey(groupKeyDir);

% using the group directory to know which subjects belong in which group
%iterates across <fileNames>  Which I believe is just several excel files with file-group membership indications
%NOTE: THE LENGTH OF <fileNames> should be the same length as <groupLabels> consider implementing a checksum for this.
for iGroups=1:length(groupNames)
    currentGroup=groupNames{iGroups};
    %NOTE:  Were hard code building the names of the files here from the <groupLabels> variable, rather than the <fileNames> variable.
    
    %create blank holders, also cleans from previous iterations
    ODBlockCell=[];
    OSBlockCell=[];
    
    currentSubjectIDs=subjectIDs(find(indexVec==iGroups));
    
    %iterate across <holdText>
    for iGroupMembers=1:length(currentSubjectIDs)
        
        %clear table on an individual basis
        ODBlockTable=[];
        OSBlockTable=[];
        %this is what we load in to if <ODBlockCell> is empty, i.e. this is the first subject of the group, sperate out right and left eyes
        ODBlockHolderTable=[];
        OSBlockHolderTable=[]; 
        
        %inelegant, could probably be done just by generating the file
        %paths to the files, however, may not be as robust against
        %missing files or subjects
        currSubjNum=currentSubjectIDs{iGroupMembers};
        %find indexes of secondary outputs corresponding to the current subject
        targetFiles=strcmp(currSubjNum,secondaryOutputSubjectID);
        targetFileIndexes=find(targetFiles);
        
        if ~isempty(targetFileIndexes)
            %if os or od block are empty, this is the first time we are
            %concatting for this group, i.e. the first subject
            if isempty(ODBlockCell)
            %read table in
                ODBlockTable=readtable(fullfile(inputDir,strcat(currSubjNum,'_OD_meanTable.csv')));
                OSBlockTable=readtable(fullfile(inputDir,strcat(currSubjNum,'_OS_meanTable.csv')));
                %convert to cell array.  We need the cell array so we can do math.  Note the use of = rather than cat
                ODBlockCell=table2cell(ODBlockTable);
                OSBlockCell=table2cell(OSBlockTable);
            else
            %if it isn't empty, we begin the catting process
                ODBlockHolder=readtable(fullfile(inputDir,strcat(currSubjNum,'_OD_meanTable.csv')));
                OSBlockHolder=readtable(fullfile(inputDir,strcat(currSubjNum,'_OS_meanTable.csv')));
                %now we cat on to the existing object
                ODBlockCell=cat(3,ODBlockCell,table2cell(ODBlockHolder));
                OSBlockCell=cat(3,OSBlockCell,table2cell(OSBlockHolder));
                %probably not necessary
                clear ODBlockHolder
                clear OSBlockHolder
            end
        else
            warning('\n no data found for subject %s', currSubjNum)
        end %end of subject specifc loop
        
    end %end of within group loop
    
    %now do mean and std.  This is an interesting way of doing it, because several things are going on
    %the cell2mat allows us to convert the cell array into a matlab numeric array, which we can then do mathematical operations (like mean and std on)
    %however, cell2mat won't work if all of the entries aren't of the same type, hence the indexing of the second dimension starting at 2.  We are avoiding the analysis names, which are strings, using this.
    ODBlockMean=mean(cell2mat(ODBlockCell(:,2:end,:)),3);
    ODBlockStd=std(cell2mat(ODBlockCell(:,2:end,:)),[],3);
    OSBlockMean=mean(cell2mat(OSBlockCell(:,2:end,:)),3);
    OSBlockStd=std(cell2mat(OSBlockCell(:,2:end,:)),[],3);
    
    %make tables
    %because we are making tables, we have to reconvert our ouputs back into a cell array because this is what is required to make a table
    ODBlockMeanCell=num2cell(ODBlockMean);
    ODBlockStdCell=num2cell(ODBlockStd);
    OSBlockMeanCell=num2cell(OSBlockMean);
    OSBlockStdCell=num2cell(OSBlockStd);
    
    %obtain data size, dim1 = layer number , dim 2 = angle total
    %NOTE: we appear to have made some assumptions about consistent field of view sizes if we are doing this here
    dataSize=size(ODBlockMean);
    
    %these serve as the column headers in the output table
    varNames=horzcat({'LayerNames'},strcat('degree ',strsplit(num2str(1:dataSize(2)),' ')));
    
    %make output tables
    %<ODBlockCell{:,1,1}> actually corresponds to the LayerNames as noted in the <varNames> variable.  This is a safe way to do this given that we previously sorted the outputs.  There are likely ways to do this in an agnostic fashion.
    ODBlockMeanTable=cell2table(horzcat({ODBlockCell{:,1,1}}',ODBlockMeanCell),'VariableNames',varNames);
    ODBlockStdTable=cell2table(horzcat({ODBlockCell{:,1,1}}',ODBlockStdCell),'VariableNames',varNames);
    OSBlockMeanTable=cell2table(horzcat({OSBlockCell{:,1,1}}',OSBlockMeanCell),'VariableNames',varNames);
    OSBlockStdTable=cell2table(horzcat({OSBlockCell{:,1,1}}',OSBlockStdCell),'VariableNames',varNames);
    
    %not actually used
    %outputFileStem=strcat(groupAnalysisDir,currentGroup);
    
    writetable(ODBlockMeanTable,strcat(outputDir,'OD_GroupMean_',currentGroup,'.csv'))
    writetable(ODBlockStdTable,strcat(outputDir,'OD_StdMean_',currentGroup,'.csv'))
    writetable(OSBlockMeanTable,strcat(outputDir,'OS_GroupMean_',currentGroup,'.csv'))
    writetable(OSBlockStdTable,strcat(outputDir,'OS_StdMean_',currentGroup,'.csv'))
    
    % show progress as go along
    fprintf('\n group %s complete',currentGroup )
end %end loop across groups
