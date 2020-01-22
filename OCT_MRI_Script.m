% read in and extrct thicknesses
% set centre according to location file
% flip left eyes to put all on same plane if combining but not needed if
% kept separate or not interested in nasal vs temporal
% set different diameters of visual field and extract the thickness
% information averages within that area.

%this could be a variable input
subjectDir = '/N/u/dnbulloc/Carbonate/OCT_Data/Data';

subjectDirContents = dir(subjectDir);
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
primaryOutputDir=fullfile(subjectDir,'primaryOutput');
%might cause an error, fix later
if ~isfolder(primaryOutputDir)
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

%this could also be an input in a functionalized version of this
centroidPath='C:\Users\jjolly.DESKTOP-RGKT43R\Documents\FMRIB\Analysis\Location.csv';
%load the excel file to obtain the centroid data
centroidTable =readtable(centroidPath);
%determine the size of <centroidTable>.  This gives us the number of subjects
tableSize=size(centroidTable);

outputDirContents = dir(primaryOutputDir);
outputFileNames = {outputDirContents(~[outputDirContents(:).isdir]).name};

%here's the deal with this:  if, on line 62 we had caught each output file name we wouldn't need to do this.  However, here we are being agnostic about what preceeded this part of the analysis.  Theoretically, this will allow us to functionalize things more easily in the future.
for iOutputFiles=1:length(outputFileNames)
    currentFileName=outputFileNames{iOutputFiles};
    %finding the indexes of underscores, just as before
    underscoreIndexes=strfind(currentFileName,'_');
    %here we are finding the last part of the file name.  Theoretically, we could have used the outputs of the function fileparts on the full file path for each file in <primaryOutputDir> 
    dotIndexes=strfind(currentFileName,'.');
    
    %working under assumption that first name component is subjectID
    outputSubjectID{iOutputFiles}=currentFileName(1:underscoreIndexes(1)-1);
    %working under assumption that second name component is eye
    outputEye{iOutputFiles}=currentFileName(underscoreIndexes(1)+1:underscoreIndexes(2)-1);
    %working under assumption that third and last (it makes both assumptions) name component is analysis
    outputAnalysis{iOutputFiles}=currentFileName(underscoreIndexes(2)+1:dotIndexes-1);
end

%safe assumption about the data about 20 by 20 degree coverage for the MRI
%project as same scan done. Check how much optics of the eye changes this
%as may be able to ignore.

%THIS COULD BE A FUNCTION INPUT
%this value is half the diameter, because you'll be extending the value around the centroid value (on both sides) by the contents of <pixelVec>
%manually set
degreeTotal=10; % halve as radius
%here we are generating a numerical (integer) vector that will help us index the components of the measure we are including in our mean

%A MORE ELEGANT WAY TO DO THIS WOULD BE TO COMPUTE THE VALUE CORRESPONDING TO THE 51 FROM THE DATA ITSELF, IF THIS IS NOT POSSIBLE, THEN MANUAL ENTRY HERE IS THE ONLY OPTION
pixelVec=[0:51:51*degreeTotal]; % 51 was calculated as the with our scan parameters, 51 pixels in each degree.

% the secondary output gives us the eccentricity information for each eye.
secondaryOutputDir=fullfile(subjectDir,'secondaryOutput');
if ~isfolder(secondaryOutputDir)
    mkdir(secondaryOutputDir);
else
    fprintf('secondary output directory already exists')
end

