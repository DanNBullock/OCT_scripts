function createRawOCTSubjectDirectoryStructure(subjDataDir,targetOutputDir, centroidCSVPath)
%createRawOCTSubjectDirectoryStructure(subjDataDir,targetOutputDir, centroidCSVPath)
%
%This is a function that is used to create a subject level directory
%structure for OCT data analysis.  Previously, centroid data was kept in a
%separate, group level file (input here as centroidCSVPath).  However, for
%cloud/parallel processing purposes group level files liek this are not
%ideal.  As such, this function creates a directory structure with
%the raw input data and the associated centroid file.
%
%  INPUTS:
%
%  subjDataDir:  The directory that contains the subject/eye specific data.
%  Should contain no files other than the relevant CSVs.  Directory can
%  contain sub-directories, though this function will not search for files
%  within them.
%
%  targetOutputDir:  the directory that the output of this function should
%  be saved to.  If not specified creates an output directory
%  ('primaryOutput') within the <subjDataDir> directory
%
%  centroidCSVPath:  path to the CSV file containing the data indicating
%  the centroid? of the eye
%
%
%  OUTPUTS:
%
%  none, saves output CSVs to specified directory
%
% Adapted from code produced by Dan Bullock and Jasleen Jolley 05 Nov 2019
% Extensive rewrite/functionalization by Dan Bullock 22 Jan 2020
% Function readapted by Dan Bullock May 12 2020 for directory creation
%
%% Subfunctions
%
%  parseCsvExport.m
%
%%  Begin Code
% initialize relevant variables and perform checks

% set output directory to subdirectory of <subjDataDir> if it isn't defined, 
if isempty(targetOutputDir)
    targetOutputDir=fullfile(subjDataDir,'primaryOutput');
else
    %do nothing
end

%create output directory if it doesnt exist
if ~isfolder(targetOutputDir)
    mkdir(targetOutputDir);
else
    %do nothing
end

%% Begin file parsing and output creation

%load the excel file to obtain the centroid data
centroidTable =readtable(centroidCSVPath);

%here we obtain the entire column under the table heading <Filename>, returns a cell string vector
centerNames=centroidTable.Filename;

%extract the contents of the input <subjDataDir>
subjectDirContents = dir(subjDataDir);

%extract the file names of the contents of <subjDataDir>
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
csvpaths = fullfile(subjDataDir,fileNames);

% this extracts the relevant layer values from each subject file and
% outputs results with the relevant ID and eye details. These are written
% to new CSVs for each layer we are interested in.


for iInputFiles = 1:length(csvpaths) %Begins by iterating over subjects
    
    %make an output directory for this subject
    currentSubjDirectory=fullfile(targetOutputDir,subjectID{iInputFiles});
    if ~isfolder(currentSubjDirectory)
    mkdir(currentSubjDirectory);
    else
        %do nothing
    end
    
    %establish current csv file path
    currentCsvPath=csvpaths{iInputFiles};
    %pull out the file name so we can compare it to the Location.csv
    [~,currFilename,~]=fileparts(currentCsvPath);
    
    %find the relevant index, assume nothing about sequence
    locationFileRowIndex=find(strcmp(currFilename,centerNames));
    
    % set X and Y of the centroid
    % be careful though because there appears to be a mismatch between our intuitions about x and y and the standard indexing practices of matlab
    currentXVal=centroidTable.position(locationFileRowIndex);
    currentYVal=centroidTable.slice(locationFileRowIndex); 
    
    %generate filename for raw data object
    newFileName=fullfile(currentSubjDirectory,strcat(eye{iInputFiles},'_raw.csv'));
    % copy the file over
    copyfile(csvpaths{iInputFiles}, newFileName)

    %create simple file for centroid coordinate storage.
    eyeCentroidFileName=strcat(currentSubjDirectory,'/',eye{iInputFiles},'_centroid.csv');
    writematrix([currentXVal currentYVal],eyeCentroidFileName);
    
    
    %creates space between iterations outputs
    
end  %end of <subjDataDir> CSV file iteration.

end % end of function