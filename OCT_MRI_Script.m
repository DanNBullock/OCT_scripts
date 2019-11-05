% read in and extrct thicknesses
% set centre according to location file
% flip left eyes to put all on same plane if combining but not needed if
% kept separate or not interested in nasal vs temporal
% set different diameters of visual field and extract the thickness
% information averages within that area.

%this could be a variable input
subjectDir = 'C:\Users\jjolly.DESKTOP-RGKT43R\Documents\FMRIB\Analysis\OCT_Data';

subjectDirContents = dir(subjectDir)
fileNames = {subjectDirContents(~[subjectDirContents(:).isdir]).name};

% Extract relevant information from the filenames
for iFiles=1:length(fileNames)
    currentFileName=fileNames{iFiles};
    %under the presumption that underscores are used to separate file name components
    underscoreIndexes=strfind(currentFileName,'_');
    
    %assumes subject id is first name component
    subjectID{iFiles}=currentFileName(1:underscoreIndexes(1)-1);
    %assumes eye is second name component
    eye{iFiles}=currentFileName(underscoreIndexes(1)+1:underscoreIndexes(2)-1);
end

%result is <subjectID> and <eye>, of equal length, indicating for <fileNames> the corresponding subject ID and eye

% set files paths.  Combines <subjectDir> and <fileNames> for a full path to each csv.  ASSUMES ALL FILES IN SUBJECT DIR ARE DESIRED CSVS.
csvpaths = fullfile(subjectDir,fileNames);

%these are the layers we want to analyse with the associated names
%THESE WOULD LIKELY BE VARIABLE INPUTS
analyses={1:7,1:4,5,6};
%THESE WOULD EITHER BE VARIABLE INPUTS OR TAKEN IN FROM TABLE
analysesNames={'TT','NL','ONL','PROS'}

% set output path (may need to make the folder)
primaryOutputDir=fullfile(subjectDir,'primaryAnalysis');
%might cause an error, fix later
if ~isfolder
    mkdir(primaryOutputDir);
else
    fprintf ('primary output directory already exists')
end

% this extracts the relevant layer values from each subject file and
% outputs results with the relevant ID and eye details. These are written
% to new CSVs for each layer we are interested in.

