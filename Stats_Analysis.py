# -*- coding: utf-8 -*-
"""
Created on Fri Jul 16 13:31:27 2021

@author: dani
"""

import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib
from scipy.spatial.distance import euclidean

file = r'./Stats/Log.txt'

cols = ['Slice','X','Y','Distances','Mean_Dist','Stdev_Dist']
df = pd.read_csv(file, delim_whitespace=True)


#s_names = ['_','Spread','MultiCluster','MegaCluster']


#df['Distances'], df['Mean_Dist'], df['Stdev_Dist'] = '','',''

#def distance(i,j):
#    dx = i[0] - j[0]
#    dy = i[1] - j[1]
#    D = np.sqrt(dx*dx + dy*dy)
#    
#    return D

d_arrays, means, stdevs = [],[],[]
CoVs = []

for i, row in df.iterrows():
    a = (row[1], row[2])
    others = [ (x[1],x[2]) for n, x in df.iterrows() if (n != i and x[0] == row[0]) ]
    distances = [ euclidean (a,b) for b in others ]
    d_arrays.append(distances)
    
    means.append(np.mean(distances))
    stdevs.append(np.std(distances))
    CoVs.append(np.std(distances)/ np.mean(distances))
    
    

df['Distances'] = d_arrays
df['Mean_Dist'] = means
df['Stdev_Dist'] = stdevs
df['Coeff_Var'] = CoVs
df['SliceName'] = ['Spread']*27 +  ['MultiCluster']*27 + ['MegaCluster']*27

use_cols = df.columns[4:]
groups = df.groupby('SliceName')[use_cols]


