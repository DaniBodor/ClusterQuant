// set output folder
out = "C:/Users/dani/Dropbox (Personal)/____Recovery/Fiji.app/Custom_Codes/CenClusterQuant/results/output/";

// Set on or off: (0 is off; >0 is on)
saveLogOutput = 0;
ExcludeMTOCs = 1;
DeconvolutionCrop = 16;	// pixels to crop around each edge (generally 16 for DV Elite). Set to 0 to not crop at all.

// Set channel order
DNAchannel = 1;
COROchannel = 2;
MTchannel = 3;
KTchannel = 4;

// Set grid parameters
gridsize = 16;				// size of individual windows to measure
WindowDisplacement = 2;		// serial displacement of window (0 = gridsize; negative = fraction of gridsize -- see notes below)

// Set DAPI outline parameter
ThreshType = "Huang";		// potentially use RenyiEntropy?
GaussSigma = 40;			// currently unused
DilateCycles = gridsize/2;	// number of dilation cycles (after 1 erode cycle) for DAPI outline

// Centromere recognition
CEN_prominence = 150;		// prominence value of find maxima function

// Set MT background correction
MTbgCorrMeth = 0;		// M background method: 0 = no correction; 1 = global background (median of cropped region); 2 = local background
MT_bg_band = 2;			// width of band around grid window to measure background intensity in



/////// WindowDisplacement:
// if WindowDisplacement > 0 --> Displacement value of for rolling window  (1 takes kinda long, 2 is fine)
// if WindowDisplacement = 0 --> WindowDisplacement = gridsize, perfect non-overlapping grid
// if WindowDisplacement < 0 --> Absolute value gives the fraction of gridsize as rolling window value. E.g. -2 will give 1/2 gridsize (i.e. 50% overlap) and -4 will give 1/4 gridsize (i.e. 75% overlap)
if (WindowDisplacement == 0)		WindowDisplacement = gridsize;
else if (WindowDisplacement < 0){
	division = abs(WindowDisplacement);
	WindowDisplacement = (gridsize/division);
}





// These lines are used to run macro on single image (first image in image list, the rest is closed)
// can be commented out/deleted for final version, but doesn't interfere
start = getTime();
selectImage(1);
ori = getTitle();


run("Select None");
run("Brightness/Contrast...");

close("\\Others");
roiManager("reset");

Stack.getDimensions(width, height, channels, slices, frames);
run("Properties...", "channels=" + channels + " slices=" + slices + " frames=" + frames + " unit=pix pixel_width=1 pixel_height=1 voxel_depth=0");


