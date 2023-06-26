"""
Conversion of matlab code for OCT_scripts to python

"""


"""
Note: the following section is for local testing and loading only.
Will be commented out in production


import pandas as pd
import numpy as np
# import raw data from csv file
pathToRawCSV='/home/dan/Downloads/OD_raw.csv'
# load it with pandas, but remember it's comming from an excel file with multiple sheets even though it's a csv
rawDataDF = pd.read_csv(pathToRawCSV,header=None)
# the current csv is essentially several sheets stacked together, wherein the sheets are split by a row that has the name of the sheet in the first column, and the rest of the row values are nan.
# We can use this to split the data into a list of dataframes, each dataframe being a sheet
# First we find the rows that have the sheet names and get a boolean mask for this
sheetNameRowMask=[np.char.isnumeric(iContent.replace('.','')) for iContent in rawDataDF.iloc[:,0].values]
# i think this returns a list of arrays with single values, so we need to flatten it AND ALSO NEGATE IT
sheetNameRowMask=np.logical_not(np.array(sheetNameRowMask).flatten())
# now we can use this mask to split the data into a list of dataframes
# let's store this as a dictionary with the sheet name as the key and the dataframe as the value
# first create a blank dictionary
rawDataDFDict={}
# find the indices of the sheet name rows from the mask
sheetNameRowIndices=np.where(sheetNameRowMask)[0]
# append the last row index to the end of the list
sheetNameRowIndices=np.append(sheetNameRowIndices,rawDataDF.shape[0])
# loop through the indices and split the data into dataframes, but remember that the last index is not inclusive
for iIndex in range(len(sheetNameRowIndices)-1):
    # get the sheet name
    sheetName=rawDataDF.iloc[sheetNameRowIndices[iIndex],0]
    # get the dataframe
    sheetDF=rawDataDF.iloc[sheetNameRowIndices[iIndex]+1:sheetNameRowIndices[iIndex+1],:]
    # retype the dataframe content to float
    sheetDF=sheetDF.astype(float)
    # add the dataframe to the dictionary
    rawDataDFDict[sheetName]=sheetDF

# now we load the centroid data, should be fairly easy, as it is just a csv with two values in it
pathToCentroidCSV='/home/dan/Downloads/OD_centroid.csv'
centroidDF=pd.read_csv(pathToCentroidCSV,header=None)
# we can set these values to centroidXYVal, but keep in mind that the first value is actually the y / vertical index and the second vlaue is the x / horizontal index
centroidXYVal=[centroidDF.iloc[0,1],centroidDF.iloc[0,0]]
"""

"""
Copying over the table describing the parameter values/meanings from the readme for the matlab code

| **Parameter variable name** | **Purpose** | **Specifications** |
| --- | --- | --- |
| layerIndexSequences | Indicates which layers are to be summed in createCSVsumOutputFiles to generate the layer amalgams that will be processed later. | Sequence[1] of sequence[2] of integers.  Sequence[1] must be equal to the number of inputs in analysesNames.  sequence[2] must be unique integers which do not exceed the total number of layers obtained from Voxeleron&#39;s [deviceName] |
| analysesNames | Indicates the abbreviation for the layer amalgam, corresponds to [specify standard]. | Set of strings, equal in length to sequence[1] of layerIndexSequences |
| visFieldDiam | Indicates the total _diameter_ of the visual field measured by the experimenter.  Assumed to be consistent across subjects.  The user/experimenter should know this about their data.The code must be amended if this is not the case, e.g. retrospective analysis of clinical data. | Numerical value |
| theshFloor | Specifies the desired threshold to be applied to input data obtained from createCSVsumOutputFiles.   Applied across subjects (prior to computation of means).  Values below this are set to NaN and are not featured in computation of mean.  If no threshold is desired, enter a value of []. | Numerical value |
| gaussKernel | Specifies the desired smoothing kernel to be applied to input data obtained from createCSVsumOutputFiles.   Applied across subjects (prior to computation of means).  Pixel values are thus the result of a gaussian smoothing process.  If no threshold is desired, enter a value of [] or 1. | Odd integer value |
| meanShape | Specifies the desired method for computing the mean.  &quot;rings&quot; will generate averages for concentric, degree-specific rings (like a bullseye), while &quot;full&quot; will compute the mean for the entire visual field (to the specified current, iterated degree). | Either &quot;rings&quot; or &quot;full&quot; |


# here we're just going to manually set some of the parameters that would usually be passed via the config.json file
# basing this off of the test case that we are currently debugging
visFieldRadiusLimit= 15 # aka visFieldDiam * .5
layerIndexSequences = "1:7,1:4,5:6"
analysesNames = "TT,IR,PRC"
visFieldDiam = 30
theshFloor = 0
gaussKernel = 1
meanShape = "rings"

"""

"""
import os
#Test Script setup: pathing
dataDir='/media/dan/HD4/coding/gitDir/OCT_scripts/testData'
dataFilePath=os.path.join(dataDir,'OD_raw.csv')
centroidFilePath=os.path.join(dataDir,'OD_centroid.csv')
configParamsFilePath=os.path.join(dataDir,'config.json')
testSaveData=os.path.join(dataDir,'testOut')
testSaveFigs=os.path.join(testSaveData,'testFigs')

OCTanalysisScriptWrapper(dataFilePath,centroidFilePath,configParamsFilePath,testSaveData,testSaveFigs)

"""