%moved this out here, because it doesn't need to be done for every subject, only once
%here we obtain the entire column under the table heading <Filename>, returns a cell string vector
centerNames=centroidTable.Filename;
%Here we are iterating over subjects, as inferred from the first entry in <tableSize>
for iCentroid=1:tableSize(1)
    %obtain the file name corresponding to the <iCentroid> entry of the <centroidTable>'s Filename field
    %NOTE, THIS NEED NOT CORRESPOND TO THE SAME ORDERING AS THE CONTENTS OF <outputFileNames>
    %in fact we are being agnostic about this ordering here, hence the additional bit with name generation here
    currentCenterName=centerNames{iCentroid};
    
    %finding the underscores in the name, just as before
    underscoreIndexes=strfind(currentCenterName,'_');
    
    %operating under the assumption that first name component is subject ID
    currentSubjectID=currentCenterName(1:underscoreIndexes(1)-1);
    %operating under the assumption that second name component is eye 
    currentEye=currentCenterName(underscoreIndexes(1)+1:underscoreIndexes(2)-1);
    %<currentAnalysis> is not used, likely because we are assuming that if a subject and eye combination exists, so to does all analyses for it
    %NOTE:  IF THIS ASSUMPTION DOES NOT HOLD, IT WOULD BE NECESSARY TO GENERATE THIS FOR LATER ITERATION
    %currentAnalysis=currentFileName(underscoreIndexes(2)+1:dotIndexes-1);
    
    %make sure the centroid is chosen for the right subjects and eyes
    %creates a boolean vector corresponding to the variable outputSubjectID
    validSubjects=strcmp(currentSubjectID,outputSubjectID);
    %creates a boolean vector corresponding to the variable outputEye
    validEye=strcmp(currentEye,outputEye);
    
    %apply both criteria to narrow down the valid analysis files
    %NOTE, IN THE CASE WHERE YOU DIDN'T HAVE ALL ANALYSES FOR A SUBJECT, THIS IS WHERE YOU WOULD APPLY A <validAnalysis> bool variable, after generation
    currentAnalysisBool=and(validSubjects,validEye);
    
    % set X and Y
    % be careful though because there appears to be a mismatch between our intuitions about x and y and the standard indexing practices of matlab
    currentXVal=centroidTable.position(iCentroid);
    currentYVal=centroidTable.slice(iCentroid);
    
    %returns the indexes
    %actually, this may actually make the function robust against instances where there isn't a full set of analyses.
    analysesIndexes=find(currentAnalysisBool);
    
    %iterates across the indexes of <analysesIndexes> .  The working presumption here is that length(analysesIndexes) always == 4
    for iCurrentAnalyses=1:length(analysesIndexes)
        
        %generates name for current analysis file.  Note double indexing using <analysesIndexes(iCurrentAnalyses)>
        analysisFileName=strcat(outputSubjectID{analysesIndexes(iCurrentAnalyses)},'_',outputEye{analysesIndexes(iCurrentAnalyses)},'_',outputAnalysis{analysesIndexes(iCurrentAnalyses)},'.csv');
        %load corresponding file.  Here we are using fullfile.
        currentAnalysisData=csvread(fullfile(outputDir,analysisFileName));
        
        %referring back to <layerLabel> so we can sort our table output 
        layerLabel{iCurrentAnalyses}=outputAnalysis{analysesIndexes(iCurrentAnalyses)};
        
        % sort so all files are in alphabetical order otherwise can be
        % mixed up.  We are thus agnostic to input ordering on layerLabel
        [sortedLabels,sortOrder]=sort(layerLabel);
        
        % this rounds down the border
        %probably need to revisit this at some point
        currentDataSize=size(currentAnalysisData);
        %NOTE THAT <conversionResize> has two items in it.  This is bad practice.  We fix it in other version of the code by splitting it into <conversionResizeX> <conversionResizeY>
        conversionResize=floor(currentDataSize/(degreeTotal*2));
        
        %NOTE: ITERATING TO degreeTotal-1 IN ORDER TO AVOID CENTROID SHIFT
        %CAUSING AN OUT OF BOUNDS INDEXING
        %actually, the centroid shift isn't necessarily the problem any more.  because we have the check implmented for x and y later this may not be necessary.
        for iAngles=1:degreeTotal-1
            %computes current radius in pixels
            xRadius=conversionResize(2)*iAngles;
            %determines the remainder for the current mathematical operation.
            %NOTE: THE USE OF .05 IS LIKELY BAD PRACTICE AS IT IS HARD CODED.  .05 = 1/20 = 1/(2*<degreeTotal>)
            %FIX THIS
            xRemainder=iAngles*.05*currentDataSize(2)-conversionResize(2)*iAngles;
            
            %same for y.
            yRadius=conversionResize(1)*iAngles;
            yRemainder=iAngles*.05*currentDataSize(1)-conversionResize(1)*iAngles;
            %THIS IS A FIX FOR THE LACK OF GRANULARITY IN THE Y DIMENSION.  We probably dont encounter this issue in the x dimension
            if yRemainder >= conversionResize(1)
                yRadius=yRadius+floor(yRemainder/conversionResize(1));
            end
            
            %sets the indexes for the y and x ranges, using the radius and the centroid values
            yRange=[currentYVal-yRadius:currentYVal+yRadius];
            xRange=[currentXVal-xRadius:currentXVal+xRadius];
            
            
            %implement check here, this is to compensate for extreme
            %eccentricity of centroid.  Resets boundaries if they are too extreme.  Note, this results in an asymetric mean being computed.
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
            % measurement units in X and Y direction
            
            %set mask as empty array of boolean 0
            matrixMask=false(length(yRange),length(xRange));
            
            %probably a better way to do this than double iteration, but effective
            %NOTE, THIS IS A NEAT TRICK WHEREBY WE ONLY ITERATE WITHIN THE BOX CONTAINING THE DEGREE RADIUS OF INTEREST
            for iYrange=1:length(yRange)
                for iXrange=1:length(xRange)
                    %gets unit displacement
                    xDisp=xRange(iXrange)-currentXVal;
                    yDisp=yRange(iYrange)-currentYVal;
                    %gets degree displacement
                    xDispConvert=xDisp/conversionResize(1);
                    yDispConvert=yDisp/conversionResize(2);
                    %computes hypotenuse and thus distance from centroid
                    %NOTE, THE REASON WE ARE DOING THIS IS BECAUSE WE CAN ONLY COMPUTE THE HYPOTENUSE IF BOTH DIMENSIONS ARE USING THE SAME UNIT MEASURE
                    %AS SUCH WE HAVE TO CONVERT BACK TO DEGREES
                    hypot=sqrt(xDispConvert^2+yDispConvert^2);
                    %sets entry in mask to 1 if it is within the boundary of <iAngles>
                    matrixMask(iYrange,iXrange)=hypot<=iAngles;
                end
            end
            
            %obtains all of the data contained within the box as described in line 228
            %Technically at this point we no longer care where they are, just that they meet the criteria for us being interested in them.
            dataSubset=currentAnalysisData(yRange,xRange);
            %from this subset, computes the mean and standard deviation
            maskedMean(iCurrentAnalyses,iAngles)=mean(dataSubset(matrixMask));
            maskedStd(iCurrentAnalyses,iAngles)=std(dataSubset(matrixMask));
        end
        
    end
    
    %resort matricies here
    
    % establish empty matricies for sorted output
    %NOTE: this clears the matrix from the last iteration
    sortedMaskedMean=zeros(size(maskedMean));
    sortedmaskedStd=zeros(size(maskedMean));
    
    %store output from previous iteractions.  Here we are resorting using the <sortOrder>
    % it might be worthwhile to include a fprintf with the <sortOrder> here just to give an indication of when things are being resorted
    for iLabels=1:length(layerLabel)
        sortedMaskedMean(iLabels,:)=maskedMean(sortOrder(iLabels),:);
        sortedmaskedStd(iLabels,:)=maskedStd(sortOrder(iLabels),:);
    end

    %adding the labels as the first column of the cell structure, so that it can function as a table
    meanDataCell=horzcat(sortedLabels',num2cell(maskedMean));
    stdDataCell=horzcat(sortedLabels',num2cell(maskedStd));
    
    %NOTE degreeTotal-1 USED HERE AGAIN FOR CONSISTENCY, this is in keeping with line 183
    varNames=horzcat({'LayerNames'},strcat('degree ',strsplit(num2str(1:degreeTotal-1),' ')));
    
    % create results tables
    meanDataTable=cell2table(meanDataCell,'VariableNames',varNames);
    stdDataTable=cell2table(stdDataCell,'VariableNames',varNames);
    
    %WARNING:  THIS ASSIGNMENT USES THE iCurrentAnalyses VARIBLE TO
    %ASSIGN NAMES.  NOT IDEAL, BUT SHOULDN'T CAUSE PROBLEMS.  FIX LATER
    %find a better/more independently reliable way to generate the names
    meanTableName=strcat(outputSubjectID{analysesIndexes(iCurrentAnalyses)},'_',outputEye{analysesIndexes(iCurrentAnalyses)},'_meanTable.csv');
    stdTableName=strcat(outputSubjectID{analysesIndexes(iCurrentAnalyses)},'_',outputEye{analysesIndexes(iCurrentAnalyses)},'_stdTable.csv');
    
    %writes them as table
    writetable(meanDataTable,fullfile(secondaryOutputDir,meanTableName))
    writetable(stdDataTable,fullfile(secondaryOutputDir,stdTableName))
    
    %just in case they need to be cleared
    clear maskedMean
    clear maskedStd
end
% I moved this here, because I think it makes sense to generate this at this point.  Consistent with previous practice
% where data for this analysis is coming from
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


%group summary statistics
%I think here we aer just getting group membership, yes?
GroupDir='C:\Users\jjolly.DESKTOP-RGKT43R\Documents\FMRIB\Analysis\Groups';
groupDirContents = dir(GroupDir);
fileNames = {groupDirContents(~[groupDirContents(:).isdir]).name};

% where the output from this is going.
% I don't understand why we have both <GroupDir> and <groupDir>.  Maybe harmonize?
groupDir='C:\Users\jjolly.DESKTOP-RGKT43R\Documents\FMRIB\Analysis\Groups\';
groupLabels={'CHM','CHM_Cont','STGD','STGD_Cont'};
groupAnalysisDir='C:\Users\jjolly.DESKTOP-RGKT43R\Documents\FMRIB\Analysis\GroupAnalysis\';

% using the group directory to know which subjects belong in which group
%iterates across <fileNames>  Which I believe is just several excel files with file-group membership indications
%NOTE: THE LENGTH OF <fileNames> should be the same length as <groupLabels> consider implementing a checksum for this.
for iGroups=1:length(fileNames)
    currentGroup=groupLabels{iGroups};
    %NOTE:  Were hard code building the names of the files here from the <groupLabels> variable, rather than the <fileNames> variable.
    curGroupPath=strcat(groupDir,currentGroup,'.xlsx');
    %NOTE:  not using standard table read or csv read because these are excel files
    [~,holdText]=xlsread(curGroupPath);
    
    %create blank holders, also cleans from previous iterations
    ODBlockCell=[];
    OSBlockCell=[];
    
    %iterate across <holdText
    for iGroupMembers=1:length(holdText)
        
        %clear table on an individual basis
        ODBlockTable=[];
        OSBlockTable=[];
        %this is what we load in to if <ODBlockCell> is empty, i.e. this is the first subject of the group, sperate out right and left eyes
        ODBlockHolderTable=[];
        OSBlockHolderTable=[]; 
        
        %inelegant, could probably be done just by generating the file
        %paths to the files, however, may not be as robust against
        %missing files or subjects
        currSubjNum=holdText{iGroupMembers};
        %find indexes of secondary outputs corresponding to the current subject
        targetFiles=strcmp(currSubjNum,secondaryOutputSubjectID);
        targetFileIndexes=find(targetFiles);
        
        if ~isempty(targetFileIndexes)
            %if os or od block are empty, this is the first time we are
            %concatting for this group, i.e. the first subject
            if isempty(ODBlockCell)
            %read table in
                ODBlockTable=readtable(strcat(secondaryOutputDir,'\',currSubjNum,'_OD_meanTable.csv'));
                OSBlockTable=readtable(strcat(secondaryOutputDir,'\',currSubjNum,'_OS_meanTable.csv'));
                %convert to cell array.  We need the cell array so we can do math.  Note the use of = rather than cat
                ODBlockCell=table2cell(ODBlockTable);
                OSBlockCell=table2cell(OSBlockTable);
            else
            %if it isn't empty, we begin the catting process
                ODBlockHolder=readtable(strcat(secondaryOutputDir,'\',currSubjNum,'_OD_meanTable.csv'));
                OSBlockHolder=readtable(strcat(secondaryOutputDir,'\',currSubjNum,'_OS_meanTable.csv'));
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
    
    writetable(ODBlockMeanTable,strcat(groupAnalysisDir,'OD_GroupMean_',currentGroup,'.csv'))
    writetable(ODBlockStdTable,strcat(groupAnalysisDir,'OD_StdMean_',currentGroup,'.csv'))
    writetable(OSBlockMeanTable,strcat(groupAnalysisDir,'OS_GroupMean_',currentGroup,'.csv'))
    writetable(OSBlockStdTable,strcat(groupAnalysisDir,'OS_StdMean_',currentGroup,'.csv'))
    
    % show progress as go along
    fprintf('\n group %s complete',currentGroup )
end %end loop across groups
