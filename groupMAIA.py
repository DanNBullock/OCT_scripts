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

currentCSVPath='/Users/plab/Downloads/exampleMAIA/combined_data.txt'
inputDir='/Users/plab/Downloads/exampleMAIA/'

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
    #arbitrarily make a vector for subject names
    subjList= ['subj_'+str(f) for f in range(len(onlyfiles))]
    #create a structure to hold all of the dataframes
    allFrames=[loadAndConvertMAIA_polar(inputDir+f) for f in onlyfiles]
    #merge into single frame, use subjList as keys
    concatInput= {subjList[i]: allFrames[i] for i in range(len(subjList))} 
    mergedFrame=pd.concat(concatInput)
    return mergedFrame

distanceKernel=2
currentCoord=[0,0]
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



sns.lineplot(data=mergedFrame, x='distance', y='value')

import numpy as np
import matplotlib.pyplot as plt
 
# Using linspace so that the endpoint of 360 is included

# Using linspace so that the endpoint of 360 is included
vFieldRange = np.radians(np.linspace(0, 360, 40))
eccentricityRange = np.arange(0, 10, 1)

xCoords=np.outer(np.atleast_2d(eccentricityRange),np.atleast_2d(np.cos(vFieldRange)).T)
yCoords=np.outer(np.atleast_2d(eccentricityRange),np.atleast_2d(np.sin(vFieldRange)).T)
sourceShape=xCoords.shape

allMeans=np.zeros(len(np.ravel(xCoords)))
allSDs=np.zeros(len(np.ravel(xCoords)))
for iPlotCoords in range(len(np.ravel(xCoords))):
    currentCoordAverage,currentCoordSD=coordKernelMeanSD([np.ravel(xCoords)[iPlotCoords],np.ravel(yCoords)[iPlotCoords]],mergedFrame,distanceKernel)
    allMeans[iPlotCoords]=currentCoordAverage
    allSDs[iPlotCoords]=currentCoordSD
    
reshapeMeans=np.reshape(allMeans,sourceShape)
reshapeSDs=np.reshape(allSDs,sourceShape)


#r, theta = np.meshgrid(vFieldRange, eccentricityRange)
#values = np.random.random((actual.size, expected.size))
 

 
fig, ax = plt.subplots(subplot_kw=dict(projection='polar'))
#ax.set_rticks([0.5, 1, 1.5, 2]) 
polarFig=ax.contourf(vFieldRange, eccentricityRange, reshapeMeans, levels=np.linspace(np.min(mergedFrame.value.to_numpy()),np.max(mergedFrame.value.to_numpy()),100))
plt.colorbar(polarFig)
plt.show()


whatisthis=np.random.random((40,80))

compte regular meshgrid but then weight value by distance from current location.  threshold probable, and decay function