def OCTanalysisScriptWrapper(dataFilePath,centroidFilePath,configParamsFilePath,dataSaveDirPath,figSaveDirPath):
    """
    The following is a wrapper script that takes in the relevant file paths and runs the OCT analysis pipeline.
    It then saves down the results to the specified save directory paths.

    Parameters
    ----------
    dataFilePath : str
        The path to the csv file containing the raw data (for a single eye).
    centroidFilePath : str
        The path to the csv file containing the centroid data (for a single eye).
    configParamsFilePath : str
        The path to the json file containing the configuration parameters.
    dataSaveDirPath : str
        The path to the directory where the CSV-formmated ouput data should be saved.
    figSaveDirPath : str
        The path to the directory where the figures should be saved.
    """
    import pandas as pd
    import numpy as np
    import json
    import os

    # load the centroid data
    centroidDF=pd.read_csv(centroidFilePath,header=None)
    # load the config params
    with open(configParamsFilePath) as f:
        configParamsDict=json.load(f)

    # go ahead parse the input raw data path into a dictionary of dataframes
    rawDataDictionary=multiSheetDictFromExcelCSV(dataFilePath)

    # also use this opportunity to check the file path to see if the file name provides
    # any hint about which eye the data is from
    # if the file name contains 'OD' then we assume it is from the right eye
    # if the file name contains 'OS' then we assume it is from the left eye
    # if the file name contains neither, we'll just set the eye to ''
    if 'OD' in os.path.basename(dataFilePath):
        eye='OD'
    elif 'OS' in os.path.basename(dataFilePath):
        eye='OS'
    else:
        eye=''
    
    # pull out the preprocessing relevant parameters
    theshFloor=configParamsDict['theshFloor']
    gaussKernel=configParamsDict['gaussKernel']

    preProcessedData=prepOCTlayerData(rawDataDictionary,theshFloor=0,gaussKernel=0)

    # pull out the analysis relevant parameters
    #visFieldRadiusLimit=configParamsDict['visFieldRadiusLimit']
    layerIndexSequences=configParamsDict['layerIndexSequences']
    # here we have to implement an extrodinarily jank way of converting the input 
    # requested layers to pythonic indexes.  NOTE: the configuration for the app
    # assumes the user is inputting indexes in the format of [start]:[end], e.g. 1:7
    # which is not 0 indexed.  The solution is to iteratively identify contiguous
    # sequences of ONLY NUMERIC CHARACTERS, convert those to numeric values, reduce them by 1
    # and then replace the substring in the original string with the new value
    # this is a very jank solution, but it works for now

    
    # now we apply this ugly function to the layerIndexSequences
    layerIndexSequences=shiftStringNumbers(layerIndexSequences,'subtraction',1)


    analysesNames=configParamsDict['analysesNames']
    # lets also take this opportunity to overwrite the analysesNames with the additional eye information
    # if the eye is not specified, then we'll just leave it as is
    if not eye=='':
        # split the analysesNames string into a list
        analysesNames=analysesNames.split(',')
        # now iterate through the list and add the eye to the beginning of each element
        for i in range(len(analysesNames)):
            analysesNames[i]=eye + '_' + analysesNames[i]
        # now rejoin the list into a string
        analysesNames=','.join(analysesNames)


    visFieldDiam=configParamsDict['visFieldDiam']
    meanShape=configParamsDict['meanShape']
    # also load in the centroid data
    # NOTE: the centroid data is in the format [y,x] so we need to flip the order of the values
    # typically, this means that the first value is much smaller, indicating the row of the centroid, while the second number is much larger, and indicates the column of the centroid.  
    # the "row" and "column" terms here are in reference to the data matrix / data frame coming in from the file at dataFilePath
    # centroidXYVal=[centroidDF.iloc[0,1],centroidDF.iloc[0,0]]
    # CORRECTION: Actually, due to how indexing works, the first value is the row and the second value is the column
    # so we don't need to flip the order of the values
    centroidXYVal=[centroidDF.iloc[0,0],centroidDF.iloc[0,1]]
    
    # now that we have these we can run the analysis to obtain a dictionary of the statistical outputs
    analysesStatisticsDictionary=multiLayerOCTanalysis(preProcessedData,centroidXYVal,layerIndexSequences,analysesNames,visFieldDiam,meanShape=meanShape)
    # now that we have that we should save down each of the dataframes to the specified save directory
    for iDictionaryElements in analysesStatisticsDictionary:
        # yes this is silly, but this is how we are doing it.
        currentKey=iDictionaryElements
        currentDictionary={}
        currentDictionary[currentKey]=analysesStatisticsDictionary[currentKey]
        fileName=currentKey+'.csv'
        # remember that there are two dataframes, one associated with key 'ringMeansDF' and one associated with'ringSTDsDF'
        # first we'll save down the means
        analysesStatisticsDictionary[currentKey]['ringMeansDF'].to_csv(os.path.join(dataSaveDirPath,'mean_'+fileName),index=False)
        # then we'll save down the standard deviations
        analysesStatisticsDictionary[currentKey]['ringSTDsDF'].to_csv(os.path.join(dataSaveDirPath,'std_'+fileName),index=False)
        # now we can also produce and save down the figures.  Be sure to set the showFigures flag to False so that the figures are saved down as this is presumably being run containerized or in a batch.
        # set the name of the figure depending on if you have information about the eye
        figName=currentKey+'.png'
        quadrantRadarFigFromAnalysisDFs(currentDictionary,figsize=(20,10),dpi=100,saveFig=False,saveDir=figSaveDirPath,analysisName=currentKey,showFig=False,colormaps=['viridis_r','plasma'])
    
    # should be complete
    return

def shiftStringNumbers(fullString,desiredShiftType,shiftValue):
    """
    This function takes in a string and shifts all instances of contiguous numeric values in the string by the specified shiftValue.
    The shift type specfies whether the value should be increased (addition) or decreased (subtraction).
    The function returns the updated string.
    
    Parameters
    ----------
    fullString : str
        The string to be shifted.
    desiredShiftType : str
        The type of shift to be applied.  Must be either 'addition' or 'subtraction'.
    shiftValue : int
        The value to be applied to the shift.
        
    Returns
    -------
    shiftedString : str
        The updated string with the specified shift applied.
    """
    import re
    
    # first, we need to identify all of the contiguous sequences of numeric characters
    # we can do this using the re.findall function
    numericSequences=re.findall(r'\d+',fullString)
    # we also need to find the starting and ending indices of each numeric sequence so that we can replace these values
    numericSequenceIndices=[(x.start(),x.end()) for x in re.finditer(r'\d+',fullString)]
    # also get the non-numeric sequences
    nonNumericSequences=re.findall(r'\D+',fullString)

    # now we need to convert these to numeric values
    numericSequences=[int(x) for x in numericSequences]
    # now we need to shift these values
    if desiredShiftType=='addition':
        numericSequences=[x+shiftValue for x in numericSequences]
    elif desiredShiftType=='subtraction':
        numericSequences=[x-shiftValue for x in numericSequences]
    else:
        raise ValueError('The desiredShiftType must be either "addition" or "subtraction"')
    # now we need to convert these back to strings
    numericSequences=[str(x) for x in numericSequences]
    # now we need to replace the original numeric sequences with the updated ones
    # we can iterate through the numericSequenceIndices and replace the substrings
    shiftedString=fullString

    # now cat together the numericSequences and nonNumericSequences, starting with numericSequences
    # and then switching back and forth between the two
    # NOTE: we need to add a nonNumericSequence to the beginning of the list to account for the first numericSequence
    nonNumericSequences.insert(0,'')
    # now interleave the two lists
    mergedListOfStrings=[val for pair in zip(nonNumericSequences,numericSequences ) for val in pair]
    # now simply join the list together
    shiftedString=''.join(mergedListOfStrings)

    return shiftedString

