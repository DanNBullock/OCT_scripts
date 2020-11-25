%set path appropriately.  Comment out if you'd like
path2Repo='/N/u/dnbulloc/Carbonate/gitProjects/OCT_scripts';
addpath(genpath(path2Repo))

%path to the raw subject data directory
path2RawSubjectDir='/N/u/dnbulloc/Carbonate/OCT_Data/Data/'
%path to the location CSV file with centroid information
path2CentroidFile='/N/u/dnbulloc/Carbonate/OCT_Data/Location/Location.csv'
%path to output nifti files
outputDir='/N/u/dnbulloc/Carbonate/OCT_Data/Niftis/';
%make the directory if it doesn't exist
if(~(exist(outputDir)==4))
    mkdir(outputDir)
end

%get the input dir contents
rawDirContents=dir(path2RawSubjectDir);
%get the csv files from that output
csvDirContentNames={rawDirContents.name};
subjectCsvFilePaths=csvDirContentNames(~[rawDirContents.isdir]);

%iterate across csv files
for iCsvFiles=1:length(subjectCsvFilePaths)
    %get current path name
    currentCsv=fullfile(path2RawSubjectDir,subjectCsvFilePaths{iCsvFiles});
    %make the nifti
    OCTNIFTIout=OCT2NIFTIwrapper(currentCsv,path2CentroidFile);
    %save the nifti
    [~,currentSubjLabel,~]=fileparts(currentCsv);
    %set current nifti path
    currentNiftiPath=fullfile(outputDir,[currentSubjLabel,'.nii']);
    %save it down
    save_nii(OCTNIFTIout, currentNiftiPath)
end
