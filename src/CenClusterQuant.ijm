// Set deconvolution edges cropping
cropEdges = 0;	// 1/0 == Yes/No
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


// Crop off deconvolution edges
if (cropEdges){
	makeRectangle(cropsize, cropsize, getWidth-cropsize*2, getHeight-cropsize*2);
	run("Crop");
}

// Initialize macro
ori = getTitle();
Stack.getDimensions(width, height, channels, slices, frames);
run("Properties...", "channels=" + channels + " slices=" + slices + " frames=" + frames + " unit=pix pixel_width=1 pixel_height=1 voxel_depth=0");
roiManager("reset");


// Call sequential functions
makeGrid(gridsize);
//makeSlidingWindow();
makeDNAMask(DNAchannel);
//findKinetochores(KTchannel);
//makeMeasurements


function makeGrid(gridsize) {
	selectImage(ori);
	H_offset = (getHeight() % gridsize) / 2;
	W_offset = (getWidth()  % gridsize) / 2;
	for (x = W_offset; x < getWidth()-W_offset; x+=gridsize) {
		for (y = H_offset; y < getHeight()-H_offset; y+=gridsize) {
			makeRectangle(x, y, gridsize, gridsize);
			roiManager("add");
		}
	}
	run("Select None");
	
	roiManager("Remove Channel Info");
	roiManager("Remove Slice Info");
	roiManager("Remove Frame Info");
}

function makeDNAMask(DNA){
	// prep images
	selectImage(ori);
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
	for (i = 0; i < 9; i++) 	run("Dilate");	
}


function findKinetochores(KT){
	selectImage(ori);
	setSlice(KT);
	

	run("Find Maxima...", "prominence=150 strict exclude output=[Single Points]");
}





