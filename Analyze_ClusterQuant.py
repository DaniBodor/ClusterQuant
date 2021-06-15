# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 14:13:59 2020
@author: dani
"""

dataDir = r'.\data\JW_test_210515\_ClusterQuant'


#%%



import numpy as np # probably can find a way around this
import pandas as pd # VERY essential
import os # possibly can find a way around this
from datetime import datetime # non-essential
import matplotlib.pyplot as plt # essential for outputting figures, not CSVs
import seaborn as sns # essential for outputting figures, not CSVs


csvInputFile = [f for f in os.listdir(dataDir) if '_Python' in f][-1]
timestamp = csvInputFile[-14:-4]
expName = os.path.basename(dataDir)
outputDir = os.path.join(dataDir, 'Results_' + timestamp)

starttime = datetime.now()

readData        = 1 # reads data from file; set to False to save time when re-analyzing previous
makeHisto       = 1 # create histogram of spot data
makeLineplot    = 1 # create a correlation graph between spots and intensities
makeViolinplots = 1 # make a violinplot for each cell showing intensity by spot count

cleanup = ['R3D', 'D3D', 'PRJ','dv','tif']
MaxLength_CondName = 0

# names
Cond = 'Condition'
Image = 'Cell'
Freq = 'Frequency'
Freq_no0 = 'Frequency_'
Counts = 'Counts'


#%% FUNCTIONS
#%%
def make_histdf(df):
    '''
    This function will create a frequency distribution dataframe used for histograms
    df: dataframe; input data
    MaxLen: int or False; max character length of condition (so legend doesn't overflow graph). set to 0/False to ignore
    '''

    # Get counts
    output_df = (df.groupby([Cond])[spotName]
                     .value_counts()
                     .rename(Counts)
                     .reset_index() )
    # Get counts and pass to output_df
    df2 = (df.groupby([Cond])[spotName]
                     .value_counts(normalize=True)
                     .rename(Freq)
                     .reset_index() )
    output_df[Freq] = df2[Freq]
    
    # Get 0-free frequencies
    with pd.option_context('mode.chained_assignment',None):
        output_df[Freq_no0] = output_df[Counts]
        zeroes = output_df[spotName] == 0
        output_df[Freq_no0][zeroes] = np.nan
        
        sum_df = output_df.groupby([Cond])[Freq_no0].sum().reset_index()
        for i,f in enumerate(output_df[Freq_no0]):
            output_df[Freq_no0][i] = f / sum_df[Freq_no0][sum_df[Cond] == output_df[Cond][i]]

    
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
    for i,x in enumerate( histogram_df[Counts] ):
        if x == 1:
            cheat_numb = histogram_df[spotName][i]
            cheat_cond = histogram_df[Cond][i]
            cheat_value = 0.0001 + cheat_df.query(f'{Cond} == "{cheat_cond}" and {spotName} == {cheat_numb}')[yAxisName]
            cheatrow = {Cond:cheat_cond, Image:'fake', spotName:cheat_numb, yAxisName:float(cheat_value)}
            cheat_df = cheat_df.append(cheatrow,ignore_index=True)
    return cheat_df
    
    
#%% MAIN       

#%% READ AND ORDER DATA
if readData:
    print ('reading input data')
    
    with open (os.path.join(dataDir,csvInputFile), "r") as myfile:
        lines = [x for x in myfile.readlines() if not x.startswith('#')]

    Folder,File = '',''
    for i,l in enumerate(lines):
        if l.startswith('****'):
            spotName    = l.split(' ')[1]
            yAxisName   = l.split(' ')[2]
            windowSize  = l.split(' ')[3]
            winDisplace = l.split(' ')[4].strip()
            full_df = pd.DataFrame(columns = [Cond, Image, spotName, yAxisName])
            outputDir = outputDir + f'_size{windowSize}_displ{winDisplace}'
            if not os.path.exists(outputDir):
                os.mkdir(outputDir)

        elif l.startswith('***'):
            Folder = l[3:-1]
        elif l.startswith('**'):
            File = name_cleaner(l[2:-1])
            spots = [int(s)   for s in lines[i+1].split(', ')]
            signal = [float(s)   for s in lines[i+2].split(', ')]
            
            indata = {spotName: spots,
                      yAxisName: signal,
                      Cond:  [Folder]*len(spots),
                      Image: [File]*len(spots)}
            
            file_df = pd.DataFrame.from_dict(indata)         # create dataframe from cell
            full_df = full_df.append(file_df)                # add cell to dataframe
    full_df = full_df            [[Cond, Image, spotName, yAxisName]]   # reorder columns
    full_df = full_df.sort_values([Cond, Image, spotName, yAxisName])   # sort from left to right
    full_df.reset_index(drop=True, inplace=True)
    save_csv(full_df, 'All_data')

    nFolders = len(full_df[Cond].unique())


#%% MAKE HISTOGRAM

if makeHisto:
    print ('generating histograms')

    # make and export histogram
    histogram_df = make_histdf(full_df)
    save_csv(histogram_df, 'Histogram')
    
    y_data = [Freq,Freq_no0]
    for x in range(2):
        # generate plot
        if nFolders < 4:
            sns.barplot (x=spotName, y=y_data[x], hue=Cond, data=histogram_df)
        else:
            sns.lineplot(x=spotName, y=y_data[x], hue=Cond, data=histogram_df)
        
        # plot formatting
        plt.legend(loc = 1, prop={'size': 12})
        plt.title(f'{spotName} per {windowSize}x{windowSize} square')
#        plt.xlabel(spotName)
        plt.ylabel(Freq)
        plt.grid(axis='y', lw = 0.5)
        if x == 1:
            plt.xlim(left=0.5)
        # save plot
        figurePath = os.path.join(outputDir, f'Histogram_{x}-based.png')
        plt.savefig(figurePath, dpi=600)
    #    plt.show()
        plt.clf()


#%% MAKE INDIVIDUAL VIOLINPLOTS
    
if makeLineplot:
    print (f'making correlation for all {Cond}')
    
    # make plot for all conditions in 1 figure
    corr_df = duplicate_singles(full_df)
    sns.lineplot(data = corr_df, x = spotName, y = yAxisName, hue = Cond,)
    x_min, x_max = plt.xlim()
    y_min, y_max = plt.ylim()
    
    # formatting
    plt.title(f'{spotName} vs {yAxisName}')
    plt.legend(loc = 1, prop={'size': 12})
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
#        cond_df = cond_df.sort_values([Cond,Image,spotName])
#        cond_df.reset_index(drop=True, inplace=True)
        condname = currcond
        if MaxLength_CondName and len(condname) > MaxLength_CondName:
            condname = condname[:MaxLength_CondName-3] + '...'
#        cond_df.to_csv( os.path.join(outputDir, condname  + '_Correlation.csv'))
        
        # create line of all data per condition
        sns.lineplot(x = spotName, y = yAxisName, data = cond_df, color = 'r')
        
        # format axes
        plt.title(condname)
        plt.xlim(x_min, x_max)
        plt.xticks(range(max_spots+1))
        plt.ylim(y_min, y_max)
        plt.grid(lw = 0.5)
#        plt.show()
        
        # save data and line plot
        figurePath =    os.path.join(condLineFigDir, condname  + '_Correlation.png')
        plt.savefig(figurePath, dpi=600)
        plt.clf()

        if makeViolinplots:
        # create violin of data per cell
            count = len(cond_df[Image].unique())
            print(f'generating violinplots for {currcond} ({count} total): ', end='')
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
                                   scale = "width", color = 'lightskyblue')
                    
                    plt.title(condname + '\n' + curr_image)
                    plt.xlabel(spotName)
                    plt.xlim(x_min, x_max)
                    plt.ylabel(yAxisName)
                    plt.ylim(full_df[yAxisName].min(), full_df[yAxisName].max())
                    plt.grid(axis='y')
                    
                    # save figure and data
                    violin_name = condname + "_" + curr_image
                    figurePath =        os.path.join(violinFigDir, violin_name  + '_violin.png')
                    plt.savefig(figurePath, dpi=600)
        #            plt.show()
                    plt.clf()
            print('')
    
#    for im in lineplots:
        


print('')
print('all done!')