%Begins by iterating over subjects
for isubjects = 1:length(csvpaths)
    fprintf('\n subject %s' ,subjectID{isubjects}) % displays progress
    % uses proprietary parseCSVExport to get csv data
    curcsv = parseCsvExport(csvpaths{isubjects});
    %iterates over analyses
    for iAnalyses=1:length(analysesNames)
        currentLayers=analyses{iAnalyses};
        %uses <currentLayers> to index across the relevant layers of <curcsv>, notably in the third dimension.  Subsequently sums those layers. 
        outputArray = [sum(curcsv(:,:,currentLayers),3)]';
        %here we generate the name for this specific analysis/synthesis output, using <subjectID>, <eye>, and <analysesNames>
        outPutName=strcat(subjectID{isubjects},'_',eye{isubjects},'_',analysesNames{iAnalyses});
        outFileName=strcat(primaryOutputDir,'\',outPutName,'.csv');
        %here we write the csv out.
        csvwrite(outFileName,outputArray);   
    end
end

% this is setting the foveal point, known as the centroid here. Need to
% read the slice and position information from Heidelberg and add into the
% centroid table.
centroidPath='C:\Users\jjolly.DESKTOP-RGKT43R\Documents\FMRIB\Analysis\Location.csv';
centroidTable =readtable(centroidPath);
tableSize=size(centroidTable);

outputDir;
outputDirContents = dir(outputDir);
outputFileNames = {outputDirContents(~[outputDirContents(:).isdir]).name};

for iOutputFiles=1:length(outputFileNames)
    currentFileName=outputFileNames{iOutputFiles};
    underscoreIndexes=strfind(currentFileName,'_');
    dotIndexes=strfind(currentFileName,'.');
    
    outputSubjectID{iOutputFiles}=currentFileName(1:underscoreIndexes(1)-1);
    outputEye{iOutputFiles}=currentFileName(underscoreIndexes(1)+1:underscoreIndexes(2)-1);
    outputAnalysis{iOutputFiles}=currentFileName(underscoreIndexes(2)+1:dotIndexes-1);
end

%safe assumption about the data about 20 by 20 degree coverage for the MRI
%project as same scan done. Check how much optics of the eye changes this
%as may be able to ignore.
degreeTotal=10; % halve as radius
pixelVec=[0:51:51*degreeTotal]; % 51 was calculated as the with our scan parameters, 51 pixels in each degree.

% the secondary output gives us the eccentricity information for each eye.
secondaryOutputDir=fullfile(subjectDir,'secondaryOutput');
%mkdir(secondaryOutputDir) only need to do this once.

for iCentroid=1:tableSize(1)
    centerNames=centroidTable.Filename;
    currentCenterName=centerNames{iCentroid};
    
    underscoreIndexes=strfind(currentCenterName,'_');
    
    currentSubjectID=currentCenterName(1:underscoreIndexes(1)-1);
    currentEye=currentCenterName(underscoreIndexes(1)+1:underscoreIndexes(2)-1);
    %currentAnalysis=currentFileName(underscoreIndexes(2)+1:dotIndexes-1);
    
    %make sure the centroid is chosen for the right subjects and eyes
    validSubjects=strcmp(currentSubjectID,outputSubjectID);
    validEye=strcmp(currentEye,outputEye);
    
    currentAnalysisBool=and(validSubjects,validEye);
    
    % set X and Y
    currentXVal=centroidTable.position(iCentroid);
    currentYVal=centroidTable.slice(iCentroid);
    
    analysesIndexes=find(currentAnalysisBool);
    
    for iCurrentAnalyses=1:length(analysesIndexes)
        analysisFileName=strcat(outputSubjectID{analysesIndexes(iCurrentAnalyses)},'_',outputEye{analysesIndexes(iCurrentAnalyses)},'_',outputAnalysis{analysesIndexes(iCurrentAnalyses)},'.csv');
        currentAnalysisData=csvread(fullfile(outputDir,analysisFileName));
        
        layerLabel{iCurrentAnalyses}=outputAnalysis{analysesIndexes(iCurrentAnalyses)};
        
        % sort so all files are in alphabetical order otherwise can be
        % mixed up
        [sortedLabels,sortOrder]=sort(layerLabel);
        
        % this rounds down the border
        currentDataSize=size(currentAnalysisData);
        conversionResize=floor(currentDataSize/(degreeTotal*2));
        
        %NOTE: ITERATING TO degreeTotal-1 IN ORDER TO AVOID CENTROID SHIFT
        %CAUSING AN OUT OF BOUNDS INDEXING
        for iAngles=1:degreeTotal-1
            xRadius=conversionResize(2)*iAngles;
            xRemainder=iAngles*.05*currentDataSize(2)-conversionResize(2)*iAngles;
            
            yRadius=conversionResize(1)*iAngles;
            yRemainder=iAngles*.05*currentDataSize(1)-conversionResize(1)*iAngles;
            %THIS IS A FIX FOR THE LACK OF GRANULARITY IN THE Y DIMENSION
            if yRemainder >= conversionResize(1)
                yRadius=yRadius+floor(yRemainder/conversionResize(1));
            end
            
            yRange=[currentYVal-yRadius:currentYVal+yRadius];
            xRange=[currentXVal-xRadius:currentXVal+xRadius];
            
            
            %implement check here, this is to compensate for extreme
            %eccentricity of centroid
            if or(any(xRange<0),any(xRange>currentDataSize(2)))
                warning('\n angle %i for subject %s exceeds range -- check centroid eccentricity',iAngles,currentSubjectID)
                xRange=xRange(and(xRange>0,xRange<currentDataSize(2)));
            else
                %do nothing
            end
            
            if or(any(yRange<0),any(yRange>currentDataSize(1)))
                warning('\n angle %i for subject %s exceeds range -- check centroid eccentricity for y',iAngles,currentSubjectID)
                yRange=yRange(and(yRange>0,yRange<currentDataSize(1)));
            else
                %do nothing
            end
            
            % This creates the mask over the area of measurement. It is an
            % ellipse calculated accounting for the differential
            % measurement units in X adn Y direction
            matrixMask=false(length(yRange),length(xRange));
            
            for iYrange=1:length(yRange)
                for iXrange=1:length(xRange)
                    xDisp=xRange(iXrange)-currentXVal;
                    yDisp=yRange(iYrange)-currentYVal;
                    xDispConvert=xDisp/conversionResize(1);
                    yDispConvert=yDisp/conversionResize(2);
                    hypot=sqrt(xDispConvert^2+yDispConvert^2);
                    matrixMask(iYrange,iXrange)=hypot<=iAngles;
                end
            end
            
            dataSubset=currentAnalysisData(yRange,xRange);
            maskedMean(iCurrentAnalyses,iAngles)=mean(dataSubset(matrixMask));
            maskedStd(iCurrentAnalyses,iAngles)=std(dataSubset(matrixMask));
        end
        
    end
    
    %resort matricies here
    sortedMaskedMean=zeros(size(maskedMean));
    sortedmaskedStd=zeros(size(maskedMean));
    for iLabels=1:length(layerLabel)
        sortedMaskedMean(iLabels,:)=maskedMean(sortOrder(iLabels),:);
        sortedmaskedStd(iLabels,:)=maskedStd(sortOrder(iLabels),:);
    end

    meanDataCell=horzcat(sortedLabels',num2cell(maskedMean));
    stdDataCell=horzcat(sortedLabels',num2cell(maskedStd));
    
    %NOTE degreeTotal-1 USED HERE AGAIN FOR CONSISTENCY
    varNames=horzcat({'LayerNames'},strcat('degree ',strsplit(num2str(1:degreeTotal-1),' ')));
    
    % create results tables
    meanDataTable=cell2table(meanDataCell,'VariableNames',varNames);
    stdDataTable=cell2table(stdDataCell,'VariableNames',varNames);
    
    %WARNING:  THIS ASSIGNMENT USES THE iCurrentAnalyses VARIBLE TO
    %ASSIGN NAMES.  NOT IDEAL, BUT SHOULDN'T CAUSE PROBLEMS.  FIX LATER
    meanTableName=strcat(outputSubjectID{analysesIndexes(iCurrentAnalyses)},'_',outputEye{analysesIndexes(iCurrentAnalyses)},'_meanTable.csv');
    stdTableName=strcat(outputSubjectID{analysesIndexes(iCurrentAnalyses)},'_',outputEye{analysesIndexes(iCurrentAnalyses)},'_stdTable.csv');
    
    writetable(meanDataTable,fullfile(secondaryOutputDir,meanTableName))
    writetable(stdDataTable,fullfile(secondaryOutputDir,stdTableName))
    
    %just in case
    clear maskedMean
    clear maskedStd
end

%group summary statistics
GroupDir='C:\Users\jjolly.DESKTOP-RGKT43R\Documents\FMRIB\Analysis\Groups';
groupDirContents = dir(GroupDir);
fileNames = {groupDirContents(~[groupDirContents(:).isdir]).name};

% where data for this analysis is coming from
secondaryOutputDir;
secondaryOutputDirContents = dir(secondaryOutputDir);
secondaryOutputFileNames = {secondaryOutputDirContents(~[secondaryOutputDirContents(:).isdir]).name};

for isecondaryOutputFiles=1:length(secondaryOutputFileNames)
    currentFileName=secondaryOutputFileNames{isecondaryOutputFiles};
    underscoreIndexes=strfind(currentFileName,'_');
    dotIndexes=strfind(currentFileName,'.');
    
    secondaryOutputSubjectID{isecondaryOutputFiles}=currentFileName(1:underscoreIndexes(1)-1);
    secondaryOutputEye{isecondaryOutputFiles}=currentFileName(underscoreIndexes(1)+1:underscoreIndexes(2)-1);
    secondaryOutputAnalysis{isecondaryOutputFiles}=currentFileName(underscoreIndexes(2)+1:dotIndexes-1);
end

% where the output from this is going.
groupDir='C:\Users\jjolly.DESKTOP-RGKT43R\Documents\FMRIB\Analysis\Groups\';
groupLabels={'CHM','CHM_Cont','STGD','STGD_Cont'};
groupAnalysisDir='C:\Users\jjolly.DESKTOP-RGKT43R\Documents\FMRIB\Analysis\GroupAnalysis\';

% using the group directory to know which subjects belong in which group
for iGroups=1:length(fileNames)
    currentGroup=groupLabels{iGroups};
    curGroupPath=strcat(groupDir,currentGroup,'.xlsx');
    [~,holdText]=xlsread(curGroupPath);
    
      %more cleaning
      ODBlockCell=[];
     OSBlockCell=[];
    
    for iGroupMembers=1:length(holdText)
        
        %clear on a group basis
        ODBlockTable=[];
        OSBlockTable=[];
        %this is what we load in to, sperate out right and left eyes
        ODBlockHolderTable=[];
        OSBlockHolderTable=[];
      
        
        
        %inelegant, could probably be done just by generating the file
        %paths to the files, however, may not be as robust against
        %missing files or subjects
        currSubjNum=holdText{iGroupMembers};
        targetFiles=strcmp(currSubjNum,secondaryOutputSubjectID);
        targetFileIndexes=find(targetFiles);
        if ~isempty(targetFileIndexes)
            %if os or od block are empty, this is the first time we are
            %concatting for this group
            if isempty(ODBlockCell)
                ODBlockTable=readtable(strcat(secondaryOutputDir,'\',currSubjNum,'_OD_meanTable.csv'));
                OSBlockTable=readtable(strcat(secondaryOutputDir,'\',currSubjNum,'_OS_meanTable.csv'));
                %convert to array
                ODBlockCell=table2cell(ODBlockTable);
                OSBlockCell=table2cell(OSBlockTable);
            else
                ODBlockHolder=readtable(strcat(secondaryOutputDir,'\',currSubjNum,'_OD_meanTable.csv'));
                OSBlockHolder=readtable(strcat(secondaryOutputDir,'\',currSubjNum,'_OS_meanTable.csv'));
                %now we cat
                ODBlockCell=cat(3,ODBlockCell,table2cell(ODBlockHolder));
                OSBlockCell=cat(3,OSBlockCell,table2cell(OSBlockHolder));
                %
                clear ODBlockHolder
                clear OSBlockHolder
            end
        else
            warning('\n no data found for subject %s', currSubjNum)
        end %end of subject specifc loop
        
    end %end of within group loop
    
    %now do mean and std
    ODBlockMean=mean(cell2mat(ODBlockCell(:,2:end,:)),3);
    ODBlockStd=std(cell2mat(ODBlockCell(:,2:end,:)),[],3);
    OSBlockMean=mean(cell2mat(OSBlockCell(:,2:end,:)),3);
    OSBlockStd=std(cell2mat(OSBlockCell(:,2:end,:)),[],3);
    
    %make tables
    ODBlockMeanCell=num2cell(ODBlockMean);
    ODBlockStdCell=num2cell(ODBlockStd);
    OSBlockMeanCell=num2cell(OSBlockMean);
    OSBlockStdCell=num2cell(OSBlockStd);
    
    %obtain data size, dim1 = layer number , dim 2 = angle total 
    dataSize=size(ODBlockMean);
    
    varNames=horzcat({'LayerNames'},strcat('degree ',strsplit(num2str(1:dataSize(2)),' ')));
    
    %make output tables
    ODBlockMeanTable=cell2table(horzcat({ODBlockCell{:,1,1}}',ODBlockMeanCell),'VariableNames',varNames);
    ODBlockStdTable=cell2table(horzcat({ODBlockCell{:,1,1}}',ODBlockStdCell),'VariableNames',varNames);
    OSBlockMeanTable=cell2table(horzcat({OSBlockCell{:,1,1}}',OSBlockMeanCell),'VariableNames',varNames);
    OSBlockStdTable=cell2table(horzcat({OSBlockCell{:,1,1}}',OSBlockStdCell),'VariableNames',varNames);
    
    %writetable(meanDataTable,fullfile(secondaryOutputDir,meanTableName))
    %currentGroup
    outputFileStem=strcat(groupAnalysisDir,currentGroup);
    
    writetable(ODBlockMeanTable,strcat(groupAnalysisDir,'OD_GroupMean_',currentGroup,'.csv'))
    writetable(ODBlockStdTable,strcat(groupAnalysisDir,'OD_StdMean_',currentGroup,'.csv'))
    writetable(OSBlockMeanTable,strcat(groupAnalysisDir,'OS_GroupMean_',currentGroup,'.csv'))
    writetable(OSBlockStdTable,strcat(groupAnalysisDir,'OS_StdMean_',currentGroup,'.csv'))
    
    % show progress as go along
    fprintf('\n group %s complete',currentGroup )
end %end loop across groups
    
