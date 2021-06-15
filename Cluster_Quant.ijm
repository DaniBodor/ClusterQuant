main_data_default = "";
nondataprefix = "##### "// printed in lines that are not data, will be ignored by python code
printIMname = 0;		// set to 0 or 1 depending on whether you want image name printed to log
time_printing = "time_printing";
file_naming = "file_naming";
starttime = fetchTimeStamp(file_naming);
makeDebugTextWindow = 0;
debugWindow = "Debugging";
start = getTime();
closeWinsWhenDone = true;	// turn off for debugging

run ("Close All");
print ("\\Clear");
roiManager("reset");
run("Colors...", "foreground=white background=black");
close("Debug");
if (isOpen(debugWindow)){
	selectWindow(debugWindow);
	run("Close");
}
while (isOpen("Exception")) {
	selectWindow("Exception");
	run("Close");
}
//run("Text Window...", "name=" + debugWindow + " width=80 height=24 menu");		setLocation(3200, 140);		debugWindow = "[" + debugWindow + "]";


// load defaults
defaults_dir = getDirectory("imagej") + "defaults" + File.separator;
defaults_file = defaults_dir + "Cluster_Quant.txt";
File.makeDirectory(defaults_dir);
defaults = import_defaults();

// set up dialog
Dialog.createNonBlocking("ClusterQuant settings");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage(" INPUT/OUTPUT");
	Dialog.setInsets(0, 100, 0);
	Dialog.addMessage("Main data folder should contain one subfolder with data per experimental condition");
	Dialog.setInsets(0, 20, 0);
	Dialog.addDirectory("Main folder", defaults[0]);
	Dialog.addString("Experiment name", defaults[1], 12);
	Dialog.addString("Image identifier", defaults[2], 12);
	Dialog.setInsets(-35, 255, 0);
	Dialog.addMessage("filenames without this identifier are excluded");

	Dialog.setInsets(10,0,0);
	Dialog.addMessage(" CHANNELS");
	Dialog.setInsets(0,0,0);
	Dialog.addNumber("Clustering channel",	defaults[3],0,3, "measure degree of clustering"); // former: Kinetochore channel
	Dialog.addToSameRow();	Dialog.addString("Name", defaults[4], 12);
	Dialog.addNumber("Correlation channel",	defaults[5],0,3, "correlate clustering with"); // former: Microtubule channel
	Dialog.addToSameRow();	Dialog.addString("Name",defaults[6],12);
	Dialog.addNumber("DNA channel",			defaults[7],0,3, "0 to skip; negative value for manual"); // former: DNA channel

	Dialog.setInsets(10,0,0);
	Dialog.addMessage(" SLIDING WINDOWS");
	Dialog.setInsets(0,0,0);
	Dialog.addNumber("Window size", 		defaults[8],0,5, "pixels");
	Dialog.addNumber("Window displacement",	defaults[9],0,5, "pixels");

	Dialog.setInsets(10,0,0);
	Dialog.addMessage(" MANUALLY SELECT REGIONS TO EXCLUDE FROM ANALYSIS?");
	Dialog.setInsets(0, 20, 0);
	Dialog.addCheckbox("Exclude regions", defaults[11]);
	Dialog.addCheckbox("Load previously excluded regions", defaults[12]);

	Dialog.setInsets(10,0,0);
	Dialog.addMessage(" EXTENDED SETTINGS");
	Dialog.setInsets(0, 20, 0);
	Dialog.addCheckbox("Test extended settings", 0);
	Dialog.addCheckbox("Show extended settings", 0);

Dialog.show();	// retrieve input
	// input/output
	dir = Dialog.getString();
	expName = Dialog.getString();
	expName = replace(expName, " ", "_");
	imageIdentifier = Dialog.getString();
	imageIdentifier = imageIdentifier.toLowerCase;
	outdir = dir + "_" + expName + File.separator;

	// channel order
	clusterChannel = 	Dialog.getNumber(); // former KTchannel
	correlChanel =		Dialog.getNumber(); // former MTchannelro
	dnaChannel =		Dialog.getNumber(); // former DNAchannel
	clusterName =		Dialog.getString(); // for x-axis title
	correlName =		Dialog.getString(); // for y-axis title

	// grid parameters
	gridSize =			Dialog.getNumber();	// size of individual windows to measure
	winDisplacement =	Dialog.getNumber(); // pixel displacement of grid at each step

	// Manual ROI exclusion
	excludeRegions =	Dialog.getCheckbox();
	preloadRegions =	Dialog.getCheckbox();

	// Extended settings
	settingsTester = 	Dialog.getCheckbox();
	extended_settings = Dialog.getCheckbox();

