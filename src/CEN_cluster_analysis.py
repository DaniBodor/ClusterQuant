# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 14:13:59 2020

@author: dani
"""



tiny = 'Log_200310_1543.txt'
small = 'Log_2003101536.txt'
large = 'Log_2003091541.txt'


filename = large
MaxLength = 35


import pandas as pd
import itertools
import sys
import os
from datetime import datetime
import matplotlib.pyplot as plt
from random import seed as rseed
from pathlib import Path
import seaborn as sns
import numpy as np

starttime = datetime.now()
rseed(22)

base_dir = os.path.abspath(os.path.join(os.getcwd(), os.pardir))
datapath = os.path.abspath(os.path.join(base_dir, 'results', 'output', filename))
outputdir = os.path.abspath(os.path.join(base_dir, 'results', 'figures'))


read_and_order = 1
cen_histograms = 1
make_vplots = 1


#%% FUNCTIONS
def make_histdf(df, ex_zeroes=True):
    '''
    This function will create a frequency distribution dataframe used for histograms
    df: dataframe; input data
    MaxLen: int or False; max character length of condition (so legend doesn't overflow graph). set to 0/False to ignore
    ex_zeroes: boolean; exclude zero values from frequency distribution
    '''
    if ex_zeroes:
        df = df[df.CENs != 0]
    
    df = (df.groupby(['Condition'])['CENs']
                     .value_counts(normalize=True)
                     .rename('frequency')
                     .reset_index()
                     .sort_values('CENs'))
    
    if MaxLength:
        df = shorten_column_name(df,'Condition',MaxLength)
    
    return df



def shorten_column_name(df,column,L):
    long_cond_names = list(df.Condition.unique())
    short_cond_names = [x[:L-3]+'...' if len(x)>L  else x for x in long_cond_names]
    df = df.replace(long_cond_names,short_cond_names)
    
    return df

#%% READ AND ORDER DATA

if read_and_order:
    
    with open (datapath, "r") as myfile:
        lines = [x for x in myfile.readlines() if not x.startswith('#')]
    full_df=pd.DataFrame(columns=['Condition','Cell','CENs','tubI'])

    Condition,Cell = '',''
    for i,l in enumerate(lines):
        if l.startswith('***'):
            Condition = l[3:-1]
        elif l.startswith('**'):
            Cell = l[2:-1]
            CENs = [int(s)   for s in lines[i+1].split(', ')]
            tubI = [float(s)   for s in lines[i+2].split(', ')]
            
            indata = {'CENs': CENs,
                      'tubI': tubI,
                      'Condition': [Condition]*len(CENs),
                      'Cell': [Cell]*len(CENs)}
            
            celldf = pd.DataFrame.from_dict(indata)         # create dataframe from cell
            full_df = full_df.append(celldf)                # add cell to dataframe
    full_df=full_df [['Condition','Cell','CENs','tubI']]    # reorder columns




#%% MAKE CEN HISTOGRAM

if cen_histograms:

    histogram_df = make_histdf(full_df)    
    
    sns.barplot(x="CENs", y="frequency", hue="Condition", data=histogram_df)
    
    # plot formatting
    plt.legend(prop={'size': 12})
    plt.title('Centromeres per square')
    plt.xlabel('Centromeres')
    plt.ylabel('Frequency')
    plt.grid(axis='y')
    
    figurepath = os.path.abspath(os.path.join(outputdir, filename[:-4]+'__hist.png'))
    plt.savefig(figurepath,dpi=1200)
#    plt.show()
    plt.clf()


#%% MAKE INDIVIDUAL VIOLINPLOTS
    
if make_vplots:
    
    for currcond in full_df.Condition.unique():
        cond_df = full_df[full_df.Condition == currcond]
        
        
        if MaxLength:
            condname = currcond[:MaxLength-3]+'...'
        else:
            condname = currcond
            
        for currcell in cond_df.Cell.unique():
            violin_df = cond_df[cond_df.Cell == currcell]
            sns.violinplot(x ='CENs', y='tubI', data=violin_df)
            
            # plot formatting
            plt.title(condname + '\n' + currcell)
            plt.xlabel('Centromeres')
            plt.ylabel('Tubulin intensity')
            plt.xlim(right = full_df.CENs.max()+.5 )
            plt.grid(axis='y')
            

            violin_name = condname + "_" + currcell
            figurepath = os.path.abspath(os.path.join(outputdir, violin_name  +'_violin.png'))
    
            plt.savefig(figurepath,dpi=1200)
#            plt.show()
            plt.clf()
#            crash