// Set deconvolution edges cropping
CropEdges = 1;	// 1/0 == Yes/No
CropSize = 16;

// Set parameters
gridsize = 16;
WindowDisplacement = 2;	// seet notes below
ThreshType = "Huang";	//"RenyiEntropy";
GaussSigma = 40;
DilateCycles = gridsize/2;
MTbgCorrMeth = 2;	// M background method: 0 = no correction; 1 = global background (median of cropped region); 2 = local background
MT_bg_band = 2;			// width of band around grid window to measure background intensity in

// Manual interventions (set to 1 to activate)
ExcludeMTOCs = 0;


// update WindowDisplacement as per rules above
// if WindowDisplacement = 0 --> WindowDisplacement = gridsize, perfect non-overlapping grid
if (WindowDisplacement == 0)		WindowDisplacement = gridsize;
// if WindowDisplacement < 0 --> Absolute value gives the fraction of gridsize as rolling window value. E.g. -2 will give 1/2 gridsize (i.e. 50% overlap) and -4 will give 1/4 gridsize (i.e. 75% overlap)
else if (WindowDisplacement < 0){
	division = abs(WindowDisplacement);
	WindowDisplacement = (gridsize/division);
}
// if WindowDisplacement > 0 --> Displacement value of for rolling window  (1 takes kinda long, 2 is fine)

// Set channel order
DNAchannel = 1;
COROchannel = 2;
MTchannel = 3;
KTchannel = 4;



// Initialize macro for test environments
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
if (CropEdges){
	makeRectangle(CropSize, CropSize, getWidth-CropSize*2, getHeight-CropSize*2);
	run("Crop");
}


////////////////////////////////////////////////////////////////////////
// Call sequential functions
makeDNAMask(DNAchannel);
if (ExcludeMTOCs == 1) SetExcludeRegions(MTchannel);
makeGrid(gridsize);
resultArray = MeasureClustering(KTchannel,MTchannel);
////////////////////////////////////////////////////////////////////////


// print and save output
clusterList = Array.slice(resultArray,0,resultArray.length/2);
MTintensity = Array.slice(resultArray,resultArray.length/2,resultArray.length);

finish = getTime();
duration = round((finish-start)/1000);
Array.print(ori,clusterList);
Array.print(ori,MTintensity);

selectWindow("Log");
timestamp = fetchTimeStamp();
saveAs("Text", "C:/Users/dani/Dropbox (Personal)/____Recovery/Fiji.app/Custom_Codes/CenClusterQuant/results/output/Log_"+timestamp+".txt");


//print(WindowDisplacement,duration,"sec",roiManager("count"));



//waitForUser("All done");

function makeDNAMask(DNA){
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

function SetExcludeRegions(MTs){
	selectImage(workingImage);
	Stack.setChannel(MTs);
	waitForUser("select regions to exclude");
}


function makeGrid(gridsize) {
	// make cell mask image
	selectImage(workingImage);
	newImage("newMask", "8-bit", getWidth, getHeight,1);
	mask = getTitle();
	roiManager("select", 0);
	run("Invert");
	roiManager("delete");

	// make grid around mask
	W_offset = (getWidth()  % WindowDisplacement) / 2;
	H_offset = (getHeight() % WindowDisplacement) / 2;
		
	
	for (x = W_offset; x < getWidth()-W_offset; x+=WindowDisplacement) {
		for (y = H_offset; y < getHeight()-H_offset; y+=WindowDisplacement) {
			makeRectangle(x, y, gridsize, gridsize);
			getStatistics(area, mean);
			if (mean == 0 && area == gridsize*gridsize)		roiManager("add");
		}
	}

	// clean up clutter
	close(mask);
	
	selectImage(workingImage);
	run("Select None");
//	roiManager("select",0);
//	roiManager("delete");
	roiManager("Remove Channel Info");
	roiManager("Show All without labels");

}

function MeasureClustering(KTch,MTch){
	// find kinetochores
	selectImage(workingImage);
	setSlice(KTch);
	run("Find Maxima...", "prominence=150 strict exclude output=[Single Points]");
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
		else if (MTbgCorrMeth == 2){	// local background correction
			// measure (signal + background) MT intensity
			getSelectionBounds(x, y, w, h);
			makeRectangle(x-MT_bg_band, y-MT_bg_band, w+2*MT_bg_band, h+2*MT_bg_band);	// box for measuring bg
			getStatistics(largearea, largemean);
			largedens = largearea*largemean;
			
			// calculate bg signal and final signal
			bgarea = largearea - rawarea;
			bgsignal = (largedens-rawdens) / bgarea;
		}

		
		MTint[roi] = rawmean - bgsignal; // background corrected intensity
		



/*
//		following code is obsolete and slow and only exists for double checking whether measurements are correct
		// old bg calculating method
		roiManager("add");			// temporary ROI used for bg measurements
		roiManager("select", newArray(roi,roiCount));
		roiManager("XOR");			// create thin box around
		bgmean = getValue("Mean");  // background mean intensity
		old_method = rawmean-bgmean;

		// double check if result of 
		//print(bgarea,rawdens,largedens);
		E=1e8;
		old_method = round(old_method*E);
		new_method = round(MTint[roi]*E);
		if (new_method-old_method != 0){
			print(new_method/E,old_method/E);
			waitForUser(roi,(new_method-old_method)/E);
		}

		// clean up bg ROIs
		roiManager("deselect");
		roiManager("select", roiCount);
		roiManager("delete");
		MTint[roi] = rawmean;
*/

	}
	run("Select None");
	
	ResultArray = Array.concat(CENs,MTint);
	return ResultArray;
}



function fetchTimeStamp(){
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	datetimeArray = newArray(month, dayOfMonth, hour, minute);

	for (i = 0; i < datetimeArray.length; i++) {
		unit = datetimeArray[i];
		if (unit<10)	datetimeArray[i] = "0"+d2s(unit,0);
		else			datetimeArray[i] = d2s(unit,0);
	}
	year = substring(d2s(year,0),2);
	DateString = year+datetimeArray[0]+datetimeArray[1];
	TimeString = datetimeArray[2]+datetimeArray[3];

	TimeStamp = DateString+TimeString;
	
	return TimeStamp;
	//print (DateString+TimeString);
}
