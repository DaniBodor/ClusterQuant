# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 14:13:59 2020

@author: dani
"""



#%% test above



MaxLength_CondName = 35

import tkinter as tk
from tkinter import filedialog as fd
import numpy as np
import pandas as pd
#import itertools
import os
from datetime import datetime
import matplotlib.pyplot as plt
from random import seed as rseed
import seaborn as sns
from pathlib import Path

top = tk.Tk()
#checkbox1 = tk.IntVar()
#c1 = tk.Checkbutton(top, text="test 1", height=5, width = 20, 
#                    onvalue = 1, offvalue = 0, variable = checkbox1)
#c1.pack()
#top.mainloop()
#top.focus_force()
top.withdraw()

print('find file open window!')

csvPath = os.path.abspath( fd.askopenfilename() )
csvFile = os.path.basename(csvPath)


#csvFile = os.path.abspath(r'C:/Users/dani/Documents/MyCodes/ClusterQuant/data/test_data/_Results/Log_210607_1703.csv')
data_dir = os.path.abspath(os.path.join(csvPath, os.pardir))
figureDir = os.path.join(data_dir, 'figures')

if not os.path.exists(figureDir):
    os.mkdir(figureDir)

starttime = datetime.now()
rseed(22)



# move below into dialog window once I figure out how
readData  = True
makeHisto  = True
makeVplots     = True
violinpercell   = True

spotName = 'Spots'
yAxisName = 'Intensity'

#%% FUNCTIONS
def make_histdf(df, ex_zeroes=True):
    '''
    This function will create a frequency distribution dataframe used for histograms
    df: dataframe; input data
    MaxLen: int or False; max character length of condition (so legend doesn't overflow graph). set to 0/False to ignore
    ex_zeroes: boolean; exclude zero values from frequency distribution
    '''
    if ex_zeroes:
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

#%% READ AND ORDER DATA

if readData:
    
    with open (csvPath, "r") as myfile:
        lines = [x for x in myfile.readlines() if not x.startswith('#')]
    full_df = pd.DataFrame(columns = ['Condition', 'Cell', spotName, yAxisName])

    Condition,Cell = '',''
    for i,l in enumerate(lines):
        if l.startswith('***'):
            Condition = l[3:-1]
        elif l.startswith('**'):
            Cell = l[2:-1]
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

    histogram_df = make_histdf(full_df)    
    
    sns.barplot(x=spotName, y="frequency", hue="Condition", data=histogram_df)
    
    # plot formatting
    plt.legend(prop={'size': 12})
    plt.title(spotName + ' per square')
    plt.xlabel(spotName)
    plt.ylabel('Frequency')
    plt.grid(axis='y')
    
    figurePath = os.path.join(data_dir, 'figures', csvFile[:-4]+'_hist.png')
    plt.savefig(figurePath, dpi=600)
#    plt.show()
    plt.clf()


#%% MAKE INDIVIDUAL VIOLINPLOTS
    
if makeVplots:
    # figure output directory
    violinFigDir = os.path.abspath(os.path.join(figureDir,csvFile[:-4]))
    if not os.path.exists(violinFigDir):
        os.mkdir(violinFigDir)
    
    max_spots = full_df[spotName].max() #for formatting

    for currcond in full_df.Condition.unique():
        cond_df = full_df[full_df.Condition == currcond]

        #shorten condition name
        if MaxLength_CondName and len(currcond) > MaxLength_CondName:
            condname = currcond[:MaxLength_CondName-3]+'...'
        else:
            condname = currcond

        # create line of all data per condition
#        sns.violinplot(x =spotName, y=yAxisName, data=cond_df, scale="width", color = 'lightskyblue')
        sns.lineplot  (x =spotName, y=yAxisName, data=cond_df, color = 'r')
        
        plt.title(condname)
        plt.xlabel(spotName)
        plt.ylabel(yAxisName)
        plt.xlim(-0.5, max_spots + 0.5 )
#        plt.ylim(full_df[yAxisName].min(), full_df[yAxisName].max())
        plt.xticks(range(max_spots+1))
        plt.grid()
#        plt.show()
        
        # save violin plot
        figurePath = os.path.join(figureDir,csvFile[:-4]+ '_' + condname  +'_line.png')
        plt.savefig(figurePath,dpi=600)
        plt.clf()

        if violinpercell:
        # create violin of data per cell
            for i,currcell in enumerate(cond_df.Cell.unique()):
                print (i,end=',')
                violin_df = cond_df[cond_df.Cell == currcell]
    
                # add missing x values
                for N in range(max_spots+1):
                    if not N in violin_df[spotName].unique():
                        newrow = {'Cndition':condname, 'Cell':currcell, spotName:N, yAxisName:np.nan}
                        violin_df = violin_df.append(newrow, ignore_index=True)
                
                
                
                # plot & formatting
                sns.violinplot(x =spotName, y=yAxisName, data=violin_df, scale="width", color = 'lightskyblue')
                sns.lineplot  (x =spotName, y=yAxisName, data=violin_df, color = 'r')
                
                plt.title(condname + '\n' + currcell)
                plt.xlabel(spotName)
                plt.ylabel(yAxisName)
                plt.xlim(-0.5, max_spots + 0.5 )
                plt.ylim(full_df[yAxisName].min(), full_df[yAxisName].max())
                plt.grid(axis='y')
                
                # save figure            
                violin_name = condname + "_" + currcell
                figurePath = os.path.join(violinFigDir, violin_name  + '_violin.png')
                plt.savefig(figurePath, dpi=600)
    #            plt.show()
                plt.clf()