def multiLayerOCTanalysis(rawDataDictionary,centroidValues,layerIndexSequences,analysesNames,visFieldDiam,meanShape='rings'):
    """
    This function takes in a dictionary of dataframes, where each dataframe is a layer of OCT data, and performs a series of analyses on them.
    The analyses are specified by the parameters passed to the function, which are the same as those used in the matlab code.
    The function returns two dataframes, one containing the mean values for each layer at each degree, and one containing the standard deviation for each layer at each degree.

    Parameters
    ----------
    rawDataDFDict : dict
        A dictionary containing the dataframes for each layer, with the layer name as the key.
    centroidValues : list, two elements
        A list containing the x and y coordinates of the centroid of the OCT scan.        
    layerIndexSequences : str
        A string containing the layer indices to be summed for each layer amalgam, where the layer indices are separated by colons and the layer amalgams are separated by commas.
    analysesNames : str
        A string containing the names of the layer amalgams, where the names are separated by commas.
    visFieldDiam : int
        The diameter of the visual field in degrees.
    theshFloor : int
        The threshold value to be applied to the data. The default is 0.
    gaussKernel : int
        The size of the gaussian kernel to be applied to the data. The default is 0, which means no smoothing.
    meanShape : str
        The shape of the mean to be computed. The default is 'rings', which means that the mean will be computed for concentric, bullseye-like rings.

    Returns
    -------
    ringMeansDF : pandas.DataFrame
        A dataframe containing the mean values for each layer at each degree.
    ringSTDsDF : pandas.DataFrame
        A dataframe containing the standard deviation for each layer at each degree.
    """
    import numpy as np
    # load ndimage, which is the scipy module for image processing, and the equivalent of imresize in matlab
    from scipy import ndimage
    from warnings import warn

    # create a blank dictionary to hold the initial, per-layer results
    layerResultsDict = {}

    # go ahead and compute the means and standard deviations for each layer, using ringMeansForOCTlayer
    for layerName,rawDataDF in rawDataDictionary.items():
        # note that we are passing half the visual field diameter, since the function expects a radius
        ringMeansDF, ringSTDsDF=ringMeansForOCTlayer(rawDataDF, centroidValues, int(visFieldDiam * 0.5), shape=meanShape)
        # add the results to the dictionary
        layerResultsDict[layerName] = {'ringMeansDF':ringMeansDF,'ringSTDsDF':ringSTDsDF}
    
    # now that we have the per-layer results, we can go ahead and compute the mean and standard deviation for each layer amalgam
    # we'll do this by splitting the list of layerIndexSequences and analysesNames into individual strings, and then parsing them into the values they correspond to.
    # parse the layerIndexSequence into the correct value.  For example, the string '1:7' should be parsed into the range of values 1,2,3,4,5,6,7.  Also, if 
    # the string is expressed as a single value, like '1', we'll go ahead and parse it into a list containing that value, so that we can iterate over it later.
    # finally, for non-consecutive values, we'll assume that the numbers have been demarcated with something like
    # a parenthesis or brackets, e.g. "(1,3,5)".  We'll go ahead and parse these into a list of values as well.  This is highly unlikely to occur
    # but we may as well create logic for it.
    # first determine if there are any parentheses or brackets in the string
    # actually, on second thought, lets just assume that no one ever does this, and the only cases are single values and consecutive values.
    # we'll go ahead and create a list of lists, where each sublist contains the parsed values for each layerIndexSequence and analysisName
    layerIndexSequencesList = []
    analysesNamesList = []
    for layerIndexSequence,analysisName in zip(layerIndexSequences.split(','),analysesNames.split(',')):
        # first parse the layerIndexSequence
        if ':' in layerIndexSequence:
            # split the string into the two values
            layerIndexSequenceSplit = layerIndexSequence.split(':')
            # now parse the values into a list
            currentSequence = list(np.arange(int(layerIndexSequenceSplit[0]),int(layerIndexSequenceSplit[1])+1))
        
        else:
            # parse the single value into a list
            currentSequence = [int(layerIndexSequence)]
        # now append the list to the layerIndexSequencesList
        layerIndexSequencesList.append(currentSequence)
        # now append the analysisName to the analysesNamesList
        analysesNamesList.append(analysisName)

    # create a blank dictionary to hold the resuts of each analysis
    layerAmalgamResultsDict = {}
    # now that we have the layerIndexSequencesList and the analysesNamesList, we can go ahead and iterate over them and compute the mean and standard deviation for each layer amalgam
    for layerIndexSequence,analysisName in zip(layerIndexSequencesList,analysesNamesList):
       # use singleMultiLayerAnalysis to compute the mean and standard deviation for the layer amalgam
        layerAmalgamResultsDict.update(singleMultiLayerAnalysis(layerResultsDict,layerIndexSequence,analysisName) )
    return layerAmalgamResultsDict