// 2nd dialog
Dialog.create("Extended settings");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage(" BACKGROUND CORRECTION");
	Dialog.setInsets(0,0,2);
	background_methods = newArray("None", "Global", "Local");
	Dialog.addChoice("Correction method", background_methods, defaults[13]);
	Dialog.addNumber("Local background width", defaults[14],0,3, "pixels (only used for local background)");

	//Dialog.setInsets(5,0,0);
	Dialog.addMessage(" DNA AND SPOT DETECTION");
	//Dialog.setInsets(0, 20, 0);
	T_options = getList("threshold.methods");
	Dialog.addChoice("DNA thresholding", T_options, defaults[15]);
	Dialog.addNumber("Dilate cycles", defaults[16],0,3, "");
	Dialog.addNumber("Spot prominence",	defaults[10],0,5, "(higher is more exclusive)");	// prominence parameter from 'Find Maxima'
	
	//Dialog.setInsets(5,0,0);
	Dialog.addMessage(" CROP BORDER");
	Dialog.addNumber("Deconvolution border", defaults[17],0,3, "pixels (16 is default for DV; 0 for no cropping)");


if ( extended_settings ) Dialog.show();
	// Background correction
	bgMeth =	 	Dialog.getChoice();	// background method: 0 = no correction; 1 = global background (median of cropped region); 2 = local background
	bgBand =	 	Dialog.getNumber();	// width of band around grid window to measure background intensity in (only used for local bg)
	// Detection settings
	threshType = 	Dialog.getChoice();	// potentially use RenyiEntropy
	dilateCycles = 	Dialog.getNumber();	// number of dilation cycles for DAPI outline
	prominence =	Dialog.getNumber();	// prominence value of find maxima function
	// Crop border
	deconvCrop =	Dialog.getNumber();	// pixels to crop around each edge (generally 16 for DV Elite). Set to 0 to not crop at all.

// save defaults
defaults = export_defaults();


// Create output directories
File.makeDirectory(outdir);
roiDir = outdir + "ROIs" + starttime + File.separator;
File.makeDirectory(roiDir);
subdirs = getFileList (dir);

// print initial info
print(nondataprefix, "Main folder:", File.getName(dir));
print(nondataprefix, "Start time:", fetchTimeStamp(time_printing) );
print("****", clusterName, correlName, gridSize, winDisplacement);


// loop through individual conditions within base data folder
for (d = 0; d < subdirs.length; d++) {
	subdirname = dir + subdirs [d];

	if (File.isDirectory(subdirname) && File.getName(subdirname) != File.getName(outdir) && !startsWith(File.getName(subdirname),"_")) {
		filelist = getFileList (subdirname);
		subout = roiDir + File.getName(subdirname) + "_ROIs" + File.separator;
		File.makeDirectory(subout);
		print("***" + File.getName(subdirname));

		for (f = 0; f < filelist.length; f++) {		// loop through individual images within condition-folder
			filename = subdirname + filelist [f];

			if ( indexOf(filename.toLowerCase, imageIdentifier) >= 0 ){	// check for identifier

				// open image and run macro
				open(filename);
				rename(filelist[f]);
				if (printIMname == 1)	print(nondataprefix, getTitle());
				cropEdges(deconvCrop);
				clusterQuantification();

				// close and dump memory
				run ("Close All");
				memoryDump(3);
			}
		}
	}
}


// print end time and save log
print(nondataprefix, "End time:", fetchTimeStamp(time_printing) );
print(nondataprefix, "Total duration:", round((getTime() - start)/100)/10, "seconds");
defaults = Array.concat(nondataprefix + " Parameters used:", defaults);
Array.print(defaults);
print(nondataprefix, "All done");

saveLog();

if(isOpen("Results")){
	selectWindow("Results");
	run("Close");

	roiManager("reset");
}





/////////////////////////////////////////////////////////
//////////////////// MINOR FUNCTIONS ////////////////////
/////////////////////////////////////////////////////////

function fetchTimeStamp(format){
	// allows for nice formatting of datetime
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// set to readable output
	year = substring(d2s(year,0),2);
	DateString = year + IJ.pad(month+1,2) + IJ.pad(dayOfMonth,2);
	TimeString = IJ.pad(hour,2) + IJ.pad(minute,2);
	DateTime = "_" + DateString + TimeString;
	
	if (format == time_printing)	return IJ.pad(hour,2) + ":" + IJ.pad(minute,2);
	if (format == file_naming)		return DateTime;
}