// Crop off deconvolution edges
run("Duplicate...", "duplicate");
workingImage = getTitle();
if (DeconvolutionCrop > 0){
	makeRectangle(DeconvolutionCrop, DeconvolutionCrop, getWidth-DeconvolutionCrop*2, getHeight-DeconvolutionCrop*2);
	run("Crop");
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Call sequential functions
makeMask(DNAchannel);
if (ExcludeMTOCs > 0) SetExcludeRegions(MTchannel);
makeGrid(gridsize);
CEN_and_MT_data = MeasureClustering(KTchannel,MTchannel);
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// print and save output
clusterList = Array.slice(CEN_and_MT_data,0,CEN_and_MT_data.length/2);
MTintensity = Array.slice(CEN_and_MT_data,CEN_and_MT_data.length/2,CEN_and_MT_data.length);

finish = getTime();
duration = round((finish-start)/1000);
Array.print(ori,clusterList);
Array.print(ori,MTintensity);

if (saveLogOutput){
	selectWindow("Log");
	timestamp = fetchTimeStamp();
	saveAs("Text", out+"Log_"+timestamp+".txt");
}



//print(WindowDisplacement,duration,"sec",roiManager("count"));
//waitForUser("All done");



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CUSTOM DEFINED FUNCTIONs

function makeMask(DNA){
	// prep images
	selectImage(workingImage);
	setSlice (DNA);
	run("Duplicate...", "duplicate channels=" + DNA);
	run("Grays");
	mask = getTitle();


/*	// de-blur
	run("Duplicate..."," ");
	getTitle() = blur;
	run("Gaussian Blur...", "sigma=" + GaussSigma);
	imageCalculator("Subtract", mask,blur);
	close(blur);
*/

	// make mask
	setAutoThreshold(ThreshType+" dark");
	run("Convert to Mask");
	run("Options...", "iterations=1 count=1 do=Erode");
	run("Options...", "iterations="+DilateCycles+" count=1 do=Dilate");
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

	selectImage(workingImage);
	roiManager("select", 0);
	run("Crop");
	close(mask);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function SetExcludeRegions(MTs){
	// select correct visuals
	selectImage(workingImage);
	Stack.setChannel(MTs);
	run("Select None");
	run("Set... ", "zoom=300");
	roiManager("Show All without labels");
	setTool("polygon");
	run("Colors...", "foreground=white background=black selection=green");

	// manual intervention
	waitForUser("Select regions to exclude.\nAdd each region to ROI manager using Ctrl+T.");

	// save grid regions
	ROIoutdir = out+"ROIs"+File.separator;
	File.makeDirectory(ROIoutdir);
	roiManager("save", ROIoutdir+ori+".zip");
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function makeGrid(gridsize) {
	// make cell mask image
	selectImage(workingImage);
	newImage("newMask", "8-bit", getWidth, getHeight,1);
	mask = getTitle();
	roiManager("select", 0);
	run("Invert");
	roiManager("delete");

	// exclude MTOCs from mask 	
	roiManager("fill");
	roiManager("delete");

	// make grid around mask
	W_offset = (getWidth()  % WindowDisplacement) / 2;  // used to center windows around mask area
	H_offset = (getHeight() % WindowDisplacement) / 2;	// used to center windows around mask area
		
	for (x = W_offset; x < getWidth()-W_offset; x+=WindowDisplacement) {
		for (y = H_offset; y < getHeight()-H_offset; y+=WindowDisplacement) {
			makeRectangle(x, y, gridsize, gridsize);
			getStatistics(area, mean);
			if (mean == 0 && area == gridsize*gridsize)		roiManager("add");	// only add regions that are completely contained in mask (and within image borders)
		}
	}
	close(mask);
	
	selectImage(workingImage);
	run("Select None");
	roiManager("Remove Channel Info");
	roiManager("Show All without labels");
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function MeasureClustering(KTch,MTch){
	// find kinetochores
	selectImage(workingImage);
	setSlice(KTch);
	run("Find Maxima...", "prominence="+CEN_prominence+" strict exclude output=[Single Points]");
	roiManager("Show All without labels");
	spots = getTitle();
	run("Divide...", "value=255");
	setMinAndMax(0, 1);

	roiCount = roiManager("count");
	CENs = newArray(roiCount);

	for (roi = 0; roi < roiCount; roi++) {
		// count number of CEN spots
		roiManager("select",roi);
		CENs[roi] = getValue("IntDen");	
	}
	
	selectImage(workingImage);
	setSlice(MTch);
	MTint = newArray(roiCount);
	MTmedian = getValue("Median");
	for (roi = 0; roi < roiCount; roi++) {
		// measure MT intensity
		roiManager("select",roi);
		getStatistics(rawarea, rawmean);
		rawdens = rawarea*rawmean;

		if		(MTbgCorrMeth == 0)		bgsignal = 0;			// no background correction
		else if (MTbgCorrMeth == 1)		bgsignal = MTmedian;	// global background correction
		else if (MTbgCorrMeth == 2){							// local background correction (in following block)
			// measure (signal + background) MT intensity
			getSelectionBounds(x, y, w, h);
			makeRectangle(x-MT_bg_band, y-MT_bg_band, w+2*MT_bg_band, h+2*MT_bg_band);	// box for measuring bg
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