def singleMultiLayerAnalysis(omnibusStatisticsDFsDict,layerIndexSequence,analysisName):
    """
    This function performs a single multi-layer analysis of multi-layer OCT data.
    By this, we mean that the omnibus, all-layer data dictionary is taken and the specified layers are
    combined into an amalgum, and the statistics are merged accordingly.

    Parameters
    ----------
    omnibusStatisticsDFsDict : dictionary
        A dictionary containing the computed statistics dataframes (mean and standard deviation) for *each* layer (yes, some or many of these won't be used in a given analysis).
        The keys are the layer names, and the values are dictionaries containing the mean and standard deviation dataframes for each layer.
    layerIndexSequence : list of int
        A list of layer indexs that are to be combined into a single amalgum.  Because we are presumably
        using python version 3.7 or greater, we can assume that the order of the dictionary keys is preserved, and so the numeric indexes can be relied upon.
    analysisName : string
        A list of the names of the analyses to be performed.  This is used to name the keys of the returned dictionary and/or provide information for figure titles.
    
    Returns
    -------
    layerAmalgamResultsDict : dictionary
        A dictionary containing the computed statistics dataframes (mean and standard deviation) for the amalgamated layers.
        The top level key is the analysis name, and the sub-dictionary contains the mean and standard deviation dataframes for each layer, with keys 'ringMeansDF' and 'ringSTDsDF', respectively.
    """
    import numpy as np
    import pandas as pd
    # get the names of the dictionary keys for the omnibusStatisticsDFsDict
    layerResultsDictKeys = list(omnibusStatisticsDFsDict.keys())
    # create a blank dictionary to hold the output
    layerAmalgamResultsDict = {}
    # select the relevant layerResultsDFs from the layerResultsDict, remember that the keys are strings, so use layerResultsDictKeys to obtain those.    
    layerResultsDFs=[]
    for layerIndex in layerIndexSequence:
        # collect the requested layers into the contents of layerResultsDFs
        layerResultsDFs.append(omnibusStatisticsDFsDict[layerResultsDictKeys[layerIndex]])

    layerResultsDFs = [omnibusStatisticsDFsDict[layerResultsDictKeys[i]] for i in layerIndexSequence]
    # remember that inside each of these dictionary elements there are two dataframes, one for the ringMeansDF and one for the ringSTDsDF
    # we'll be taking the mean of each of these to obtain the layer amalgam results.  Be sure that the mean computation is robust to Nans, in case there are any NaNs in the data.
    # we'll ensure nan robustness by temporarily converting these to arrays and using np.nanmean
    # first convert the layerResultsDFs to arrays
    layerResultMeanDFs = [np.array(layerResultsDF['ringMeansDF']) for layerResultsDF in layerResultsDFs]
    # do the same for the layerResultSTDsDFs
    layerResultSTDsDFs = [np.array(layerResultsDF['ringSTDsDF']) for layerResultsDF in layerResultsDFs]
    # now we can go ahead and compute the amalgam mean and standard deviation for this layer amalgam
    ringWiseMeans = np.nanmean(layerResultMeanDFs,axis=0)
    ringWiseSTDs = np.nanmean(layerResultSTDsDFs,axis=0)
    # now we can go ahead and convert these back to dataframes, and use the column headings from the first layerResultsDF
    ringMeansDF = pd.DataFrame(ringWiseMeans,columns=layerResultsDFs[0]['ringMeansDF'].columns)
    ringSTDsDF = pd.DataFrame(ringWiseSTDs,columns=layerResultsDFs[0]['ringSTDsDF'].columns)
    # add the results to the layerAmalgamResultsDict
    layerAmalgamResultsDict[analysisName] = {'ringMeansDF':ringMeansDF,'ringSTDsDF':ringSTDsDF}
    return layerAmalgamResultsDict

def quadrantRadarPlotFromQuadrantDF(quadrantDF,figsize=(10,10),dpi=100,saveFig=False,saveDir='',saveName='',showFig=True,colormap='viridis_r'):
    """
    This function takes in a dataframe containing the quadrant-wise values for a series of rings, and plots them as a "sunburst-like" plot.
    By this, it is meant that the rings are plotted as concentric circles, and the quadrants are plotted as pie slices within each ring, with their quadrant divisors being shared across rings.
    The function returns the figure and axes handles.
    Parameters
    ----------
    quadrantDF : pandas dataframe
        A dataframe containing the quadrant-wise values for a series of rings.  The dataframe should have four columns, one for each quadrant, and the index should be the ring number, offset by 1 due to 0 indexing.
        The sequence of quadrants is assumed to follow cartesian convention, i.e. Q1 is the upper right quadrant, Q2 is the upper left quadrant, Q3 is the lower left quadrant, and Q4 is the lower right quadrant, relative to the centroid.
    figsize : tuple, optional
        The size of the figure. The default is (10,10).
    dpi : int, optional
        The resolution of the figure. The default is 100.
    saveFig : bool, optional
        Whether or not to save the figure. The default is False.
    saveDir : str, optional
        The directory to save the figure in. The default is ''.
    saveName : str, optional
        The name to save the figure as. The default is ''.
    showFig : bool, optional
        Whether or not to show the figure. The default is True.
    colormap : str, optional
        The colormap to use for the plot. The default is 'viridis_r'.

    Returns
    -------
    fig : matplotlib figure handle
        The figure handle for the plot.
    ax : matplotlib axes handle
        The axes handle for the plot.
    """
    import matplotlib.pyplot as plt
    import numpy as np
    # first create the figure and axes handles
    fig,ax = plt.subplots(figsize=figsize,dpi=dpi,subplot_kw=dict(polar=True))
    # now we'll go ahead and plot the data
    # first we'll need to get the number of rings
    numRings = len(quadrantDF)
    # now we'll need to get the number of quadrants, it's kind of implied by the name "quadrant" but whatever may as well be thorough
    numQuadrants = len(quadrantDF.columns)
    # next we get the values in the dataframe
    quadrantValues = np.array(quadrantDF)
    # now we'll need to get the angles for each quadrant, we'll do this by dividing 2pi by the number of quadrants
    quadrantAngles = np.linspace(0,2*np.pi,numQuadrants,endpoint=False)
    # now we'll need to get the radii for each ring, we'll do this by dividing 1 by the number of rings
    ringRadii = np.linspace(0,1,numRings,endpoint=False)
    # now we can go ahead and plot the data
    # we'll do this by iterating over the rings, and plotting each quadrant as a pie slice
    for ringIndex,ringRadius in enumerate(ringRadii):
        # get the values for all of the subsections of this ring
        ringValues = quadrantValues[ringIndex,:]
        # get the colors for all of the subsections of this ring, based on the values.
        # however, we need to be careful of nan values, so first we'll test 
        # if there are any nan values in the ringValues.  We'll need to set a blank vector for colors first though.  Make sure it is of the appropriate dimenssions
        ringColors = np.zeros((numQuadrants,4))
        if np.any(np.isnan(ringValues)):
            # if there are nan values, we'll need to set the colors for the non-nan values
            # first we'll need to get the indices of the non-nan values
            nonNanIndices = np.where(~np.isnan(ringValues))[0]
            # now we can go ahead and get the colors for the non-nan values
            ringColors[nonNanIndices,:] = plt.cm.get_cmap(colormap)(ringValues[nonNanIndices])
            # presumably, because the alpha value of the initialized ringColors is 0, the nan values will be transparent
        else:
            # if there are no nan values, we can go ahead and get the colors for all of the values
            ringColors = plt.cm.get_cmap(colormap)(ringValues)
        # now we can go ahead and plot the pie slices be sure that we're only coloring between the start and end of the current ring and not overlapping with previous or subsequent rings
        ax.bar(quadrantAngles,ringRadius,width=2*np.pi/numQuadrants,bottom=ringRadius,color=ringColors,edgecolor='white')
        #NOTE: I don't think the above works, but we'll try it for now
    # now we can go ahead and set the limits of the plot
    ax.set_ylim(0,1)
    # now we can go ahead and set the ticks for the plot
    # we'll do this by setting the ticks to be at the boundaries between rings and quadrants
    # first we'll need to get the angles for the boundaries between quadrants
    quadrantBoundaryAngles = np.linspace(0,2*np.pi,numQuadrants+1)
    # now we can go ahead and set the ticks
    ax.set_xticks(quadrantBoundaryAngles[:-1])
    # we won't set tick labels because that would get too busy
    # now we return the figure and axes handles
    return fig,ax