function memoryDump(n){
	//print("memory used prior to memory dump: " + IJ.freeMemory());
	for (i = 0; i < n; i++) run("Collect Garbage");
	//print(nondataprefix, "memory used after " + n + "x memory dump: " + IJ.freeMemory());
}

function cropEdges(x){
	if (x > 0) {
		makeRectangle(deconvCrop, deconvCrop, getWidth-deconvCrop*2, getHeight-deconvCrop*2);
		run("Crop");
	}
}

function getLocalBackground(){

	// measure (signal + background) MT intensity
	getSelectionBounds(x, y, w, h);
	makeRectangle(x-bgBand, y-bgBand, w+2*bgBand, h+2*bgBand);	// box for measuring bg
	getStatistics(largeArea, largeMean);
	largeDens = largeArea*largeMean;

	// calculate bg signal and final signal
	rawDens = rawArea * rawMean;
	bgArea	= largeArea - rawArea;
	bgSignal= (largeDens - rawDens) / bgArea;

	return bgSignal;
}

function saveLog(){
	selectWindow("Log");
	saveAs("Text", outdir + "_PythonInput" + starttime + ".csv");
}

function import_defaults(){ 
	
	// set pre-defaults for first time
	defaults = newArray();
	defaults[0] = "" 				;//dir 				= Dialog.getString();
	defaults[1] = "ClusterQuant" 	;//expName 			= Dialog.getString();
	defaults[2] = ".dv" 			;//imageIdentifier	= Dialog.getString();
	defaults[3] = 4 				;//clusterChannel	= Dialog.getNumber();
	defaults[4] = "Spots" 			;//clusterName 		= Dialog.getString();
	defaults[5] = 3 				;//correlChanel 	= Dialog.getNumber();
	defaults[6] = "Intensity" 		;//correlName 		= Dialog.getString();
	defaults[7] = 1 				;//dnaChannel 		= Dialog.getNumber();
	defaults[8] = 16 				;//gridSize 		= Dialog.getNumber();
	defaults[9] = 4 				;//winDisplacement	= Dialog.getNumber();
	defaults[10] = 150 				;//prominence 		= Dialog.getNumber();
	defaults[11] = 0 				;//excludeRegions	= Dialog.getCheckbox();
	defaults[12] = 1 				;//preloadRegions	= Dialog.getCheckbox();
	defaults[13] = "Local" 			;//bgMeth			= Dialog.getChoice();
	defaults[14] = 2 				;//bgBand			= Dialog.getNumber();
	defaults[15] = "RenyiEntropy"	;//threshType		= Dialog.getChoice();
	defaults[16] = 4 				;//dilateCycles		= Dialog.getNumber();
	defaults[17] = 16 				;//deconvCrop		= Dialog.getNumber();

	// import previous defaults if they exist
	
	if (File.exists(defaults_file)) {
		def_str = File.openAsString(defaults_file);
		imp_def = split(def_str, ", ");
		
		if (imp_def.length == defaults.length){
			defaults = imp_def;
		}
	}
	for (i = 0; i < defaults.length; i++) {
		if (defaults[i] == "_") {
			defaults[i] = "";
		}
	}
	return defaults;
}

function export_defaults(){
	defaults = newArray();
	defaults[0] = dir;
	defaults[1] = expName;
	defaults[2] = imageIdentifier;
	defaults[3] = clusterChannel;
	defaults[4] = clusterName;
	defaults[5] = correlChanel;
	defaults[6] = correlName;
	defaults[7] = dnaChannel;
	defaults[8] = gridSize;
	defaults[9] = winDisplacement;
	defaults[10] = prominence;
	defaults[11] = excludeRegions;
	defaults[12] = preloadRegions;
	defaults[13] = bgMeth;
	defaults[14] = bgBand;
	defaults[15] = threshType;
	defaults[16] = dilateCycles;
	defaults[17] = deconvCrop;

	for (i = 0; i < defaults.length; i++) {
		if (defaults[i] == "") {
			defaults[i] = "_";
		}
	}

	print("\\Clear");
	Array.print(defaults);
	selectWindow("Log");
	saveAs("Text", defaults_file);
//	waitForUser("");
	print("\\Clear");


	return defaults;
}

