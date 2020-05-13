function [outTable]=computeMAIAsubjectMeansDegrees(MAIAdirTable,sectionIndexes)
%  [meanDegreesTable, stdDegreesTable ]=computeMAIAsubjectMeansDegrees(MAIAdirTable, indexStdTable)
%
%  This function takes in the multi subject table produced
%  by MAIAdirTable and uses that information to compute
%  the means and standard deviations of the indexes indicated by sectionIndexes.
%
%  INPUTS
%
%  MAIAdirTable:  The table output from MAIAdirArray.
%
%  sectionIndexes:  A cell array with integer sequences indicating which
%  indexes (from the MAIA reading) that you would like to have iteratively
%  averaged.  Must be a cell array in order to handle sequences of
%  different lenths.
%
%  OUTPUTS
%
%  outTable: a table containing the requested sequence means and standard
%  deviations for each row of the input table.
%
%  Dan Bullock 17 Feb 2020
%  Modified for single subject applications Dan Bullock May 13 2020
%% Begin code

%set up the output vectors
subjectIDVec=MAIAdirTable.subjectID;
subjectEyeVec=MAIAdirTable.eye;

%obtain the size of the input data array
inputTableSize=size(MAIAdirTable);
%convert to cell array
tableDataHold = table2cell(MAIAdirTable);
%extract the numerical index data
indexArraydata=cell2mat(tableDataHold(:,3:end));

%initalize array for table creation
outDataArray=zeros(inputTableSize(1),length(sectionIndexes)*2);

for iRows=1:inputTableSize(1)
    
    for iRings=1:length(sectionIndexes)
    
        %extract the indexes for the current ring
        %add one because of the inclusion of the 0 index
        currentIndexes=sectionIndexes{iRings}+1;
        %index only those that we are currently interested in
        currentRingThresholds=indexArraydata(iRows,currentIndexes);
        
        %compute mean and std of these thresholds
        currMean=mean(currentRingThresholds);
        currStd=std(currentRingThresholds);
        
        %enter in current mean
        meanDegreesVec(iRings)=currMean;
        %enter in current std
        stdDegreesVec(iRings)=currStd;
    
    end
    %fill in the array
    outDataArray(iRows,:)=[meanDegreesVec stdDegreesVec];
    meanDegreesVec=[] ;
    stdDegreesVec=[];
end

% createoutput table headers
meanColumns=[];
stdColumns=[];
for iColumns=1:length(sectionIndexes)
    meanColumns{iColumns}=strcat('sequence_',num2str(iColumns),'_mean');
    stdColumns{iColumns}=strcat('sequence_',num2str(iColumns),'_std');
end

%create vull column header vector
columHeaders={'SubjectID','Eye',meanColumns{:}, stdColumns{:}};

%convert data to cell array
dataCellArray=num2cell(outDataArray);

%concat the structure
tableCellStruc=horzcat(subjectIDVec,subjectEyeVec,dataCellArray);

%make the output table
outTable = cell2table(tableCellStruc,'VariableNames',columHeaders);

end %done