def quadrantRadarFigFromAnalysisDFs(analysisDFs,figsize=(20,10),dpi=100,saveFig=False,saveDir='',analysisName='',showFig=True,colormaps=['viridis_r','plasma']):
    """
    This function is an extension of quadrantRadarPlotFromQuadrantDF that will plot sunburst-like radar plots for both the mean and standard deviation of the rings in the analysisDFs.
    The function returns the figure and axes handles.  Also, if entered, the figure is saved to the specified directory with the specified name.
    
    Parameters
    ----------
    analysisDFs : dict
        A dictionary containing the a sub-dictionary with key-value pairings for the mean and standard deviation of a single analysis generated by singleMultiLayerAnalysis.
        The singular key of the top-level dictionary is assumed to be the name of the analysis, and will be used in place of '' if the default value for analysisName is used.
    figsize : tuple, optional
        The size of the figure. The default is (20,10).  Note that the width is twice the height, as the figure contains two subplots.
    dpi : int, optional
        The resolution of the figure. The default is 100.
    saveFig : bool, optional
        Whether or not to save the figure. The default is False.
    saveDir : str, optional
        The directory to save the figure in. The default is ''.
    analysisName : str, optional
        The name of the analysis. The default is ''.  If nothing is entered, the top-level key of the analysisDFs dictionary is used.
    showFig : bool, optional
        Whether or not to show the figure. The default is True.
    colormaps : list of str, optional
        The colormaps to use for the mean and standard deviation plots. The default is ['viridis_r','plasma'].  The first colormap is used for the mean, the second for the standard deviation.
        The default colormaps are chosen due to the implicit valence of values.  Yellow brighter colors are associated with presumably more concerning values, while darker colors are associated with presumably less concerning values.
    
    Returns
    -------
    fig : matplotlib figure handle
        The figure handle for the plot.
    ax : matplotlib axes handle
        The axes handle for the plot.
    """
    import matplotlib.pyplot as plt
    import os

    # first we'll need to get the analysis name if it wasn't entered
    if analysisName == '':
        analysisName = list(analysisDFs.keys())[0]
    # but also if the analysis name came in with a file extension, go ahead and split that off and save it for later.
    analysisName,analysisExtension = os.path.splitext(analysisName)
    # now we'll need to get the mean and standard deviation dataframes
    meanDF = analysisDFs[list(analysisDFs.keys())[0]]['ringMeansDF']
    stdDF = analysisDFs[list(analysisDFs.keys())[0]]['ringSTDsDF']
    # now we can go ahead and plot the data using quadrantRadarPlotFromQuadrantDF, which returns the figure and axes handles
    fig,ax = plt.subplots(1,2,figsize=figsize,dpi=dpi,subplot_kw=dict(polar=True))
    # now we can go ahead and plot the mean data, be sure to set showFig to False so that we don't show the figure twice
    quadrantRadarPlotFromQuadrantDF(meanDF,fig=fig,ax=ax[0],colormap=colormaps[0],showFig=False)
    # now we can go ahead and plot the standard deviation data, be sure to set showFig to what was entered so that we can show the figure if desired.
    # don't bother setting the saveFig or saveDir parameters, as we need to set the figure titles and labels first
    quadrantRadarPlotFromQuadrantDF(stdDF,fig=fig,ax=ax[1],colormap=colormaps[1],showFig=False)
    # now we can go ahead and set the titles and labels for the figure
    fig.suptitle(analysisName)
    ax[0].set_title('Quadrant-wise Mean')
    ax[1].set_title('Quadrant-wise Standard Deviation')
    # the rest should be fairly self-explanatory
    # this would be really cool to implement, but it requires a method of detecting which eye the data is coming from: e.g. OD vs OS
    # remember, OD is right eye, OS is left eye
    # actually, lets go ahead and implement this, by checking if the analysis name contains OD or OS
    if 'OD' in analysisName:
        eye = 'OD'
    elif 'OS' in analysisName:
        eye = 'OS'
    else:
        eye = ''
    # now we can go ahead and set the labels
    # let's assume that the data has been oriented appropriately given the source eye
    # NOTE: JASLEEN, WE SHOULD CHECK TO ENSURE THAT THIS IS THE CASE
    # if that assumption is correct, we don't need to do anything special to the labels, so we'll start by creating a vector for the label names
    labelNames = ['Superior','Inferior','Nasal','Temporal']
    # now we can go ahead and set the labels
    ax[0].set_xticklabels(labelNames)
    ax[1].set_xticklabels(labelNames)
    # at this point all of the relevant information has been set so we can go ahead and either show it or save it
    if saveFig:
        if not analysisExtension == '':
            analysisName = analysisName + '.' + analysisExtension
        else:
            analysisName = analysisName + '.png'
        fig.savefig(os.path.join(saveDir,analysisName))
    if showFig:
        fig.show()
    # now we can go ahead and return the figure and axes handles
    return fig,ax

