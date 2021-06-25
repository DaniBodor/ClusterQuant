# ClusterQuant

Version 1.0

Measure degree of clustering of individual spots relative to local signal intensity of another channel.

## README under construction
...  
...

## IGNORE BELOW

## Input/Output

Place any number of data folders (one folder containing multiple images) within data>raw (see Project organization below). These will be annotated separately and will result in properly formatted output graphs.
Filenames ending with "PRJ.tif" or "PRJ.dv" (note the capitals) will be read by the code. Other files can exist within data folder without interference.

Run *src>MAIN_RunOnSubfolders.ijm* and select data>raw as base directory (drag into ImageJ or FiJi and hit run). This will output a \*.txt file which is then read by the Python code.
Next, run *src>CEN_cluster_analysis.py* from a Python compiler (doesn't work from FiJi for whatever reason).

This will output three types of data:
1) a \*.txt file with all raw data in *results>output*(see format below)
2) a single histogram comparing number of CENs per squareby dataset in *results>figures*
3) one lineplot per dataset showing the average +/- SD (I believe) tubulin intensity by number of centromeres per square in *results>figures*
4) one violinplot per image showing the distribution of tubulin intensity by number of centromeres per square in *results>figures>subfolder*

The \*.txt file will be organized as follows:
```
##### Running CenClusterQuant on [base folder]
##### Start time: [current time]
***[folder name]
**[image name]
[list of CEN counts]
[list of tubulin intensities]
**[image name]
[list of CEN counts]
[list of tubulin intensities]
***[folder name]
**[image name]
[list of CEN counts]
[list of tubulin intensities]
etc.
##### End time: [current time]
##### All done
```


## Project organization

Used Barbara Vreede's 'good-enough-project' cookiecutter setup for project organization (cookiecutter gh:bvreede/good-enough-project)

```
.
├── .gitignore
├── CITATION.md
├── LICENSE.md
├── README.md
├── requirements.txt
├── data               <- All project data, ignored by git
│   └── base           <- Place raw data here, separated into subfolders by condition (RO)
│       ├── dataset 1  <- separate conditions to be analyzed (containing multiple images) (RO) 
│       ├── dataset 2   
│       ├── ...         
│       └── dataset N   
├── results
│   ├── figures        <- Figures for the manuscript or reports (PG)
│   └── output         <- Other output for the manuscript or reports (PG)
└── src                <- Source code for this project (HW)
    └── external       <- External code/plugins required (RO)
```


## License

This project is licensed under the terms of the [MIT License](/LICENSE.md)

## Citation

Please [cite this project as described here](/CITATION.md).
