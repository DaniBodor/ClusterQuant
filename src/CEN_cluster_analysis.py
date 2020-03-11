# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 14:13:59 2020

@author: dani
"""



tiny = 'Log_200310_1543.txt'
small = 'Log_2003091541.txt'
large = 'Log_2003101536.txt'


filename = small

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
datapath = os.path.abspath(os.path.join(os.getcwd(), os.pardir, 'results', 'output', filename))





read_and_order = 1
cen_histograms = 1


#%% FUNCTIONS
def make_histdf(df, MaxLen=35, ex_zeroes=True):
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
    df.CENs = df.CENs.astype('int')
    
    if MaxLen:
        long_cond_names = list(df.Condition.unique())
        short_cond_names = [x[:MaxLen-3]+'...' if len(x)>MaxLen  else x for x in long_cond_names]
        df = df.replace(long_cond_names,short_cond_names)
    
    return df


#%% READ AND ORDER DATA

if read_and_order:
    
    with open (datapath, "r") as myfile:
        lines = [x for x in myfile.readlines() if not x.startswith('#')]
    full_df=pd.DataFrame(columns=['Condition','Cell','CENs','MT_I'])

    Condition,Cell = '',''
    for i,l in enumerate(lines):
        if l.startswith('***'):
            Condition = l[3:-1]
#            if len(Condition) > 40:
#                Condition = Condition[:35]+'...'
        elif l.startswith('**'):
            Cell = l[2:-1]
            CENs = [float(s)   for s in lines[i+1].split(', ')]
            MT_I = [float(s) for s in lines[i+2].split(', ')]
            
            indata = {'CENs': CENs,
                      'MT_I': MT_I,
                      'Condition': [Condition]*len(CENs),
                      'Cell': [Cell]*len(CENs)}
            
            newdf = pd.DataFrame.from_dict(indata)
            full_df = full_df.append(newdf)
    full_df=full_df [['Condition','Cell','CENs','MT_I']]




#%% OUTPUT CEN HISTOGRAM

if cen_histograms:


#    Condition_gr = full_df.groupby(['Condition'])
    
    
#    sns.countplot(data=full_df, x='CENs', hue = 'Condition')
#    plt.show()

#    if histogram_exclude_zero:
#        histogram_df = 
#        
#    else:
    

    histogram_df = make_histdf(full_df)
    sns.barplot(x="CENs", y="frequency", hue="Condition", data=histogram_df)

    plt.legend(prop={'size': 12})
    plt.title('Centromeres per square')
    plt.xlabel('Centromeres')
    plt.ylabel('Frequency')
    
    plt.show()


