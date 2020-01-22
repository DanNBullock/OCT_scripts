function createCSVsumOutputFiles(subjDataDir,targetOutputDir,layerIndexSequences,analysesNames)
%createCSVsumOutputFiles(subjDataDir,targetOutputDir,layerIndexSequences,analysesNames)
%
%This is a semi-generalized function which creates the desired output csv
%files for all subjects/eyes in an input directory, <subjDataDir>.  Presumes input CSV
%files are in the format necessary for parseCsvExport. Outputs a csv which
%sums across each layer set specified in <layerIndexSequences>, named in
%accordance with input to <analysesNames>.  Saved to <targetOutputDir>.
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
% layerIndexSequences: a cell array of integer sequences corresponding to
% the layers reprsented in the subjects' input csv data arrays.  Measures
% will be summed across these in the ouput CSVs
%
% analysesNames: a cell array of strings corresponding to the desired names
% for the analyses.  Should be of same length as <layerIndexSequences>
%
%  OUTPUTS:
%
%  none, saves output CSVs to specified directory
%
% Adapted from code produced by Dan Bullock and Jasleen Jolley 05 Nov 2019
% Dan Bullock 22 Jan 2020
%%  Begin Code
% initialize relevant variables and perform checks

% set output directory if it isn't defined
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

%perform check to determine if <layerIndexSequences> and <analysesNames>
%inputs are of equal lengths.
if ~length(layerIndexSequences)==length(analysesNames)
    error('layerIndexSequences and analysesNames are of different lenghts')
else
    fprintf('\n %i output analsis files to create per subject')
end

%% Begin file parsing and output creation

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


for isubjects = 1:length(csvpaths) %Begins by iterating over subjects
    
    % uses proprietary parseCSVExport to get csv data
    curcsv = parseCsvExport(csvpaths{isubjects});
    
    for iAnalyses=1:length(analysesNames) %iterates over analyses
        currentLayers=layerIndexSequences{iAnalyses};
        %uses <currentLayers> to index across the relevant layers of <curcsv>, notably in the third dimension.  Subsequently sums those layers. 
        outputArray = [sum(curcsv(:,:,currentLayers),3)]';
        %here we generate the name for this specific analysis/synthesis output, using <subjectID>, <eye>, and <analysesNames>
        outPutName=strcat(subjectID{isubjects},'_',eye{isubjects},'_',analysesNames{iAnalyses});
        %append .csv
        outputCSVname=strcat(outPutName,'.csv');
        %generate filepath name for output
        %NOTE THIS IS CHANGED FROM THE PREVIOUS VERSION WHICH USED STRCAT.
        %THIS IS BECAUSE WE WERE PREVIOUSLY CATTING A '\', WHICH WAS
        %SPECIFIC TO WINDOWS ENVIRONMENTS.  IT IS POSSIBLE THAT \n MAY
        %CAUSE PROBLEMS FOR THIS SAME REASON
        outFileName=fullfile(targetOutputDir,outputCSVname);
        %here we write the csv out.
        csvwrite(outFileName,outputArray);
        %bit of a terminal report here
        fprintf('\n Cross layer sum csv creation for layer(s) %s for %s complete for %s', num2str(layerIndexSequences{iAnalyses}), strcat(subjectID{isubjects},'_',eye{isubjects}), analysesNames{iAnalyses})
   
    end %end of <analysesNames> iteration.
    %creates space between iterations outputs
    fprintf('\n')
end  %end of <subjDataDir> CSV file iteration.

end % end of function