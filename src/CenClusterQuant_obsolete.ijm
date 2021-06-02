
// Set channel order
dnaChannel = 1;
otherChannel = 2;
correlChanel = 3;
clusterChannel = 4;

// Set grid parameters
gridSize = 32;					// size of individual windows to measure
winDisplacement = -4;		// pixel displacement of separate windows (0 = gridSize; negative = fraction of gridSize -- see notes below)

// Set DAPI outline parameter
threshType = "Huang";		// potentially use RenyiEntropy?
gaussSigma = 40;			// currently unused
dilateCycles = gridSize/4;	// number of dilation cycles (after 1 erode cycle) for DAPI outline

// Centromere recognition
prominence = 150;		// prominence value of find maxima function




// Set MT background correction
bgMeth = 0;		// M background method: 0 = no correction; 1 = global background (median of cropped region); 2 = local background
bgBand = 2;			// width of band around grid window to measure background intensity in

// Set on or off: (0 is off; >0 is on)
excludeMTOCs = 1;
preloadMTOCs = 1;
deconvCrop = 16;	// pixels to crop around each edge (generally 16 for DV Elite). Set to 0 to not crop at all.


// Will pick up settings from MAIN




// These lines are used to run macro on single image (first image in image list, the rest is closed)
// can be commented outdir/deleted for final version, but doesn't interfere so no need
start = getTime();
selectImage(1);
rename (File.getName(getTitle()));
ori = getTitle();

run("Select None");
run("Brightness/Contrast...");

close("\\Others");
roiManager("reset");

Stack.getDimensions(width, height, channels, slices, frames);
run("Properties...", "channels=" + channels + " slices=" + slices + " frames=" + frames + " unit=pix pixel_width=1 pixel_height=1 voxel_depth=0");


// set output folder
arg = getArgument();
if (arg == ""){
	BaseDir = File.directory();
	CurrentFolder = File.getName(BaseDir);
	parent = CurrentFolder;
	while (CurrentFolder != "CenClusterQuant"){
		BaseDir = File.getParent(BaseDir);
		CurrentFolder = File.getName(BaseDir);
	}
	outdir = BaseDir+File.separator+"results" + File.separator +"output" + File.separator;

	
}
else{
	outdir = substring(arg, 0, indexOf(arg, "#%#%#%#%"));
	parent = substring(arg, indexOf(arg, "#%#%#%#%")+8);
}
subout = outdir+"Output_"+parent+File.separator;