def prepOCTlayerData(rawDataDFDict,theshFloor=0,gaussKernel=0):
    """
    This function takes in a dictionary of dataframes, where each dataframe is a layer of OCT data, and performs a series of preprocessing steps on them, in accordance
    with the parameters passed to the function.  The function returns a dictionary containing the preprocessed dataframes.

    Parameters
    ----------
    rawDataDFDict : dict
        A dictionary containing the dataframes for each layer, with the layer name as the key.
        Typically this dictionary is generated by multiSheetDictFromExcelCSV.
    theshFloor : int
        The threshold value to be applied to the data. Values below this are set to Nan, such that they don't impact 
        the computation of the mean or standard deviation. The default is 0.
    gaussKernel : int
        The size of the gaussian kernel to be applied to the data. The default is 0, which means no smoothing.

    Returns
    -------
    preprocessedDataDFDict : dict
        A dictionary containing the preprocessed dataframes, with the layer name as the key.
    """
    import pandas as pd
    import numpy as np
    from scipy import ndimage

    # create a blank dictionary to hold the preprocessed dataframes
    preprocessedDataDFDict = {}
    # iterate through the layers and preprocess them
    for layerName,rawDataDF in rawDataDFDict.items():
        # apply the threshold
        rawDataDF[rawDataDF<theshFloor]=np.nan
        # apply the gaussian kernel
        if gaussKernel>0:
            rawDataDF = ndimage.gaussian_filter(rawDataDF, gaussKernel)
        # add the preprocessed dataframe to the dictionary
        preprocessedDataDFDict[layerName] = rawDataDF
    return preprocessedDataDFDict

def multiSheetDictFromExcelCSV(pathToExcelCSV):
    """
    This function divides up a multi sheet csv file, presumably derived from Excell.
    It is assumed that the sheets are divided by rows containing the sheet name in the first column, followed by a series of nan values.
    This, at least, seems like how it has been done thus far.

    Parameters
    ----------
    pathToExcelCSV : str
        The path to the csv file to be loaded.
    
    Returns
    -------
    sheetsDictionary : dict
        A dictionary containing the dataframes for each sheet, with the sheet name as the key.
    """
    import pandas as pd
    import numpy as np
    # load it with pandas, but remember it's comming from an excel file with multiple sheets even though it's a csv
    rawDataDF = pd.read_csv(pathToExcelCSV,header=None)
    # the current csv is essentially several sheets stacked together, wherein the sheets are split by a row that has the name of the sheet in the first column, and the rest of the row values are nan.
    # We can use this to split the data into a list of dataframes, each dataframe being a sheet
    # First we find the rows that have the sheet names and get a boolean mask for this
    sheetNameRowMask=[np.char.isnumeric(iContent.replace('.','')) for iContent in rawDataDF.iloc[:,0].values]
    # i think this returns a list of arrays with single values, so we need to flatten it AND ALSO NEGATE IT
    sheetNameRowMask=np.logical_not(np.array(sheetNameRowMask).flatten())
    # now we can use this mask to split the data into a list of dataframes
    # let's store this as a dictionary with the sheet name as the key and the dataframe as the value
    # first create a blank dictionary
    sheetsDictionary={}
    # find the indices of the sheet name rows from the mask
    sheetNameRowIndices=np.where(sheetNameRowMask)[0]
    # append the last row index to the end of the list
    sheetNameRowIndices=np.append(sheetNameRowIndices,rawDataDF.shape[0])
    # loop through the indices and split the data into dataframes, but remember that the last index is not inclusive
    for iIndex in range(len(sheetNameRowIndices)-1):
        # get the sheet name
        sheetName=rawDataDF.iloc[sheetNameRowIndices[iIndex],0]
        # get the dataframe
        sheetDF=rawDataDF.iloc[sheetNameRowIndices[iIndex]+1:sheetNameRowIndices[iIndex+1],:]
        # retype the dataframe content to float
        sheetDF=sheetDF.astype(float)
        # add the dataframe to the dictionary
        sheetsDictionary[sheetName]=sheetDF
    # return the dictionary
    return sheetsDictionary

def circleMaskAtLocation(refDims, proportion, centroid):
    """
    This function creates a circular mask of a given proportion at a given location within a given image size.

    Parameters
    ----------
    refDims : list of int
        The dimensions of the reference image, in the form [xDim,yDim].  If a single value is passed, it is assumed to be a square.
    proportion : float
        The proportion of the image to be masked.  Must be between 0 and 1.  Judged from the maximum dimension of the image.
    centroid : list of int
        The centroid of the mask, in the form [x,y].

    Returns
    -------
    mask : numpy array
        A numpy array of the same dimensions specified by refDims, True in a circle of the specified proportion, False elsewhere.   
    """


    import numpy as np
    # check if refDims is a list or a single value
    # if it's two values, we'll assume these are the x and y dimension sizes
    # if it's a single value, we'll assume it's a square
    # NOTE: the x and y convention is not necessarily consistent with the origional input (i.e. the input files) or how things have been done previously
    if isinstance(refDims, list):
        xDim = refDims[0]
        yDim = refDims[1]
    else:
        xDim = refDims
        yDim = refDims
    # now implement a check to ensure that the centroid is within the bounds of the image
    if centroid[0] < 0 or centroid[0] > xDim or centroid[1] < 0 or centroid[1] > yDim:
        raise ValueError('Centroid value: {} is not within the bounds of the image dimensions: {}'.format(centroid, [xDim, yDim]))
    # now create a meshgrid of x and y values
    x, y = np.meshgrid(np.arange(xDim), np.arange(yDim))
    # now compute the distance from the centroid for each point
    distFromCentroid = np.sqrt((x - centroid[0])**2 + (y - centroid[1])**2)
    # now create a mask based on the proportion of the largest dimension
    mask = distFromCentroid < proportion * max(xDim, yDim)
    return mask


#def ringMeansFromSquareFormArray(squareFormArray, centroid, visFieldRadiusLimit,shape='rings'):    
    """
    This function iteratively computes the mean of concentric circles or rings, centered at the centroid index.
    for each of these rings or circle, the mean constitutes the mean of all pixels within the bounds of either a circle
    (if shape='circle') centered at the centroid, iteratively progressing across N divisions, where N is the number
    entered for visFieldRadiusLimit.  If shape='rings', then the mean is computed for the area of N bullseye shaped rings,
    where N is the number entered for visFieldRadiusLimit.  The mean is computed for each of these rings, and the results
    are returned as a list of N means, where N is the number entered for visFieldRadiusLimit.

    NOTE: this function will throw warnings and return NaN values if the centroid is too close to the edge of the image.
    This proximity is arbitrarily decided to be if there is an asymetry of greater than 50 percent between
    the distance from the centroid to the actual edge of the relevant radius measure.  This is to prevent
    the mean from being biased by representing a substantially smaller portion of one side (top vs bottom; left vs right)
    of the visual field.

    Inputs:
        - squareFormArray: a 2D numpy array of values, where the dimensions are equal (i.e. square)
        - centroid: a tuple of the x and y coordinates of the centroid of the visual field
        - visFieldRadiusLimit: the maximum radius of the visual field, in degrees.  The array will be divided up in to this many subsections.
        - shape: either 'rings' or 'circle', indicating whether the mean should be computed for concentric rings or circles.

    Outputs:
        - ringMeans: a list of N means, where N is the number entered for visFieldRadiusLimit.
    """



