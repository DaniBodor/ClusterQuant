// Set deconvolution edges cropping
cropEdges = 1;	// 1/0 == Yes/No
cropsize = 16;

// Set parameters
gridsize = 16;
ThreshType = "Huang";	//"RenyiEntropy";
Gauss_sigma = 40;

// Set channel order
DNAchannel = 1;
COROchannel = 2;
MTchannel = 3;
KTchannel = 4;


/*
// Initialize macro for test environments
selectImage(1);

run("Select None");
run("Brightness/Contrast...");

close("\\Others");
roiManager("reset");

Stack.getDimensions(width, height, channels, slices, frames);
run("Properties...", "channels=" + channels + " slices=" + slices + " frames=" + frames + " unit=pix pixel_width=1 pixel_height=1 voxel_depth=0");
run("Set Measurements...", "area mean min center feret's integrated redirect=None decimal=3");
*/



// Crop off deconvolution edges
ori = getTitle();
Stack.getDimensions(width, height, channels, slices, frames);
run("Properties...", "channels=" + channels + " slices=" + slices + " frames=" + frames + " unit=pix pixel_width=1 pixel_height=1 voxel_depth=0");
run("Set Measurements...", "area mean min center feret's integrated redirect=None decimal=3");

run("Duplicate...", "duplicate");
workingImage = getTitle();
if (cropEdges){
	makeRectangle(cropsize, cropsize, getWidth-cropsize*2, getHeight-cropsize*2);
	run("Crop");
}




// Call sequential functions
makeDNAMask(DNAchannel);
makeGrid(gridsize);
clusterList = MeasureClustering(KTchannel,MTchannel);

// plot histo of centromere numbers in grid
/*Plot.create("CEN histogram", "Number of centromeres", "count")
Plot.addHistogram(clusterList, 1);
Plot.show();
*/
Array.print(ori,clusterList);


//makeSlidingWindow();	// update from makeGrid


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
	run("Gaussian Blur...", "sigma=" + Gauss_sigma);
	imageCalculator("Subtract", mask,blur);
	close(blur);
*/

	// make mask
	setAutoThreshold(ThreshType+" dark");
	run("Convert to Mask");
	run("Erode");
	for (i = 0; i < (gridsize); i++) 	run("Dilate");
//	for (i = 0; i < 24; i++) 	run("Dilate");

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
	
	//roiManager("reset");
	close(mask);
}


function makeGrid(gridsize) {
	// make cell mask image
	selectImage(workingImage);
	newImage("newMask", "8-bit", getWidth, getHeight,1);
	mask = getTitle();
	roiManager("select", 0);
	run("Invert");

	// make grid around mask
	W_offset = (getWidth()  % gridsize) / 2;
	H_offset = (getHeight() % gridsize) / 2;
	for (x = W_offset; x < getWidth()-W_offset; x+=gridsize) {
		for (y = H_offset; y < getHeight()-H_offset; y+=gridsize) {
			makeRectangle(x, y, gridsize, gridsize);
			getStatistics(area, mean);
			if (mean == 0)		roiManager("add");
		}
	}

	// clean up clutter
	close(mask);
	
	selectImage(workingImage);
	run("Select None");
	roiManager("select",0);
	roiManager("delete");
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

	CENs = newArray(roiManager("count"));
	for (roi = 0; roi < roiManager("count"); roi++) {
		roiManager("select",roi);
		run("Measure");
		CENs[roi] = getResult("IntDen");
	}
	run("Select None");
	
	return CENs;
}



