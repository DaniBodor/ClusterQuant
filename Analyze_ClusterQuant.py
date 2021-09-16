# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 14:13:59 2020
@author: dani
"""


#%%

import numpy as np
import pandas as pd
import os
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns
import tkinter as tk
from tkinter import filedialog as fd




starttime = datetime.now()

readData        = 0 # reads data from file; set to False to save time when re-analyzing previous
makeHisto       = 0 # create histogram of spot data
makeLineplot    = 0 # create a correlation graph between spots and intensities
makeViolinplots = 0 # make a violinplot for each cell showing intensity by spot count
exportStats     = 0 # output CSVs for further processing
makePrismOutput = True # output data that can easily be copied to Prism

cleanup = ['R3D', 'D3D', 'PRJ','dv','tif']
MaxLength_CondName = 0
histo_bar_vs_line_cutoff = 4
max_histo_bars = 50


# names
Cond = 'Condition'
Image = 'Cell'
Freq = 'Frequency'
Count = 'Count'


#%% MINOR FUNCTIONS
#%%
def make_histdf(df):
    '''
    This function will create a frequency distribution dataframe used for histograms
    df: dataframe; input data
    MaxLen: int or False; max character length of condition (so legend doesn't overflow graph). set to 0/False to ignore
    '''

    # Get Count
    output_df = (df.groupby([Cond])[spotName]
                     .value_counts()
                     .rename(Count)
                     .reset_index() )
    # Get Count and pass to output_df
    df2 = (df.groupby([Cond])[spotName]
                     .value_counts(normalize=True)
                     .rename(Freq)
                     .reset_index() )
    output_df[Freq] = df2[Freq]

    
    if MaxLength_CondName:
        df = shorten_column_name(df, Cond, MaxLength_CondName)
    
    output_df = output_df.sort_values([Cond,spotName])
    output_df.reset_index(drop=True, inplace=True)
    return output_df

#%%
def shorten_column_name(df,column,L):
    long_cond_names = list(df[Cond].unique())
    short_cond_names = [x[:L-3]+'...' if len(x)>L else x for x in long_cond_names]
    df = df.replace(long_cond_names,short_cond_names)
    
    return df

#%%
def name_cleaner(name):
    for x in cleanup:
        name = name.replace(x, '')
    while '__' in name:
        name = name.replace('__', '_')
    name = name.replace('.','')

    while name[-1] == '_':
        name = name[:-1]
    while name[0] == ' ':
        name = name[1:]
    
    return name

#%%
def excl_0(df):
    df = df[df[spotName] != 0]
    return df

#%%
def save_csv(df,name):
    try:
        filename = name + '.csv'
        df.to_csv( os.path.join(outputDir, filename) )
    except PermissionError:
        print(f'could not save {filename}')

#%%
def duplicate_singles(df):
    cheat_df = df.copy()
    for i,x in enumerate( histogram_df[Count] ):
        if x == 1:
            cheat_numb = histogram_df[spotName][i]
            cheat_cond = histogram_df[Cond][i]
            cheat_value = 0.0001 + cheat_df.query(f'{Cond} == "{cheat_cond}" and {spotName} == {cheat_numb}')[yAxisName]
            cheatrow = {Cond:cheat_cond, Image:'fake', spotName:cheat_numb, yAxisName:float(cheat_value)}
            cheat_df = cheat_df.append(cheatrow,ignore_index=True)
    return cheat_df

#%%
    
def getStats(df, group, data):
    if type(group) == str:
        group = [group]
    stats = df.groupby(group)[data].agg(['describe','var','sem']).reset_index()
    stat_columns = ['Count','Mean','StDev','Min','25%-ile','Median','75%-ile','Max','Variance','SEM']
    stats.columns = [*group, *stat_columns]
    low,high = getCI(stats)
    stats['CI95_low'] = low
    stats['CI95_high'] = high
    
    return stats


def getCI(df, ci=95):
    ci_lo, ci_hi = [],[]
    
    for i in df.index:
        m = df.loc[i]['Mean']
        c = df.loc[i]['Count']
        s = df.loc[i]['StDev']
        ci_lo.append(m - 1.95*s/np.sqrt(c))
        ci_hi.append(m + 1.95*s/np.sqrt(c))
    
    return ci_lo, ci_hi


#%% MAIN
#%%

#%% READ AND ORDER DATA
if readData:
    # open file dialog
    print('find file open window (it might be behind other windows) and select the _PythonInput file you want to analyze.')
    top = tk.Tk()
    
    csvInputPath = os.path.abspath( fd.askopenfilename(title = 'Select _PythonInput file for analysis', 
                                                       filetypes = (("CSVs","*.csv"),("All files","*.*")) ))
    top.withdraw()
    csvInputFile = os.path.basename(csvInputPath)
    dataDir = os.path.abspath(os.path.join(csvInputPath, os.pardir))
    
    #dataDir = r'.\data\testData\_LabMeeting'
    #PythonInput_version = -1
    #csvInputFile = [f for f in os.listdir(dataDir) if '_Python' in f][PythonInput_version]
    
    
    expName = os.path.basename(dataDir)
    timestamp = csvInputFile[-14:-4]
    outputDir = os.path.join(dataDir, 'Results_' + timestamp)


    print ('reading input data')  
    with open (os.path.join(dataDir,csvInputFile), "r") as myfile:
        lines = [x.strip(',\n') for x in myfile.readlines() if not x.startswith('#')]

    Folder,File = '',''
    for i,l in enumerate(lines):
        if l.startswith('****'):
            spotName    = l.split(' ')[1]
            yAxisName   = l.split(' ')[2]
            radius  = l.split(' ')[3]
            areaPercent = l.split(' ')[4].strip()
            full_df = pd.DataFrame()
            outputDir = outputDir + f'_radius{radius}_Afract{areaPercent}'
            if not os.path.exists(outputDir):
                os.mkdir(outputDir)

        elif l.startswith('***'):
            Folder = l[3:]
        elif l.startswith('**'):
            File = name_cleaner(l[2:])
            spots =  [float   ( s.strip() ) for s in lines[i+1].split(',')]
            signal = [float ( s.strip() ) for s in lines[i+2].split(',')]
            
            indata = {spotName: spots,
                      yAxisName: signal,
                      Cond:  [Folder]*len(spots),
                      Image: [File]*len(spots)}
            
            file_df = pd.DataFrame.from_dict(indata)         # create dataframe from cell
            full_df = full_df.append(file_df)                # add cell to dataframe
        
    full_df = full_df.replace([np.inf, -np.inf], np.nan).dropna(axis=1)
    full_df[spotName] = full_df[spotName].astype(int)
    full_df = full_df            [[Cond, Image, spotName, yAxisName]]   # reorder columns
    full_df = full_df.sort_values([Cond, Image, spotName, yAxisName])   # sort from left to right
    full_df.reset_index(drop=True, inplace=True)
    save_csv(full_df, 'Raw_data')

#%% MAKE HISTOGRAM

if makeHisto:
    print ('generating histograms')

    # make and export histogram
    histogram_df = make_histdf(full_df)
    save_csv(histogram_df, 'Histogram')
    
    too_many_conditions = histo_bar_vs_line_cutoff  <   len(full_df[Cond].unique())
    too_many_bars       = max_histo_bars            <   len(full_df[Cond].unique()) * full_df[spotName].max()
    # generate plot
    if too_many_conditions or too_many_bars:
        sns.lineplot(x=spotName, y=Freq, hue=Cond, data=histogram_df)
    else:
        sns.barplot (x=spotName, y=Freq, hue=Cond, data=histogram_df)
    
    # plot formatting
    plt.legend(loc = 1, prop={'size': 12})
    plt.title(f'{spotName} in cluster (radius: {radius} pixels)')
    plt.ylabel(Freq)
    plt.grid(axis='y', lw = 0.5)
    # save plot
    figurePath = os.path.join(outputDir, 'Histogram.png')
    plt.savefig(figurePath, dpi=600)
    plt.clf()
        
        
        # make scatterplot
        


#%% MAKE COORELATION GRAPHS
    
if makeLineplot:
    print (f'making correlation for all {Cond}')
    
    # make plot for all conditions in 1 figure
    corr_df = duplicate_singles(full_df)
    sns.lineplot(data = corr_df, x = spotName, y = yAxisName, hue = Cond) 

    x_limits = plt.xlim()
    y_limits = plt.ylim()


    # formatting
    plt.title(f'{yAxisName} vs {spotName}')
    plt.legend(loc = 2, prop={'size': 12})
    plt.grid(lw = 0.5)
    
    figurePath =    os.path.join(outputDir, 'All_Correlations.png')
    plt.savefig(figurePath, dpi=600)
    plt.clf()
    
    # figure output directories
    violinFigDir = os.path.abspath(os.path.join(outputDir, 'ViolinFigs'))
    if not os.path.exists(violinFigDir):
        os.mkdir(violinFigDir)
    
    condLineFigDir = os.path.abspath(os.path.join(outputDir, Cond))
    if not os.path.exists(condLineFigDir):
        os.mkdir(condLineFigDir)
    
    max_spots = full_df[spotName].max() #for formatting
    for i, currcond in enumerate(full_df[Cond].unique()):
        print (f'making correlation diagram for {currcond}')
        
        # generate and save correlation df per condition
        cond_df = corr_df[corr_df[Cond] == currcond]
        condname = currcond
        if MaxLength_CondName and len(condname) > MaxLength_CondName:
            condname = condname[:MaxLength_CondName-3] + '...'
        
        # create line of all data per condition
        sns.lineplot(x = spotName, y = yAxisName, data = cond_df, color = 'r')
        
        # format axes
        plt.title(condname)
        plt.xlim(x_limits)
        plt.xticks(range(max_spots+1))
        plt.ylim(y_limits)
        plt.grid(lw = 0.5)
#        plt.show()
        
        # save data and line plot
        figurePath =    os.path.join(condLineFigDir, condname  + '_Correlation.png')
        plt.savefig(figurePath, dpi=600)
        plt.clf()

        if makeViolinplots:
        # create violin of data per cell
            total = len(full_df[full_df[Cond] == currcond][Image].unique())
            print(f'generating violinplots for {currcond} ({total} total): ', end='')
            for i,curr_image in enumerate(cond_df[Image].unique()):
                if curr_image is not 'fake':
                    print (i+1,end=',')
                    violin_df = cond_df[cond_df[Image] == curr_image]
        
                    # add missing x values
                    for N in range(max_spots+1):
                        if not N in violin_df[spotName].unique():
                            newrow = {Cond:condname, Image:curr_image, spotName:N, yAxisName:np.nan}
                            violin_df = violin_df.append(newrow, ignore_index=True)
                    
                    
                    
                    # plot & formatting
                    sns.lineplot  (x = spotName, y = yAxisName, data = violin_df, color = 'r')
                    sns.violinplot(x = spotName, y = yAxisName, data = violin_df, 
                                   scale = "width", color = 'lightskyblue', lw = 1)
                    
                    plt.title(condname + '\n' + curr_image)
                    plt.xlim(x_limits)
                    plt.ylim(full_df[yAxisName].min(), full_df[yAxisName].max() )
                    plt.grid(axis='y', lw = 0.5)
                    
                    # save figure and data
                    violin_name = condname + "_" + curr_image
                    figurePath =        os.path.join(violinFigDir, violin_name  + '_violin.png')
                    plt.savefig(figurePath, dpi=600)
        #            plt.show()
                    plt.clf()
            print('')
    
#%%
if exportStats:
    print ('exporting stats as csv files')
    
    # get clustering stats per condition
    stats_1 =  getStats(full_df, Cond, spotName)
    save_csv(stats_1, f'{spotName}_stats')
    
    # get signal stats per condition / count
    stats_2 = getStats(full_df, [Cond,spotName], yAxisName)    
    stats_2[Freq] = histogram_df[Freq]
    save_csv(stats_2, f'{yAxisName}_stats_summary')
    
    # get signal stats per imagge / count
    stats_3 = getStats(full_df, [Cond,Image,spotName], yAxisName)
    save_csv(stats_3, f'{yAxisName}_stats_per_image')
    


#%%

if makePrismOutput:
    print ('generating files for Prism')
    
    def prism_output(filename, headers, data):
        if filename.endswith('.csv'):
            filename = filename[:-4]
        
        file = os.path.join(outputDir, filename + '.csv')
        with open(file, 'w') as f:
            f.write(','.join(headers))
            f.write('\n')
            
            for x in range(len(data[0])):
                line = [data[i][x] for i in range(len(data)) ]

                if x>0 and line[0] != data[0][x-1]:
                    f.write('\n')
                
                f.write(','.join(map(str, line)))
                f.write('\n')
    
    
    # scatterplot (swarmplot), using full_df
    prism_type = 'scatterplot'
    headers = [Image, *full_df[Cond].unique()]
    data = [list(full_df[Image])]
    for c in headers[1:]:
        col = [x if full_df[Cond][i] == c else '' for i, x in enumerate(full_df[spotName]) ]
        data.append(col)
#    prism_output(prism_type, headers, data)
    
    
    # scatterplot (swarmplot) with noise, using full_df
    prism_type = 'scatterplot'
    headers = [Image, *full_df[Cond].unique()]
    data = [list(full_df[Image])]
    max_noise = 0.2
    for c in headers[1:]:
        r = np.random.uniform(low = -max_noise, high = max_noise, size = len(full_df[spotName]))
        col = [x+r[i] if full_df[Cond][i] == c else '' for i, x in enumerate(full_df[spotName]) ]
        data.append(col)
#    prism_output(prism_type, headers, data)
    
    
    # Line graph per condition, using stats2
    prism_type = 'XY_per_condition'
    Conds = [cond for cond in stats_2[Cond].unique()]
    
    headers = ['',spotName]
    data = [['']*len(stats_2), list(stats_2[spotName]) ]
    
    for c in Conds:
        headers = headers + [c]*3

        mean =   [x if stats_2[Cond][i] == c else '' for i, x in enumerate(stats_2['Mean']) ]
        stdev =  [x if stats_2[Cond][i] == c else '' for i, x in enumerate(stats_2['StDev']) ]
        counts = [x if stats_2[Cond][i] == c else '' for i, x in enumerate(stats_2['Count']) ]
        data.append(mean)
        data.append(stdev)
        data.append(counts)
    
#    prism_output(prism_type, headers, data)
    
    
    # Line graph per image, using stats3
    prism_type = 'XY_per_image'
    Conds = [cond for cond in stats_3[Cond].unique()]
    IMs =   [im for im in stats_3[Image].unique()]

    headers = ['',spotName]
    data = [list(stats_3[Image]), list(stats_3[spotName]) ]
    
    for c in Conds:
        for im in stats_3[stats_3[Cond] == c][Image].unique():
            ims = [f'{c} - {im}']
            headers = headers + [ele for ele in ims for i in range(3)]
        
            mean =   [x if (stats_3[Cond][i] == c and stats_3[Image][i] == im) else '' for i, x in enumerate(stats_3['Mean']) ]
            stdev =  [x if (stats_3[Cond][i] == c and stats_3[Image][i] == im) else '' for i, x in enumerate(stats_3['StDev']) ]
            counts = [x if (stats_3[Cond][i] == c and stats_3[Image][i] == im) else '' for i, x in enumerate(stats_3['Count']) ]
            data.append(mean)
            data.append(stdev)
            data.append(counts)
    
    prism_output(prism_type, headers, data)

print('')
print('(if you got a FutureWarning, try updating pandas)')
print('all done!')