def stretchArrayToSquareForm(arrayToStretch):
    """
    This function takes in a 2D numpy array and stretches it to be square.  It does this by finding the largest dimension
    of the array, and then stretching the smaller dimension to match the larger dimension.  The array is stretched by
    repeating the values of the smaller dimension, such that the final array is square.

    Inputs:
        - arrayToStretch: a 2D numpy array of values, where the dimensions are not equal (i.e. not square)

    Outputs:
        - squareFormArray: a 2D numpy array of values, where the dimensions are equal (i.e. square)
    """
    import numpy as np
    from scipy import ndimage 

    # Extract array size of data
    currentDataSize = arrayToStretch.shape

    # get the largest dimension
    largestDimSize = np.max(currentDataSize)
    # Implement image resize here
    # NOTE: initially, without order=0 this would output an entirely blank array with all values as false.  
    # it was expected that mode='nearest' would be necessary to ensure that the centroid was appropriately stretched without being 
    # smoothed / interpolated into a false value.  I'm not entirely sure what the default order value of 3 entails, 
    # but Copilot recommended order=0 and that seems to work.  Praise be to Copilot.
    imageSquareForm = ndimage.zoom(arrayToStretch, (largestDimSize / currentDataSize[0], largestDimSize / currentDataSize[1]),mode='nearest', order=0)

    return imageSquareForm

def quickTest_plotArray(arrayToPlot):
    """
    The following is just a quick testing function which plots a heatmap
    of the array passed to it.  This is useful for quickly checking the
    content of an array, to ensure that it is what you expect it to be.
    
    Inputs:
        - arrayToPlot: a 2D numpy array of values
            
    """
    import matplotlib.pyplot as plt
    import numpy as np
    import seaborn as sns
    sns.set()
    plt.imshow(arrayToPlot)
    plt.show()


