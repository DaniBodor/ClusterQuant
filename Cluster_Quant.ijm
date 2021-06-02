printIMname = 0;		// set to 0 or 1 depending on whether you want image name printed to log
non_data_prefix="##### "// printed in lines that are not data, will be ignored by python code

run ("Close All");
print ("\\Clear");


// set up
Dialog.create("Settings");
	Dialog.addMessage(" Select main data folder");
	Dialog.addMessage(" Main data folder should contain one subfolder with data per experimental condition");
	Dialog.addDirectory("Main folder", "");
	Dialog.addString("Image identifier", "D3D_PRJ.dv", "only file names containing this identifier will be read (leave empty to include all)");
	Dialog.addString("Output folder name","_Results");
	
	Dialog.addMessage("\n Set channel order");
	Dialog.addNumber("Clustering channel",	4,0,3, "channel to measuring degree of clustering"); // former: Kinetochore channel
	Dialog.addNumber("Correlation channel",	3,0,3, "channel to correlate degree of clustering with; use 0 to skip this step"); // former: Microtubule channel
	Dialog.addNumber("DNA channel",			1,0,3, "used for excluding non-chromosomal foci; use 0 to skip this step"); // 
	Dialog.addNumber("Other channel",		2,0,3, "currently unused"); // former: Corona channel
	
	Dialog.addMessage("\n Measurement windows");
	Dialog.addNumber("Window size", 		16,0,3, "pixels");
	Dialog.addNumber("Displacement ratio",	 4,0,3, "1/N displacement per stap");	// pixel displacement of separate windows (0 = gridsize; negative = fraction of gridsize -- see notes below)

	Dialog.addMessage("\n Spot recognition");
	Dialog.addNumber("Prominence factor",	150,0,3, "");
	
	Dialog.addMessage("\n Nucleus outlining");
	Dialog.addChoice("DNA thresholding method", getList("threshold.methods"), "Huang");		// potentially use RenyiEntropy?
	Dialog.addNumber("Gaussian blur",		40,0,3, "pixels");
	Dialog.addNumber("Dilate cycles",		 4,0,3, "pixels (after 1 erode cycle)");
	
	Dialog.addMessage("\n Background correction");
	background_methods = newArray("None", "Global", "Local");
	Dialog.addChoice("background correction", background_methods, background_methods[2]);
	Dialog.addNumber("Local background width", 	 2,0,3, "pixels (only used for local background)");

	Dialog.addMessage("\n Other settings");
	Dialog.addCheckbox("Save log", 1);
	Dialog.addCheckbox("Exclude regions", 1);
	Dialog.addCheckbox("Load excluded regions", 1);
	Dialog.addNumber("Crop deconvolution border", 	 16,0,3, "pixels (16 is default for DV; 0 for no deconvolution");

Dialog.show();	// retrieve input
	// input/output
	dir = Dialog.getString();
	imageIdentifier = Dialog.getString();
	outdir = dir + getString("prompt", "default") + File.separator;
	subdirs = getFileList (dir);
	File.makeDirectory(outdir);

	// channel order
	clusterChannel = 	Dialog.getNumber(); // former KTchannel
	correlChanel =		Dialog.getNumber(); // former MTchannel
	dnaChannel =		Dialog.getNumber(); // former DNAchannel
	otherChannel =		Dialog.getNumber(); // former COROchannel

	// grid parameters
	gridSize =			Dialog.getNumber();	// size of individual windows to measure
	winDisplacement =	gridSize / Dialog.getNumber(); // pixel displacement of grid at each step
	
	// Centromere recognition
	prominence =		Dialog.getNumber();		// prominence value of find maxima function
		
	// Nuclear outline
	threshType = 	Dialog.getChoice();	// potentially use RenyiEntropy?
	gaussSigma = 	Dialog.getNumber();	// currently unused
	dilateCycles = 	Dialog.getNumber();	// number of dilation cycles (after 1 erode cycle) for DAPI outline

	// Background correction
	bgMeth =	 	Dialog.getChoice();	// background method: 0 = no correction; 1 = global background (median of cropped region); 2 = local background
	bgBand =	 	Dialog.getNumber();	// width of band around grid window to measure background intensity in (only used for local bg)
	
	// Other
	excludeMTOCs =	Dialog.getCheckbox();
	preloadMTOCs =	Dialog.getCheckbox();
	deconvCrop =	Dialog.getNumber();	// pixels to crop around each edge (generally 16 for DV Elite). Set to 0 to not crop at all.



// print initial info
print(non_data_prefix, "Current file:", File.getName(dir));
timestamp = fetchTimeStamp();
print(non_data_prefix, "Start time:", substring(timestamp,lengthOf(timestamp)-4));


// loop through individual conditions within base data folder
for (d = 0; d < subdirs.length; d++) {
	subdirname = dir + subdirs [d];		

	if ( endsWith (subdirname, File.separator)){	// check that it is a  folder
		filelist = getFileList (subdirname);
		print("***" + File.getName(subdirname));
		
		for (f = 0; f < filelist.length; f++) {		// loop through individual images within condition-folder
			filename = subdirname + filelist [f];

			if ( indexof(filename.toLowerCase, imageIdentifier) >= 0 ){	// check for identifier
				
				// open image and run macro
				open(filename);
				if (printIMname == 1)	print(non_data_prefix, getTitle());
				clusterQuantification();

				// save output
				selectWindow("Log");
				saveAs("Text", outdir + "Log_" + timestamp + ".txt");

				// close and dump memory
				run ("Close All"); 	
				memoryDump(3);
			}
		}
	}
}


// print end time and save log
endtime = fetchTimeStamp();
print(non_data_prefix, "End time:", substring(endtime, lengthOf(endtime)-4) );
print (non_data_prefix, "All done");
saveAs("Text", outdir + "Log_" + timestamp + ".txt");




/////////////////////////////////////////////////////////
//////////////////// MINOR FUNCTIONS ////////////////////
/////////////////////////////////////////////////////////

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



///////////////////////////////////////////////////////
//////////////////// MAIN FUNCTION ////////////////////
///////////////////////////////////////////////////////


function clusterQuantification(IM){

ori = getTitle();




}