function test_1(){
	selectImage(ori);
	setSlice(3);
	roiManager("Show All without labels");
	roiManager("Show None");
	roiManager("deselect");
	run("From ROI Manager");

	run("Duplicate...", "title=DNA_channel duplicate channels=4");
	run("Tile");
	for (id = 1; id <= nImages; id++) {
		selectImage(id);
		resetMinAndMax;
	}
	selectImage(3);
	run("Threshold...");
	setAutoThreshold(threshType);
	resetMinAndMax();
	
	waitForUser("Check if selection contains all spots: \n \n" + 
			"- if consistently too large/small: change dilate cycles (higher cycle number = larger area; currently: " + dilateCycles + ").\n" +
			"- if completely off, test other threshold method on DNA channel (current default is: " + threshType +").\n" +
			" \nYou can change these parameters in the extended settings window when starting this macro,\nand they will be stored as default in ImageJ");
	
	close("DNA_channel");
	selectImage(ori);
	run("Remove Overlay");
}

function test_2(){
	run("Tile");
	for (id = 1; id <= nImages; id++) {
		selectImage(id);
		resetMinAndMax;
	}
	roiManager("Combine");
	roiManager("add");
	for (i = 1; i <= nImages; i++) {
		selectImage(i);
		roiManager("Show None");
		roiManager("select", roiManager("count")-1);
	}
	selectImage(ori);
	waitForUser("Check whether spot recognition seems OK (spots outside the ROI can be ignored).\n" +
			" \nIf this looks wrong, test to find a good 'Prominence' factor using\n" + 
			"'Process > Find Maxima...' and use 'Preview point selection' to find a good value.\n" +
			"Current default prominence: " + prominence + ".\n" +
			" \nYou can change this parameter in the extended settings window when starting this macro,\nand it will be stored as default in ImageJ");
	roiManager("delete");
}

////////////////////////////////////////////////////////
//////////////////// MAIN FUNCTIONS ////////////////////
////////////////////////////////////////////////////////


function clusterQuantification(){

	// initialize
	ori = getTitle();
	setVoxelSize(1, 1, 0, "px");	// unitize pixel size
	run("Select None");
	resetMinAndMax;
	roiManager("reset");
	cropEdges(deconvCrop);
	ROIfile = subout + ori + ".zip";

	// run sequential steps:
		// step 1: get DAPI outline
		makeMask();
		// step 2: exclude regions
		if (excludeRegions) 	setExcludeRegions();
		else roiManager("save", ROIfile);
		// step 3: make grid
		makeGrid();
		// step 4: make measurements
		before = getTime();
		allData = measureClustering();
		duration = round((getTime() - before)/100)/10;
		
	// retrieve separate arrays from allData
	clusterList = Array.slice(allData, 0, allData.length/2);
	intensList	= Array.slice(allData, allData.length/2, allData.length);

	// print info
	print("**", ori);
	Array.print(clusterList);
	Array.print(intensList);
	//print(nondataprefix, "duration:", duration, "sec");
	
	saveLog();
}


// step 1
function makeMask(){
	if (dnaChannel > 0) {
		// prep images
		selectImage(ori);
		setSlice (dnaChannel);
		run("Duplicate...", "duplicate channels=&dnaChannel");
		run("Grays");
		mask = getTitle();
	
		// make mask
		setAutoThreshold(threshType+" dark");
		run("Convert to Mask");
		run("Fill Holes");
		run("Erode");
	
		// find main cell from mask
		run("Analyze Particles...", "display exclude clear include add");
		while ( roiManager("count") > 1){
			roiManager("select", 0);
			getStatistics(area_0);
			roiManager("select", 1);
			getStatistics(area_1);
			if (area_0 < area_1)	roiManager("select", 0);	// else ROI 1 still selected
			roiManager("delete");
		}

		roiManager("select", 0);
		run("Invert");
		run("Clear Outside");
		run("Select None");
		run("Invert");
		for (i = 0; i < dilateCycles; i++)	run("Dilate");
		run("Analyze Particles...", "display exclude clear include add");

		if (settingsTester)	test_1();
		
		close(mask);
	}
	
	else if (dnaChannel < 0){ // manual selection of analysis region
		setSlice(dnaChannel * -1);
		Stack.setDisplayMode("grayscale");
		run("Duplicate...", "duplicate channels=&dnaChannel");
		mask = getTitle();
		run("Tile");
		for (id = 1; id <= nImages; id++) {
			selectImage(id);
			resetMinAndMax;
		}
		setAutoThreshold("MinError dark");
		setTool("wand");
		waitForUser("Create analysis region and add to ROI manager (Ctrl+t)");
		selectImage(nImages);

		// at least 1 ROI added
		if (roiManager("count") > 0){
			// combine in case >1 ROI was added
			roiManager("Combine");
			roiManager("add");
			while (roiManager("count") > 1) {
				roiManager("select", 0);
				roiManager("delete");
			}
		}
		
		// in case selection was made but not added to ROI list --> add to ROI list
		else if (is("area"))	roiManager("add");	
		
		// no selection --> use entire frame
		else {
			run("Select All");
			roiManager("add");
		}
		
		run("Convert to Mask");
		run("Erode");
		for (i = 0; i < dilateCycles; i++)	run("Dilate");
		roiManager("select", 0);
		getSelectionBounds(_x_, _y_, _, _);
		doWand(_x_, _y_);
		roiManager("update");
		close(mask);
	}
	
	else { //no mask
		run("Select All");
		roiManager("add");
	}

	// save ROI file
	selectImage(ori);
	roiManager("select", 0);
	roiManager("rename", "Analysis region");
}


