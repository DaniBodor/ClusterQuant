# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 14:13:59 2020
@author: dani
"""

dataDir = r'C:\Users\dani\Documents\MyCodes\ClusterQuant\data\testData\_ClusterQuant'

#%% test above



import numpy as np # probably can find a way around this
import pandas as pd # VERY essential
import os # possibly can find a way around this
from datetime import datetime # non-essential
import matplotlib.pyplot as plt # essential for outputting figures, not CSVs
import seaborn as sns # essential for outputting figures, not CSVs



csvInputFile = [f for f in os.listdir(dataDir) if '_Python' in f][0]
timestamp = csvInputFile[-14:-4]
expName = os.path.basename(dataDir)
figureDir = os.path.join(dataDir, 'Results_' + timestamp)

starttime = datetime.now()

exclude_zeroes  = False # include or exclude 0s from histogram
readData        = True # reads data from file; set to False to save time when re-analyzing previous
makeHisto       = True # create histogram of spot data
makeLineplot    = True # create a correlation graph between spots and intensities
makeViolinplots = True # make a violinplot for each cell showing intensity by spot count

cleanup = ['R3D', 'D3D', 'PRJ','dv','tif']
MaxLength_CondName = 0

#%% FUNCTIONS
def make_histdf(df):
    '''
    This function will create a frequency distribution dataframe used for histograms
    df: dataframe; input data
    MaxLen: int or False; max character length of condition (so legend doesn't overflow graph). set to 0/False to ignore
    ex_zeroes: boolean; exclude zero values from frequency distribution
    '''
    if exclude_zeroes:
        df = df[df[spotName] != 0]
    
    df = (df.groupby(['Condition'])[spotName]
                     .value_counts(normalize=True)
                     .rename('frequency')
                     .reset_index()
                     .sort_values(spotName))
    
    if MaxLength_CondName:
        df = shorten_column_name(df, 'Condition', MaxLength_CondName)
    
    return df



def shorten_column_name(df,column,L):
    long_cond_names = list(df.Condition.unique())
    short_cond_names = [x[:L-3]+'...' if len(x)>L else x for x in long_cond_names]
    df = df.replace(long_cond_names,short_cond_names)
    
    return df


def name_cleaner(name):
    for x in cleanup:
        name = name.replace(x, '')
    while '__' in name:
        name = name.replace('__', '_')
    name = name.replace('.','')

    while name[-1] == '_':
        name = name[:-1]
    
    return name

#%% READ AND ORDER DATA

if readData:
    
    with open (csvInputPath, "r") as myfile:
        lines = [x for x in myfile.readlines() if not x.startswith('#')]

    Condition,Cell = '',''
    for i,l in enumerate(lines):
        if l.startswith('****'):
            spotName    = l.split(' ')[1]
            yAxisName   = l.split(' ')[2]
            windowSize  = l.split(' ')[3]
            winDisplace = l.split(' ')[4].strip()
            full_df = pd.DataFrame(columns = ['Condition', 'Cell', spotName, yAxisName])
            figureDir = figureDir + f'_size{windowSize}_displ{winDisplace}'
            if not os.path.exists(figureDir):
                os.mkdir(figureDir)

        elif l.startswith('***'):
            Condition = l[3:-1]
        elif l.startswith('**'):
            Cell = name_cleaner(l[2:-1])
            spots = [int(s)   for s in lines[i+1].split(', ')]
            signal = [float(s)   for s in lines[i+2].split(', ')]
            
            indata = {spotName: spots,
                      yAxisName: signal,
                      'Condition': [Condition]*len(spots),
                      'Cell': [Cell]*len(spots)}
            
            celldf = pd.DataFrame.from_dict(indata)         # create dataframe from cell
            full_df = full_df.append(celldf)                # add cell to dataframe
    full_df = full_df [['Condition', 'Cell', spotName, yAxisName]]    # reorder columns




#%% MAKE HISTOGRAM

if makeHisto:

    # make and export histogram
    histogram_df = make_histdf(full_df)    
    
    # generate plot
    sns.barplot(x=spotName, y="frequency", hue="Condition", data=histogram_df)
    
    # plot formatting
    plt.legend(prop={'size': 12})
    plt.title(spotName + ' per square')
    plt.xlabel(spotName)
    plt.ylabel('Frequency')
    plt.grid(axis='y')
    
    
    # save plot and data
    figurePath =         os.path.join(figureDir, 'Histogram.png')
    histogram_df.to_csv( os.path.join(figureDir, 'Histogram.csv') )
    plt.savefig(    figurePath, dpi=600)
#    plt.show()
    plt.clf()


#%% MAKE INDIVIDUAL VIOLINPLOTS
    
if makeLineplot:
    # figure output directory
    violinFigDir = os.path.abspath(os.path.join(figureDir, 'ViolinFigs'))
    if not os.path.exists(violinFigDir):
        os.mkdir(violinFigDir)
    
    max_spots = full_df[spotName].max() #for formatting

    for currcond in full_df.Condition.unique():
        cond_df = full_df[full_df.Condition == currcond]
        condname = currcond
        if MaxLength_CondName and len(condname) > MaxLength_CondName:
            condname = condname[:MaxLength_CondName-3] + '...'
          
        # create line of all data per condition
#        sns.violinplot(x =spotName, y=yAxisName, data=cond_df, scale="width", color = 'lightskyblue')
        sns.lineplot  (x = spotName, y = yAxisName, data = cond_df, color = 'r')
        
        plt.title(condname)
        plt.xlabel(spotName)
        plt.ylabel(yAxisName)
        plt.xlim(-0.5, max_spots + 0.5 )
#        plt.ylim(full_df[yAxisName].min(), full_df[yAxisName].max())
        plt.xticks(range(max_spots+1))
        plt.grid()
#        plt.show()
        
        # save violin plot and data
        cond_df.to_csv( os.path.join(figureDir, condname  + '_Correlation.csv'))
        figurePath =    os.path.join(figureDir, condname  + '_Correlation.png')
        plt.savefig(figurePath, dpi=600)
        plt.clf()

        if makeViolinplots:
        # create violin of data per cell
            for i,currcell in enumerate(cond_df.Cell.unique()):
                print (i,end=',')
                violin_df = cond_df[cond_df.Cell == currcell]
    
                # add missing x values
                for N in range(max_spots+1):
                    if not N in violin_df[spotName].unique():
                        newrow = {'Condition':condname, 'Cell':currcell, spotName:N, yAxisName:np.nan}
                        violin_df = violin_df.append(newrow, ignore_index=True)
                
                
                
                # plot & formatting
                sns.lineplot  (x = spotName, y = yAxisName, data = violin_df, color = 'r')
                sns.violinplot(x = spotName, y = yAxisName, data = violin_df, 
                               scale = "width", color = 'lightskyblue')
                
                plt.title(condname + '\n' + currcell)
                plt.xlabel(spotName)
                plt.ylabel(yAxisName)
                plt.xlim(-0.5, max_spots + 0.5 )
                plt.ylim(full_df[yAxisName].min(), full_df[yAxisName].max())
                plt.grid(axis='y')
                
                # save figure and data
                violin_name = condname + "_" + currcell
                figurePath =        os.path.join(violinFigDir, violin_name  + '_violin.png')
                plt.savefig(figurePath, dpi=600)
    #            plt.show()
                plt.clf()
