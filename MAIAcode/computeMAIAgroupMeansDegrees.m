function [meanDegreesTable, stdDegreesTable ]=computeMAIAgroupMeansDegrees(indexMeanTable, indexStdTable,meanMethod)
%  [meanDegreesTable, stdDegreesTable ]=computeMAIAgroupMeansDegrees(indexMeanTable, indexStdTable,meanMethod)
%
%  This function takes in the multi group index-wise mean tables produced
%  by computeMAIAgroupMeansIndexes and uses that information to compute
%  ring or full iterative means.
%
%  INPUTS
%
%  indexMeanTable:  the mean table from computeMAIAgroupMeansIndexes,  rows
%  are the group/eye - wise means of each index (1:max, including a column
%  for 1 which is filled with NaNs).
%
%  indexStdTable:  the stdTable from the aformentioned source
%
%  meanMethod: either "rings" or "full".  This indicates whether the
%  mean of the visual field should be computed as hollow, cocentric, 1mm
%  rings (think dart board) or as a full circle/elipsoid
%
%  OUTPUTS
%
%  meanDegreesTable:  A table with the iterative (across "degrees") mean  and standard deviation computed
%  for the data in indexMeanTable
%
%  stdDegreesTable:  A table with the iterative (across "degrees") mean  and standard deviation computed
%  for the data in indexMeanTable
%
%  Dan Bullock 17 Feb 2020
%% Begin code

%get varnames from table
inputVarNames=indexMeanTable.Properties.VariableNames;
%find the indexes of the node columns
indexIndexes=contains(inputVarNames,'index');
%set a vec for those names
nodeColumnNames={inputVarNames{indexIndexes}};

%initialize variables for while loop
totalPoints=0;
iIter=0;

%compute the number of indexes needed for the current data, but remember
%that you'll be ignoring column 1
while totalPoints(end)<length(nodeColumnNames)
    totalPoints(iIter+1)=4*iIter^2 + 1;
    iIter=iIter+1;
end

%delete the last one, because we necessarily go over
totalPoints(end)=[];

%extract the dataArray
meanDataArray=indexMeanTable{:,indexIndexes};
stdDataArray=indexStdTable{:,indexIndexes};

%if we just delete the nanColumn, we can ignore it and compute the mean of
%index point 0 as though it were 1
meanDataArray(:,2)=[];
stdDataArray(:,2)=[];

%get size of input table data
dataSize=size(meanDataArray);

%create blank output array, twice as long because now we include standard
%deviation in the table
outMeanArrayData=zeros(dataSize(1),length(totalPoints))*2;
outStdArrayData=outMeanArrayData;

for iMeans=1:dataSize(1)
    
    for iRings=1:length(totalPoints)
        
        %if it is 1 set it to the current index, otherwise, compute it
        if iRings==1
            currMeanMean=meanDataArray(iMeans,1);
            currMeanStd=0;
            currStdMean=stdDataArray(iMeans,1);
            currStdStd=0;
        else
            %get the index range in accordance with the input mean method
            if strcmp(meanMethod,'rings')
            %derive current range of indexes
            currRange=[[totalPoints(iRings-1)+1]:[totalPoints(iRings)]];
            elseif strcmp(meanMethod,'full')
               currRange=[1:[totalPoints(iRings)]]; 
            else
                error('mean compute method not recognized')
            end
                
            %begin computing statistics
            currMeanMean=mean(meanDataArray(iMeans,currRange));
            currMeanStd=std(meanDataArray(iMeans,currRange));
            %I don't know if these are necessary, but these correspond to
            %within group variance.  The standard deviation computed above
            %corresponds to the variance associated with biological
            %variability across average readings from the eye withing the current degree.
            currStdMean=mean(stdDataArray(iMeans,currRange));
            currStdStd=std(stdDataArray(iMeans,currRange));
        end
        %enter in current mean
        outMeanArrayData(iMeans,iRings)=currMeanMean;
        %enter in current std
        outMeanArrayData(iMeans,iRings+5)=currMeanStd;
         %enter in current mean for input std tabler
        outStdArrayData(iMeans,iRings)=currStdMean;
        %enter in current std for input std tabler
        outStdArrayData(iMeans,iRings+5)=currStdStd;
    end
    
    %setcolumn headers, just the ring name
    ringLabelsStrings= strcat('ring',cellfun(@num2str,num2cell(1:5),'UniformOutput',false));
    columnHeadersMean=strcat(ringLabelsStrings,'mean');
    columnHeadersStd=strcat(ringLabelsStrings,'std');
    
    %set the vector for the column headers for the output
    dataColumnHeaders=horzcat(inputVarNames{1:2},columnHeadersMean,columnHeadersStd);
    
    %create the cell structure for the output tables
    outMeanTableCellStruc=horzcat(indexMeanTable.Group,indexMeanTable.eye,num2cell(outMeanArrayData));
    outStdTableCellStruc=horzcat(indexMeanTable.Group,indexMeanTable.eye,num2cell(outStdArrayData));
    
    %create the output tables
    meanDegreesTable=cell2table(outMeanTableCellStruc,'VariableNames',squeeze(dataColumnHeaders));
    stdDegreesTable=cell2table(outStdTableCellStruc,'VariableNames',squeeze(dataColumnHeaders));
end