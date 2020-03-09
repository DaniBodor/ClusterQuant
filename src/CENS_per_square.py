# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 14:13:59 2020

@author: dani
"""


filename = 'Log_2003091541.txt'

import pandas as pd
import itertools
import sys
import os
from datetime import datetime
import matplotlib.pyplot as plt
from random import seed as rseed
from pathlib import Path

starttime = datetime.now()
rseed(22)
datapath = os.path.abspath(os.path.join(os.getcwd(), os.pardir, 'results', 'output', filename))


with open (datapath, "r") as myfile:
#    data = myfile.readlines()
    lines = [x for x in myfile.readlines() if not x.startswith('#')]
df=pd.DataFrame(columns=['Cond','Cell','CENs','MT_I'])

#%% READ AND ORDER DATA
data_reform = ['']*197
Cond,Cell = '',''
for i,x in enumerate(lines):
    if x.startswith('***'):
        Cond = x[3:]
    elif x.startswith('**'):
        Cell = x[2:]
        CENs = [int(s)   for s in lines[i+1].split(', ')]
        MT_I = [float(s) for s in lines[i+2].split(', ')]
        
        indata = {'CENs': CENs,
                  'MT_I': MT_I,
                  'Cond': [Cond]*len(CENs),
                  'Cell': [Cell]*len(CENs)}
        
        newdf = pd.DataFrame.from_dict(indata)
        df = df.append(newdf)
df=df [['Cond','Cell','CENs','MT_I']]


#%% IMPORT DATA



