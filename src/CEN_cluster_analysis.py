# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 14:13:59 2020

@author: dani
"""



tiny = 'Log_200310_1543.txt'
small = 'Log_2003091541.txt'
large = 'Log_2003101536.txt'


histogram_exclude_zero = 1


startchar_foldername_to_Conditionitionname = 12
endchar_foldername_to_Conditionitionname = 18

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





read_and_order = 0
cen_histograms = 1






#%% READ AND ORDER DATA

if read_and_order:
    
    with open (datapath, "r") as myfile:
        lines = [x for x in myfile.readlines() if not x.startswith('#')]
    df=pd.DataFrame(columns=['Condition','Cell','CENs','MT_I'])

    Condition,Cell = '',''
    for i,l in enumerate(lines):
        if l.startswith('***'):
            Condition = l[startchar_foldername_to_Conditionitionname+3:endchar_foldername_to_Conditionitionname+4]
        elif l.startswith('**'):
            Cell = l[2:-1]
            CENs = [float(s)   for s in lines[i+1].split(', ')]
            MT_I = [float(s) for s in lines[i+2].split(', ')]
            
            indata = {'CENs': CENs,
                      'MT_I': MT_I,
                      'Condition': [Condition]*len(CENs),
                      'Cell': [Cell]*len(CENs)}
            
            newdf = pd.DataFrame.from_dict(indata)
            df = df.append(newdf)
    df=df [['Condition','Cell','CENs','MT_I']]




#%% OUTPUT CEN HISTOGRAM

if cen_histograms:


    Condition_gr = df.groupby(['Condition'])
    
    
#    sns.countplot(data=df, x='CENs', hue = 'Condition')
#    plt.show()

#    if histogram_exclude_zero:
#        histogram_df = 
#        
#    else:
    
    histogram_df = (df.groupby(['Condition'])['CENs']
                     .value_counts(normalize=True)
                     .rename('frequency')
                     .reset_index()
                     .sort_values('CENs'))
    sns.barplot(x="CENs", y="frequency", hue="Condition", data=histogram_df)

    plt.legend(prop={'size': 12})
    plt.title('Centromeres per square')
    plt.xlabel('Centromeres')
    plt.ylabel('Frequency')
    
    plt.show()


