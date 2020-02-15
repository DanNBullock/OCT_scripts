function [MeanVec]=MAIAsubjectMeanGen(subjectFilePath,meanMethod)
%[MeanVec]=MAIAsubjectMeanGen(subjectFilePath,meanMethod)
%
%  This function takes in the data output from a MAIA reading and iteratively computes
%  the average (in accordace with the meanMethod input)
%
%  INPUTS:
%
%  subjectFilePath: Path to single subject's MAIA output.
%
%  meanMethod: either "rings" or "full".  This indicates whether the
%  mean of the visual field should be computed as hollow, cocentric, 1mm
%  rings (think dart board) or as a full circle/elipsoid.
% 
%  OUTPUTS:
%
%  MeanVec:  A single row vector with as many iterative means computed as
%  the input data permits
%
%  Dan Bullock  15 Feb 2020 
%%  Begin Code

%no need to save it, lets just use it
currentdataTable=readtable(subjectFilePath,'delimiter','\t');

%  initialize variables
totalPoints=0;
iIter=0;

%compute the number of indexes needed for the current data
while totalPoints(end)<length(currentdataTable.ID)
    totalPoints(iIter+1)=4*iIter^2 + 1;
    iIter=iIter+1;
end

%remove the extra number.  In order to break out of the above loop you have
%to exceed the data available.
totalPoints=totalPoints(1:end-1);

%iterate until you hit limit
for iMeans=1:length(totalPoints)-1
    if strcmp(meanMethod,'rings')
        %just the current ring
        curIndexes=[totalPoints(iMeans)+1]:[totalPoints(iMeans+1)];
    elseif strcmp(meanMethod,'full')
        %middle to current ring
        curIndexes=[totalPoints(1)+1]:[totalPoints(iMeans+1)];        
    else
       error('mean method specification not understood') 
    end
    
    %now compute the mean for the current indexes   
    MeanVec(iMeans)=mean(curIndexes);
    
end

end


