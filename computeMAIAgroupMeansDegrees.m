function [meanDegreesTable, stdDegreesTable ]=computeMAIAgroupMeansDegrees(indexMeanTable, indexStdTable,meanMethod)




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

dataSize=size(meanDataArray);

for iMeans=1:length()
    
    for iRings=1:length(totalPoints)-1
        
        

            
        
        %
    

    end

end