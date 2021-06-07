main_data_default = "C:\\Users\\dani\\Documents\\MyCodes\\ClusterQuant\\data\\test_data";
nondataprefix = "##### "// printed in lines that are not data, will be ignored by python code
printIMname = 0;		// set to 0 or 1 depending on whether you want image name printed to log
time_printing = "time_printing";
file_naming = "file_naming";
starttime = fetchTimeStamp(file_naming);
makeDebugTextWindow = 0;
debugWindow = "Debugging";
start = getTime();

run ("Close All");
print ("\\Clear");
roiManager("reset");
run("Colors...", "foreground=white background=black");
close("Debug");
if (isOpen(debugWindow)){
	selectWindow(debugWindow);
	run("Close");
}




//run("Text Window...", "name=" + debugWindow + " width=80 height=24 menu");		setLocation(3200, 140);		debugWindow = "[" + debugWindow + "]";




// set up dialog
Dialog.createNonBlocking("ClusterQuant settings");
	Dialog.addMessage(" SELECT DATA FOLDER");
	Dialog.addMessage(" Main data folder should contain one subfolder with data per experimental condition");
	Dialog.addDirectory("Main folder", main_data_default);
	Dialog.addString("Image identifier", "D3D_PRJ.dv", "only file names containing this identifier will be read (leave empty to include all)");
	Dialog.addString("Output folder name","_Results");

	Dialog.addMessage("\n SET CHANNEL ORDER");
	Dialog.addNumber("Clustering channel",	4,0,3, "channel to measuring degree of clustering"); // former: Kinetochore channel
	Dialog.addNumber("Correlation channel",	3,0,3, "channel to correlate degree of clustering with; use 0 to skip this step"); // former: Microtubule channel
	Dialog.addNumber("DNA channel",			1,0,3, "used for excluding non-chromosomal foci; use 0 to skip this step"); //
	Dialog.addNumber("Other channel",		2,0,3, "currently unused"); // former: Corona channel

	Dialog.addMessage("\n MEASRUEMENT WINDOWS");
	Dialog.addNumber("Window size", 		16,0,3, "pixels");
	Dialog.addNumber("Displacement ratio",	 4,0,3, "Window size / N");	// pixel displacement of separate windows (0 = gridsize; negative = fraction of gridsize -- see notes below)

	Dialog.addMessage("\n SPOT RECOGNITION");
	Dialog.addNumber("Prominence factor",	150,0,3, "");

	Dialog.addMessage("\n NUCLEUS OUTLINING");
	T_options = getList("threshold.methods");
	Dialog.addChoice("DNA thresholding method", T_options, "Huang");		// potentially use RenyiEntropy?
	Dialog.addNumber("Gaussian blur",		40,0,3, "pixels");
	Dialog.addNumber("Dilate cycles",		 4,0,3, "pixels (after 1 erode cycle)");

	Dialog.addMessage("\n BACKGROUND CORRECTION");
	background_methods = newArray("None", "Global", "Local");
	Dialog.addChoice("background correction method", background_methods, background_methods[2]);
	Dialog.addNumber("Local background width", 	 2,0,3, "pixels (only used for local background)");

	Dialog.addMessage("\n OTHER");
	Dialog.setInsets(0, 20, 0);
	Dialog.addCheckbox("Exclude regions", 1);
	Dialog.addCheckbox("Load previously excluded regions", 1);
	Dialog.addNumber("Crop deconvolution border", 	 0,0,3, "pixels (16 is default for DV; 0 for no deconvolution");

Dialog.show();	// retrieve input
	// input/output
	dir = Dialog.getString();
	imageIdentifier = Dialog.getString();
	imageIdentifier = imageIdentifier.toLowerCase;
	outdir = dir + Dialog.getString() + File.separator;
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
	excludeRegions =	Dialog.getCheckbox();
	preloadRegions =	Dialog.getCheckbox();
	deconvCrop =	Dialog.getNumber();	// pixels to crop around each edge (generally 16 for DV Elite). Set to 0 to not crop at all.



// print initial info
print(nondataprefix, "Main folder:", File.getName(dir));
print(nondataprefix, "Start time:", fetchTimeStamp(time_printing) );


// loop through individual conditions within base data folder
for (d = 0; d < subdirs.length; d++) {
	subdirname = dir + subdirs [d];

	if (File.isDirectory(subdirname) && File.getName(subdirname) != File.getName(outdir)) {
		filelist = getFileList (subdirname);
		subout = outdir + "output_" + File.getName(subdirname) + File.separator;
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

				// save output
				selectWindow("Log");
				saveAs("Text", outdir + "Log_" + starttime + ".txt");

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
print(nondataprefix, "All done");

selectWindow("Log");
saveAs("Text", outdir + "Log_" + starttime + ".txt");




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
	DateTime = DateString+"_"+TimeString;
	
	if (format == time_printing)	return IJ.pad(hour,2) + ":" + IJ.pad(minute,2);
	if (format == file_naming)	return DateTime;
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

	//print(largeArea, largeMean, rawDens, bgArea, bgSignal);

	return bgSignal;
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
		if(dnaChannel > 0) makeMask();
		// step 2: exclude regions
		if (excludeRegions) 			setExcludeRegions();
		else if (roiManager("count")>0) roiManager("save", ROIfile);
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

	// save log
	selectWindow("Log");
	saveAs("Text", outdir + "Log_" + starttime + ".txt");
}


// step 1
function makeMask(){
	// prep images
	selectImage(ori);
	setSlice (dnaChannel);
	run("Duplicate...", "duplicate channels=&dnaChannel");
	run("Grays");
	mask = getTitle();

	// make mask
	setAutoThreshold(threshType+" dark");
	run("Convert to Mask");
	run("Erode");
	for (i = 0; i < dilateCycles; i++)	run("Dilate");

	// find main cell in mask
	run("Analyze Particles...", "display clear include add");

	while ( roiManager("count") > 1){
		roiManager("select", 0);
		getStatistics(area_0);
		roiManager("select", 1);
		getStatistics(area_1);
		if (area_0 < area_1)	roiManager("select", 0);	// else ROI 1 still selected
		roiManager("delete");
	}
	close(mask);

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
	run("Find Maxima...", "prominence=&prominence strict exclude output=[Single Points]");
	run("Divide...", "value=255");
	setMinAndMax(0, 1);
	roiManager("Show All without labels");

	saveAs("Tiff", subout + ori + "_Maxima.tif");
	spotIM = getTitle();

	// get global bg
	bgSignal = 0;	// for no background correction
	if (bgMeth == background_methods[1]) {	// global bg correction
		setSlice(correlChanel);
		bgSignal = getValue("Median");
	}

	// count number of CEN spots
	Spots = newArray();
	Intensities = newArray();
	selectImage(spotIM);
	for (roi = 0; roi < roiManager("count"); roi++) {
		roiManager("select",roi);
		Spots[roi] = getValue("IntDen");
	}

	// Measure correlation (separate loop from above saves a lot of time!)
	selectImage(ori);
	for (roi = 0; roi < roiManager("count"); roi++) {
		// measure correl channel
		roiManager("select",roi);
		setSlice(correlChanel);
		getStatistics(rawArea, rawMean);
		if (bgMeth == background_methods[2])	bgSignal = getLocalBackground();	// local bg correction
		Intensities[roi] = rawMean - bgSignal; // background corrected intensity
	}

	run("Select None");

	data = Array.concat(Spots,Intensities);
	return data;
}
