# ClusterQuant

This project measures the degree of clustering of individual spots relative to local signal intensity of another channel.


# README UNDER CONSTRUCTION


## Workflow
1) Organize image data as explained below
2) Run _Cluster_Quant.ijm_ and select base data folder
3) Run _Analyze_ClusterQuant.py_ on the csv output file from step 2 (filename starting with _\_PythonInput_)


#### Step 1: Input data organization
Macro works on any projected microscopy image that can be opened in FiJi.
Create a base directory for data analysis. Within the base directory, create separate directories for each condition to be analyzed. Within these directories, place all images to be analyzed for this condition. (Note foldernames starting with an underscore will not be read.) E.g.,  
<img src="README_pics/DirTree.PNG">


#### Step 2: Running ClusterQuant.ijm from FiJi (ImageJ)
Drag _Cluster_Quant.ijm_ into FiJi and hit Run at the bottom of the script editor. This will open a dialog window with a number of options.

INPUT/OUTPUT:
- Main folder: choose base directory listed above
- Experiment name: Names the output folder
- Image identifier: input that must be present in all filenames to be read; any filename that does not contain. E.g. if folders contain both raw data and projected images, write the identifying part of the filename of the projected images (usually "PRJ"). This can be left empty if all files present in the folders should be analyzed.

CHANNELS:


#### Step 3: Running Analyze_ClusterQuant.py in Python


#### Step 4: Post-processing data





## License

This project is licensed under the terms of the [MIT License](/LICENSE.md)

## Citation

Please [cite this project as described here](/CITATION.md).
