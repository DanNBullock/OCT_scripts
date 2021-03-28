#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Feb 23 15:08:25 2021

@author: dan
"""

import pandas as pd
import numpy as np
import seaborn as sns
import os
from os import listdir
from os.path import isfile, join
import scipy

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

#currentCSVPath='/Users/plab/Downloads/exampleMAIA/004.txt'
#inputDir='/Users/plab/Downloads/exampleMAIA/'

#load a csv and convert the data to radius & value
def loadAndConvertMAIA(currentCSVPath):
    #actually appears to be tab separated
    currentTable=pd.read_csv(currentCSVPath, sep='\t')
    #simple trig to get radial hypotenuse
    hypotVec=np.sqrt(np.square(currentTable.x_deg)+np.square(currentTable.y_deg))
    #create an output frame
    outFrame=pd.DataFrame(data=np.asarray([currentTable.x_deg,currentTable.y_deg,hypotVec,currentTable.Threshold]).T,columns=['x_deg','y_deg','distance', 'value'])
    return outFrame

def loadAndConvertMAIA_polar(currentCSVPath):
    #actually appears to be tab separated
    currentTable=pd.read_csv(currentCSVPath, sep='\t')
    #simple trig to get radial hypotenuse
    hypotVec=np.sqrt(np.square(currentTable.x_deg)+np.square(currentTable.y_deg))
    #get the radian value
    #REVERSED?
    radianVec=np.arctan2(currentTable.y_deg,currentTable.x_deg)
    #create an output frame
    outFrame=pd.DataFrame(data=np.asarray([currentTable.x_deg,currentTable.y_deg,radianVec,hypotVec,currentTable.Threshold]).T,columns=['x_deg','y_deg','polar','distance', 'value'])
    return outFrame

def multiSubjectDataStruc(inputDir):
    #get the relevant file names
    onlyfiles = [f for f in listdir(inputDir) if isfile(join(inputDir, f))]
    #make robust against the damnable .DS_Store
    onlyfiles.remove('.DS_Store')
    #arbitrarily make a vector for subject names
    subjList= ['subj_'+str(f) for f in range(len(onlyfiles))]
    #create a structure to hold all of the dataframes
    allFrames=[loadAndConvertMAIA_polar(inputDir+f) for f in onlyfiles]
    #merge into single frame, use subjList as keys
    concatInput= {subjList[i]: allFrames[i] for i in range(len(subjList))} 
    mergedFrame=pd.concat(concatInput)
    return mergedFrame


def coordKernelMeanSD(currentCoord,mergedFrame,distanceKernel):
    compareCoords=(np.asarray([mergedFrame.x_deg,mergedFrame.y_deg]).T)
    distances=scipy.spatial.distance.cdist(np.atleast_2d(currentCoord),compareCoords)
    maskCriteriaVec=distances<distanceKernel
    #gaussian, I guess
    weightVec=np.exp(-distances[maskCriteriaVec])
    targetValues=np.atleast_2d(np.asarray(mergedFrame.value))
    #weighted, windowed average
    weightedAverage=np.average(targetValues[maskCriteriaVec], weights=weightVec)
    #weighted, windowed variance
    weightedVariance=np.average((targetValues[maskCriteriaVec]-weightedAverage)**2, weights=weightVec)
    return weightedAverage, np.sqrt(weightedVariance)

def ringMeanDev(convertedMAIAtable):
    #
    floorDists=np.floor(convertedMAIAtable.distance.to_numpy())
    vals=np.floor(convertedMAIAtable.value.to_numpy())
    meanVec=np.zeros(10)
    stdevVec=np.zeros(10)
    for iDegrees in range(10):
        meanVec[iDegrees]=np.mean(vals[floorDists==iDegrees])
        stdevVec[iDegrees]=np.std(vals[floorDists==iDegrees])
    outframe=pd.DataFrame(np.array([meanVec,stdevVec]).T,columns=['mean','stdev'])
    return outframe

def MAIAradarPlot(convertedMAIAtable):
    import numpy as np
    import matplotlib.pyplot as plt
 
    # Using linspace so that the endpoint of 360 is included
    vFieldRange = np.radians(np.linspace(0, 360, 40))
    eccentricityRange = np.arange(0, 10, 1)
    
    #get a regular sampling using .outer
    xCoords=np.outer(np.atleast_2d(eccentricityRange),np.atleast_2d(np.cos(vFieldRange)).T)
    yCoords=np.outer(np.atleast_2d(eccentricityRange),np.atleast_2d(np.sin(vFieldRange)).T)
    #figure out how big the dataframe is
    sourceShape=xCoords.shape
    
    #turn the 2d dataframe target into a 1D vector, storage for means and stdev
    allMeans=np.zeros(len(np.ravel(xCoords)))
    allSDs=np.zeros(len(np.ravel(xCoords)))
    
    #set kernel frame for interpolation.  Values outside of this distance are ignored for interpolation computation
    distanceKernel=2
    #compute value for coordinates
    for iPlotCoords in range(len(np.ravel(xCoords))):
        currentCoordAverage,currentCoordSD=coordKernelMeanSD([np.ravel(xCoords)[iPlotCoords],np.ravel(yCoords)[iPlotCoords]],convertedMAIAtable,distanceKernel)
        allMeans[iPlotCoords]=currentCoordAverage
        allSDs[iPlotCoords]=currentCoordSD
    
    reshapeMeans=np.reshape(allMeans,sourceShape)
    reshapeSDs=np.reshape(allSDs,sourceShape)


    fig, ax = plt.subplots(subplot_kw=dict(projection='polar'))
    #ax.set_rticks([0.5, 1, 1.5, 2]) 
    polarFig=ax.contourf(vFieldRange, eccentricityRange, reshapeMeans, levels=np.linspace(np.min(convertedMAIAtable.value.to_numpy()),np.max(convertedMAIAtable.value.to_numpy()),100))
    plt.colorbar(polarFig)
    #plt.show()
    return fig

def MAIAscatterPlot(convertedMAIAtable):
    import seaborn as sns
    import numpy as np
    import matplotlib.pyplot as plt
    
    fig, axes = plt.subplots(1, 1)

    sns.scatterplot(x="x_deg", y="y_deg", data=convertedMAIAtable, hue="value", cmap="viridis",s=300,ax=axes)

    plt.ylabel('Vertical eccentricity')
    plt.xlabel('Horizontal eccentricity')
    #plt.show()
    return fig

def computeMAIAonDir(inputDir):
    #get the relevant file names
    os.makedirs(os.path.join(inputDir,'output/'), exist_ok=True)
    onlyfiles = [f for f in listdir(inputDir) if isfile(join(inputDir, f))]
    #make robust against the damnable .DS_Store
    onlyfiles.remove('.DS_Store')
    #iterate across files in directory
    for iFiles in range(len(onlyfiles)):
        #generate current file name
        currentFileName=os.path.join(inputDir,onlyfiles[iFiles])
        #create stem for all output files
        outputFileStem=os.path.join(inputDir,'output/',onlyfiles[iFiles].replace('.txt',''))
        #do the polar coordinate table conversion
        convertedMAIAtable=loadAndConvertMAIA_polar(currentFileName)
        #compute the ring means and save to csv
        ringMeanTable=ringMeanDev(convertedMAIAtable)
        ringMeanTable.to_csv(outputFileStem+'_ringMeanTable.csv')
        #do the radar plot and save to file
        radarOut=MAIAradarPlot(convertedMAIAtable)
        radarOut.savefig(outputFileStem+'_radarPlot.png')
        #do the scatter plot and save to file
        scatterOut=MAIAscatterPlot(convertedMAIAtable)
        scatterOut.savefig(outputFileStem+'_scatterPlot.png')
        
    #now do it at the group level   
    allSubjTable=multiSubjectDataStruc(inputDir)
    groupFileStem=os.path.join(inputDir,'output/group')
    #compute the ring means and save to csv
    ringMeanTable=ringMeanDev(allSubjTable)
    ringMeanTable.to_csv(groupFileStem+'_ringMeanTable.csv')
    #do the radar plot and save to file
    radarOut=MAIAradarPlot(allSubjTable)
    radarOut.savefig(groupFileStem+'_radarPlot.png')
    #do the scatter plot and save to file
    scatterOut=MAIAscatterPlot(allSubjTable)
    scatterOut.savefig(groupFileStem+'_scatterPlot.png')