// step 2
function setExcludeRegions(){

	// load existing ROI files if they exist
	if (preloadRegions && File.exists(ROIfile) ){
		roiManager("reset");
		roiManager("open", ROIfile);
	}
	else {
		// select correct visuals
		selectImage(ori);
		Stack.setChannel(correlChanel);
		run("Select None");
		run("Set... ", "zoom=150");
		setLocation(2000, 50);
		roiManager("Show All without labels");
		setTool("polygon");

		// manually select exclusio regions
		waitForUser("Select regions to exclude.\nAdd each region to ROI manager using Ctrl+t.");

		// rename ROIs and save
		for (roi = 1; roi < roiManager("count"); roi++) {
			roiManager("select", roi);
			roiManager("rename", "Exclude_Region_"+roi);
		}
		roiManager("save", ROIfile);
	}
}


// step 3
function makeGrid() {

	// make cell mask image and exlude MTOCs (only black region will be read)
	selectImage(ori);
	newImage("newMask", "8-bit", getWidth, getHeight, 1);	// creates white image
	mask = getTitle();
	roiManager("select", 0);
	run("Invert");				// makes cell/nuclear outline black
	roiManager("delete");
	roiManager("fill");			// makes exclude regions white
	roiManager("reset");

	// make grid around mask (used to center windows around mask area)	//######## not sure what i meant by this comment, but it works...
	W_offset = (getWidth()  % winDisplacement) / 2;
	H_offset = (getHeight() % winDisplacement) / 2;

	for (x = W_offset; x < getWidth()-W_offset; x+=winDisplacement) {
		for (y = H_offset; y < getHeight()-H_offset; y+=winDisplacement) {
			makeRectangle(x, y, gridSize, gridSize);
			getStatistics(area, mean);
			if (mean == 0 && area == gridSize*gridSize)		roiManager("add");	// only add regions that are completely contained in mask (and within image borders)
		}
	}
	close(mask);

	selectImage(ori);
	run("Select None");
	roiManager("Remove Channel Info");
	roiManager("Show All without labels");
}


// step 4
function measureClustering(){

	// find kinetochores
	selectImage(ori);
	setSlice(clusterChannel);
	run("Find Maxima...", "prominence=" + prominence + " strict exclude output=[Single Points]");
	run("Divide...", "value=255");
	setMinAndMax(0, 1);
	roiManager("Show All without labels");

	saveAs("Tiff", subout + ori + "_Maxima.tif");
	spotIM = getTitle();
	run("Tile");
	for (id = 1; id <= nImages; id++) {
		selectImage(id);
		resetMinAndMax;
	}
	
	// get global bg
	bgSignal = 0;	// for no background correction
	if (bgMeth == background_methods[1]) {	// global bg correction
		setSlice(correlChanel);
		bgSignal = getValue("Median");
	}

	// count number of CEN spots
	Spots = newArray();
	Intensities = newArray();
	
	if (settingsTester)	test_2();

	selectImage(spotIM);
	for (roi = 0; roi < roiManager("count"); roi++) {
		roiManager("select",roi);
		Spots[roi] = getValue("IntDen");
	}

	// Measure correlation (separate loop from above saves a lot of time!)
	selectImage(ori);
	setSlice(correlChanel);
	for (roi = 0; roi < roiManager("count"); roi++) {
		// measure correl channel
		roiManager("select",roi);
		getStatistics(rawArea, rawMean);
		if (bgMeth == background_methods[2])	bgSignal = getLocalBackground();	// local bg correction
		Intensities[roi] = rawMean - bgSignal; // background corrected intensity
	}

	run("Select None");

	data = Array.concat(Spots,Intensities);
	return data;
}