def ringMeansForOCTlayer(OCTLayerData, centroid, visFieldRadiusLimit, shape='rings'):
    """
    This function computes the mean of concentric circles or rings, cntered at the centroid index.
    It does not assume the input OCTLayerData is square, and will stretch the array to be square
    before computing the means.  This is to ensure that the mean is computed for the same area,
    as the stretching will repeat values in the smaller dimension to match the larger dimension.
    but this does not cause any particular pixel to be counted a disporpotionate number of times.

    for each of these rings or circle, the mean constitutes the mean of all pixels within the bounds of either a circle
    (if shape='circle') centered at the centroid, iteratively progressing across N divisions, where N is the number
    entered for visFieldRadiusLimit.  If shape='rings', then the mean is computed for the area of N bullseye shaped rings,
    where N is the number entered for visFieldRadiusLimit.  The mean is computed for each of these rings, and the results
    are returned as a list of N means, where N is the number entered for visFieldRadiusLimit.

    NOTE: this function will throw warnings and return NaN values if the centroid is too close to the edge of the image.
    This proximity is arbitrarily decided to be if there is an asymetry of greater than 50 percent between
    the distance from the centroid to the actual edge of the relevant radius measure.  This is to prevent
    the mean from being biased by representing a substantially smaller portion of one side (top vs bottom; left vs right)
    of the visual field.

    Inputs:
        - OCTLayerData: a 2D numpy array of values, where the dimensions are not equal (i.e. not square)
        - centroid: a tuple of the x and y coordinates of the centroid of the visual field
        NOTE: WE'RE DEFINING X AND Y IN THE CONVENTIONAL MANNER, WHERE X IS THE HORIZONTAL AXIS AND Y IS THE VERTICAL AXIS
        THIS IS AS OPPOSED TO HOW "SOME DATA INPUTS" IMPLEMENT THIS CONVENTION, AND SO THE SWITCH,
        IF NECESSARY MUST BE DONE OUTSIDE OF THIS FUNCTION.
        - visFieldRadiusLimit: the maximum radius of the visual field, in degrees.  The array will be divided up in to this many subsections.
        - shape: either 'rings' or 'circle', indicating whether the mean should be computed for concentric rings or circles.

    Outputs:
        - ringMeans: a list of N means, where N is the number entered for visFieldRadiusLimit.
    """
    import numpy as np
    import pandas as pd
    
    # first we need to create a mask with a single true value at the centroid
    # this will be used to find the new centroid after the array is stretched
    centerTrue = np.zeros(OCTLayerData.shape, dtype=bool)
    centerTrue[centroid[0], centroid[1]] = True

    # square form array for both the mask and the data
    squareFormDataArray = stretchArrayToSquareForm(OCTLayerData)
    squareFormMaskArray = stretchArrayToSquareForm(centerTrue)

    # get the largest dimension span, should be the same because we stretched it to be square
    largestDimSize = np.max(squareFormDataArray.shape)

    # find the new centroid, do this by simply averaging the x and y coordinates of the true values
    # in the squareFormMaskArray
    newCentroid = np.mean(np.where(squareFormMaskArray), axis=1)
    # reassign the centroid to the new centroid, but make sure it is rounded to an integer
    squareFormCentroid = (int(np.round(newCentroid[0])), int(np.round(newCentroid[1])))
    # also reset the mask to have a single true value at the new centroid
    # actually this may not be necessary
    #squareFormMaskArray = np.zeros(squareFormMaskArray.shape, dtype=bool)
    squareFormMaskArray[squareFormCentroid[0], squareFormCentroid[1]] = True

    # create a vector containing the proportion of the visual field radius that each ring represents
    fieldProportions=np.linspace(0,1,visFieldRadiusLimit+1)

    # create a blank pandas dataframe to store the results.
    # NOTE: we'll actually be storing the per-ring quadrant means in this dataframe, so it will have 4 columns
    # and N rows, where N is the number of rings.
    ringMeansDF = pd.DataFrame(columns=['quadrant1', 'quadrant2', 'quadrant3', 'quadrant4'])
    # also create a structure for the standard deviations
    ringStdsDF = pd.DataFrame(columns=['quadrant1', 'quadrant2', 'quadrant3', 'quadrant4']) 

    # start iterating through the rings
    for iAngles in range(1, visFieldRadiusLimit + 1):
        # get the mask for the current circle
        currentMask = circleMaskAtLocation(largestDimSize, fieldProportions[iAngles], squareFormCentroid)
        # create a whole-array quadrant mask, centered at the centroid, with 1s in quadrant 1, 2s in quadrant 2, etc.
        quadrantMask=np.zeros(squareFormDataArray.shape)
        # this is a bad way to do this, but copilot has not been entirely helpful
        # get all of the indicies of coordinates that are above the centroid
        aboveYIndeces=np.arange(squareFormCentroid[1],largestDimSize)
        # get all of the indicies of coordinates that are below the centroid
        belowYIndeces=np.arange(0,squareFormCentroid[1])
        # get all of the indicies of coordinates that are to the right of the centroid
        rightXIndeces=np.arange(squareFormCentroid[0],largestDimSize)
        # get all of the indicies of coordinates that are to the left of the centroid
        leftXIndeces=np.arange(0,squareFormCentroid[0])
        # using the preceding indeces, set all values above and to the right of the centroid to 1
        # this entails getting the cartesian product of the aboveYIndeces and rightXIndeces
        quadrantMask[np.ix_(aboveYIndeces,rightXIndeces)]=1
        # set all values below and to the right of the centroid to 2
        quadrantMask[np.ix_(belowYIndeces,rightXIndeces)]=2
        # set all values below and to the left of the centroid to 3
        quadrantMask[np.ix_(belowYIndeces,leftXIndeces)]=3
        # set all values above and to the left of the centroid to 4
        quadrantMask[np.ix_(aboveYIndeces,leftXIndeces)]=4

        # to get quadrant-specific masks of the current circle, we need to logical_and the current circle mask
        # along with the relevant values of the quadrant mask
        quadrant1Mask = np.logical_and(currentMask, quadrantMask == 1)
        quadrant2Mask = np.logical_and(currentMask, quadrantMask == 2)
        quadrant3Mask = np.logical_and(currentMask, quadrantMask == 3)
        quadrant4Mask = np.logical_and(currentMask, quadrantMask == 4)
        
        # NOTE: the naming convention applied above is such that quadrant1Mask the "upper right" quadrant is quadrant 1 in that the associated values are above and to the right of the centroid.
        # correspondingly quadrant2Mask is the "upper left" quadrant, quadrant3Mask is the "lower left" quadrant, and quadrant4Mask is the "lower right" quadrant.  This is in accordance
        # with the standards of the cartesian coordinate system.
        # whether this is rings or circles, we don't need to do anythign for the first iteration
        if not iAngles == 1:
            if shape=='rings':
                # if this is not the first iteration AND the shape is rings, we need to mask out the previous circle
                # get the mask for the previous circle
                previousMask = circleMaskAtLocation(largestDimSize, fieldProportions[iAngles - 1], squareFormCentroid)
                # mask out the previous circle
                quadrant1Mask = np.logical_and(quadrant1Mask, np.logical_not(previousMask))
                quadrant2Mask = np.logical_and(quadrant2Mask, np.logical_not(previousMask))
                quadrant3Mask = np.logical_and(quadrant3Mask, np.logical_not(previousMask))
                quadrant4Mask = np.logical_and(quadrant4Mask, np.logical_not(previousMask))
                # Now check if any of these quadrants are 50% smaller than the others; also print the pixel counts to the console
                # this is to prevent the mean from being biased by representing a substantially smaller portion of one side (top vs bottom; left vs right)
                # of the visual field.
                # get the pixel counts for each quadrant
        quadrant1PixelCount = np.sum(quadrant1Mask)
        quadrant2PixelCount = np.sum(quadrant2Mask)
        quadrant3PixelCount = np.sum(quadrant3Mask)
        quadrant4PixelCount = np.sum(quadrant4Mask)
        print('Pixel counts for quadrants 1, 2, 3, 4: ' + str(quadrant1PixelCount) + ', ' + str(quadrant2PixelCount) + ', ' + str(quadrant3PixelCount) + ', ' + str(quadrant4PixelCount))
        # check if any of the quadrants are 50% smaller than the others.  Do this by summing the pixel count and computing the proportions
        quadrantProportions=np.array([quadrant1PixelCount, quadrant2PixelCount, quadrant3PixelCount, quadrant4PixelCount]) / np.sum([quadrant1PixelCount, quadrant2PixelCount, quadrant3PixelCount, quadrant4PixelCount])
        # check if the smallest quadrant is less than 50% of the largest quadrant
        if np.min(quadrantProportions) < 0.5 * np.max(quadrantProportions):
            # if so, print a warning to the console
            print('WARNING: One of the quadrants for ring' + str() + 'is 50 percent smaller than one of the other quadrants.  This may bias the mean.')
            # print the centroid coordinate, the dimensions of the associated array, and the distances from the centroid to the edges of the array
            print('Centroid: ' + str(squareFormCentroid))
            print('Reference array dimensions: ' + str(squareFormDataArray.shape))
            print('Distances from centroid to edges of array: ' + str([squareFormCentroid[0], squareFormDataArray.shape[0] - squareFormCentroid[0], squareFormCentroid[1], squareFormDataArray.shape[1] - squareFormCentroid[1]]))
            print('Placing nan in the means for the current ring (ring ' + str(iAngles) + ')')
            # and place a nan in the ring means
            ringMeansDF.loc[iAngles] = [np.nan, np.nan, np.nan, np.nan]
            # do the same for the standard deviations
            ringStdsDF.loc[iAngles] = [np.nan, np.nan, np.nan, np.nan]
        else:
            # if not move on and compute the quadrant means, these should be nan mean because the thresholding operation may have masked out sub-threshold values with nans
            ringMeansDF.loc[iAngles] = [np.nanmean(squareFormDataArray[quadrant1Mask]), np.nanmean(squareFormDataArray[quadrant2Mask]), np.nanmean(squareFormDataArray[quadrant3Mask]), np.nanmean(squareFormDataArray[quadrant4Mask])]
            # also compute the standard deviations
            ringStdsDF.loc[iAngles] = [np.nanstd(squareFormDataArray[quadrant1Mask]), np.nanstd(squareFormDataArray[quadrant2Mask]), np.nanstd(squareFormDataArray[quadrant3Mask]), np.nanstd(squareFormDataArray[quadrant4Mask])]
    # return the ring means and standard deviations      
    return ringMeansDF, ringStdsDF

