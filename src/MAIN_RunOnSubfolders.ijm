BaseDirName = "CenClusterQuant";
image_identifier="";	// only files containing this identifier in the file name will be opened (empty string will include all)
printDIRname = 1;		// set to 0 or 1 depending on whether you want directory name printed to log
printIMname = 0;		// set to 0 or 1 depending on whether you want image name printed to log
printStartEnd = 1;		// set to 0 or 1 depending on whether you want start and end time printed to log
saveLogResults = 1;		// set to 0 or 1 depending on whether you want to save log results
non_data_prefix="##### "// printed in lines that are not data

// set up
run ("Close All");
print ("\\Clear");
dir = getDirectory ("Choose CenClusterQuant data directory");
subdirs = getFileList (dir);

// recognize own location
BaseDir = File.getParent(dir);
CurrentFolder = File.getName(BaseDir);
while (CurrentFolder != BaseDirName){
	BaseDir = File.getParent(BaseDir);
	CurrentFolder = File.getName(BaseDir);
}

// other paths required
MacroPath = BaseDir + File.separator  + "src" + File.separator + BaseDirName + ".ijm";
OutputPath = BaseDir + File.separator  + "results" + File.separator + "output"+File.separator;
print(non_data_prefix+"Running", BaseDirName, "on" , File.getName(dir));

// fetch time
timestamp = fetchTimeStamp();
if(printStartEnd==1)	print(non_data_prefix+"Start time: " +substring(timestamp,lengthOf(timestamp)-4));


// lots of loops and conditions to find correct files in correct folders

// loop through individual conditions within base data folder
for (d = 0; d < subdirs.length; d++) {
	subdirname = dir + subdirs [d];

	// check that it is indeed  folder
	if ( endsWith (subdirname, "/")){
		filelist = getFileList (subdirname);
		if (printDIRname == 1)	print("***" + File.getName(subdirname));
		
		// loop through individual images within condition-folder
		for (f = 0; f < filelist.length; f++) {
		//for (f = 0; f < 5; f++) {		// use for testing on few images
			filename = subdirname + filelist [f];

			// check that file is an image (*.tif or *.dv) abd that it contains the identifier set at the top
			if ( endsWith (filename, ".tif") || endsWith (filename, ".dv") ){
				if (indexOf(filelist [f] , image_identifier) >= 0 ){
					// correct files were found
					
					// open image and run macro
					open(filename);
					ori = getTitle();
					RunCode(ori);

					// save output
					selectWindow("Log");
					if (saveLogResults)		saveAs("Text", OutputPath+"Log_"+timestamp+".txt");

					// close and dump memory
					run ("Close All"); 	
					memoryDump(3);
				}
			}
		}
	}
}


// print end time if desired
if (printStartEnd == 1){
	endtime = fetchTimeStamp();
	print(non_data_prefix+"End time: " + substring(endtime, lengthOf(endtime)-4) );
}

print (non_data_prefix + "All done");
if (saveLogResults)		saveAs("Text", OutputPath + "Log_" + timestamp + ".txt");



function RunCode(IM){
	if (printIMname == 1)	print(non_data_prefix+IM);
	argument1 = OutputPath;
	argument2 = File.getName(subdirname);
	passArgument = argument1 + "#%#%#%#%" + argument2;
	runMacro(MacroPath, passArgument);
		
	//waitForUser(IM);
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function fetchTimeStamp(){
	// allows for nice formatting of datetime
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// set to readable output
	year = substring(d2s(year,0),2);
	DateString = year + IJ.pad(month+1,2) + IJ.pad(dayOfMonth,2);
	TimeString = IJ.pad(hour,2) + IJ.pad(minute,2);

	// concatenate and return
	DateTime = DateString+"_"+TimeString;
	return DateTime;
}


function memoryDump(n){
	print("memory used prior to memory dump: " + IJ.freeMemory());
	for (i = 0; i < n; i++) run("Collect Garbage");
	print("memory used after " + n + "x memory dump: " + IJ.freeMemory());
}


function settingsDialog(){
	Dialog.create("Settings");
	
	Dialog.addMessage(" Set channel order");
	// **** I need to rename these their function
	Dialog.addNumber("DNA channel", 		 1,0,3, "");
	Dialog.addNumber("Corona channel", 		 2,0,3, "");
	Dialog.addNumber("Microtubule channel",  3,0,3, "");
	Dialog.addNumber("Kinetochore channel",  4,0,3, "");
	
	Dialog.addMessage("\n Measurement windows");
	Dialog.addNumber("Window size", 			16,0,3, "pixels");
	Dialog.addNumber("Window displacement",  4,0,3, "pixels");	// pixel displacement of separate windows (0 = gridsize; negative = fraction of gridsize -- see notes below)

	Dialog.addMessage("\n Centromere recognition");
	Dialog.addNumber("Centromere prominence",	150,0,3, "");
	
	Dialog.addMessage("\n Nucleus outlining");
	Dialog.addChoice("DNA thresholding method", getList("threshold.methods"), "Huang");		// potentially use RenyiEntropy?
	Dialog.addNumber("Gaussian blur",		40,0,3, "pixels");
	Dialog.addNumber("Dilate cycles",		 4,0,3, "pixels (after 1 erode cycle)");
	
	Dialog.addMessage("\n Background correction");
	background_methods = newArray("None", "Global", "Local");
	Dialog.addChoice("background correction", background_methods, background_methods[2]);
	Dialog.addNumber("Local background width", 	 2,0,3, "pixels (unused for global or no background correction)");

	Dialog.addMessage("\n Other settings");
	Dialog.addCheckbox("Save log", 1);
	Dialog.addCheckbox("Exclude regions", 1);
	Dialog.addCheckbox("Load excluded regions", 1);
	Dialog.addNumber("Crop deconvolution border", 	 16,0,3, "pixels (16 is default for DV; 0 for no deconvolution");

	// retrieve input
	Dialog.show();

	// channel order
	DNAchannel =	Dialog.getNumber();
	COROchannel =	Dialog.getNumber();
	MTchannel =		Dialog.getNumber();
	KTchannel = 	Dialog.getNumber();
	
	// grid parameters
	gridsize =		Dialog.getNumber();	// size of individual windows to measure
	WindowDisplacement = Dialog.getNumber();;		// pixel displacement of separate windows (0 = gridsize; negative = fraction of gridsize -- see notes below)
	
	// Centromere recognition
	CEN_prominence = Dialog.getNumber();		// prominence value of find maxima function
		
	// Nuclear outline
	ThreshType = 	Dialog.getChoice();		// potentially use RenyiEntropy?
	GaussSigma = 	Dialog.getNumber();	// currently unused
	DilateCycles = 	Dialog.getNumber();	// number of dilation cycles (after 1 erode cycle) for DAPI outline

	// Background correction
	bgMeth =	 	Dialog.getChoice();	// background method: 0 = no correction; 1 = global background (median of cropped region); 2 = local background
	bgBand =	 	Dialog.getNumber();	// width of band around grid window to measure background intensity in
	
	// Other
	saveLogOutput =	Dialog.getCheckbox();
	ExcludeMTOCs =	Dialog.getCheckbox();
	preload_MTOCs =	Dialog.getCheckbox();
	DeconvCrop =	Dialog.getNumber();	// pixels to crop around each edge (generally 16 for DV Elite). Set to 0 to not crop at all.
}