// Crop off deconvolution edges
run("Duplicate...", "duplicate");
ori = getTitle();
if (deconvCrop > 0){
	makeRectangle(deconvCrop, deconvCrop, getWidth-deconvCrop*2, getHeight-deconvCrop*2);
	run("Crop");
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Call sequential functions
makeMask(dnaChannel);
if (excludeMTOCs > 0) setExcludeRegions(correlChanel);
makeGrid(gridSize);
CEN_and_MT_data = measureClustering(clusterChannel,correlChanel);
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// print and save output
clusterList = Array.slice(CEN_and_MT_data,0,CEN_and_MT_data.length/2);
MTintensity = Array.slice(CEN_and_MT_data,CEN_and_MT_data.length/2,CEN_and_MT_data.length);

finish = getTime();
duration = round((finish-start)/1000);
print("**"+ori);
Array.print(clusterList);
Array.print(MTintensity);

selectWindow("Log");
timestamp = fetchTimeStamp();
saveAs("Text", outdir+"Log_"+timestamp+".txt");



//print(winDisplacement,duration,"sec",roiManager("count"));
//waitForUser("All done");

/// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% carry on from here!

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CUSTOM DEFINED FUNCTIONs

function makeMask(DNA){
	// prep images
	selectImage(ori);
	setSlice (DNA);
	run("Duplicate...", "duplicate channels=" + DNA);
	run("Grays");
	mask = getTitle();


/*	// de-blur
	run("Duplicate..."," ");
	getTitle() = blur;
	run("Gaussian Blur...", "sigma=" + gaussSigma);
	imageCalculator("Subtract", mask,blur);
	close(blur);
*/

	// make mask
	setAutoThreshold(threshType+" dark");
	run("Convert to Mask");
	run("Options...", "iterations=1 count=1 do=Erode");
	run("Options...", "iterations="+dilateCycles+" count=1 do=Dilate");
	run("Options...", "iterations=1 count=1 do=Nothing");

	// find main cell in mask
	run("Analyze Particles...", "display clear include add");
	
	while ( roiManager("count") > 1){
		roiManager("select", 0);
		getStatistics(area_0);
		roiManager("select", 1);
		getStatistics(area_1);
		if (area_0 < area_1)	roiManager("select", 0);
		roiManager("delete");
	}

	selectImage(ori);
	roiManager("select", 0);
	run("Crop");
	close(mask);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function setExcludeRegions(MTs){
	ROIfile = subout+ori+".zip";
	
	if (preloadMTOCs && File.exists(ROIfile) ){
		roiManager("reset");
		roiManager("open", ROIfile);
	}
	else {	
		// select correct visuals
		selectImage(ori);
		Stack.setChannel(MTs);
		run("Select None");
		run("Set... ", "zoom=300");
		roiManager("Show All without labels");
		setTool("polygon");
		run("Colors...", "foreground=white background=black selection=green");
	
		// manual intervention
		waitForUser("Select regions to exclude.\nAdd each region to ROI manager using Ctrl+t.");
	
		// rename ROIs
		roiManager("select", 0);
		roiManager("rename", "analysis region");
		for (roi = 1; roi < roiManager("count"); roi++) {
			roiManager("select", roi);
			roiManager("rename", "MTOC_"+roi);
		}
			
		// save cell outline and MTOC regions
		File.makeDirectory(subout);
		roiManager("save", ROIfile);
	}
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function makeGrid(gridSize) {
	// make cell mask image
	selectImage(ori);
	newImage("newMask", "8-bit", getWidth, getHeight,1);
	mask = getTitle();
	roiManager("select", 0);
	run("Invert");
	roiManager("delete");

	// exclude MTOCs from mask 	
	roiManager("fill");
	roiManager("reset");
	
	// make grid around mask
	W_offset = (getWidth()  % winDisplacement) / 2;  // used to center windows around mask area
	H_offset = (getHeight() % winDisplacement) / 2;	// used to center windows around mask area
		
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


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function measureClustering(KTch,MTch){
	// find kinetochores
	selectImage(ori);
	setSlice(KTch);
	run("Find Maxima...", "prominence="+prominence+" strict exclude output=[Single Points]");
	roiManager("Show All without labels");
	spots = getTitle();
	if (!File.isDirectory(subout))	File.makeDirectory(subout);
	saveAs("Tiff", subout+ori+"_Maxima.tif");
	run("Divide...", "value=255");
	setMinAndMax(0, 1);

	roiCount = roiManager("count");
	CENs = newArray(roiCount);

	for (roi = 0; roi < roiCount; roi++) {
		// count number of CEN spots
		roiManager("select",roi);
		CENs[roi] = getValue("IntDen");	
	}
	
	selectImage(ori);
	setSlice(MTch);
	MTint = newArray(roiCount);
	MTmedian = getValue("Median");
	for (roi = 0; roi < roiCount; roi++) {
		// measure MT intensity
		roiManager("select",roi);
		getStatistics(rawarea, rawmean);
		rawdens = rawarea*rawmean;

		if		(bgMeth == 0)		bgsignal = 0;			// no background correction
		else if (bgMeth == 1)		bgsignal = MTmedian;	// global background correction
		else if (bgMeth == 2){							// local background correction (in following block)
			// measure (signal + background) MT intensity
			getSelectionBounds(x, y, w, h);
			makeRectangle(x-bgBand, y-bgBand, w+2*bgBand, h+2*bgBand);	// box for measuring bg
			getStatistics(largearea, largemean);
			largedens = largearea*largemean;
			
			// calculate bg signal and final signal
			bgarea = largearea - rawarea;
			bgsignal = (largedens-rawdens) / bgarea;
		}

		// output
		MTint[roi] = rawmean - bgsignal; // background corrected intensity
	}
	run("Select None");
	
	data = Array.concat(CENs,MTint);
	return data;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function fetchTimeStamp(){
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// set to readable output
	year = substring(d2s(year,0),2);
	DateString = year + IJ.pad(month+1,2) + IJ.pad(dayOfMonth,2);
	TimeString = IJ.pad(hour,2) + IJ.pad(minute,2);

	// concatenate and return
	DateTime = DateString+TimeString;
	return DateTime;
}
