


%this could be a variable input
subjDataDir = '/N/u/dnbulloc/Carbonate/OCT_Data/Data';

targetOutputDir='/N/u/dnbulloc/Carbonate/OCT_Data/PrimaryData';

analysisMeanDir='/N/u/dnbulloc/Carbonate/OCT_Data/subjectLayerAnalyses';



centroidCSVPath='/N/u/dnbulloc/Carbonate/OCT_Data/Location/Location.csv';

%these are the layers we want to analyse with the associated names
%THESE WOULD LIKELY BE VARIABLE INPUTS
layerIndexSequences={1:7,1:4,5,6};
%THESE WOULD EITHER BE VARIABLE INPUTS OR TAKEN IN FROM TABLE
analysesNames={'TT','NL','ONL','PROS'};


createCSVsumOutputFiles(subjDataDir,targetOutputDir,layerIndexSequences,analysesNames)


analyzeOCTDataWrapper(targetOutputDir,analysisMeanDir,centroidCSVPath,20, 'full')
