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
roiManager("reset");


// Call sequential functions
makeGrid(gridsize);
//makeSlidingWindow();
//makeDNAMask(DNAchannel);
//findKinetochores(KTchannel);
//makeMeasurements


function makeGrid(gridsize) {
	selectImage(ori);
	H0 = (getHeight() % gridsize) / 2;
	W0 = (getWidth()  % gridsize) / 2;
	for (i = W0; i < getWidth()-W0; i+=gridsize) {
		for (j = H0; j < getHeight()-H0; j+=gridsize) {
			makeRectangle(j, i, gridsize, gridsize);
			roiManager("add");
		}
	}
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
	getTitle() = mask;


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
	
	// dilate
	run("Erode");
	for (i = 0; i < 9; i++) 	run("Dilate");	
}


function findKinetochores(KT){
	selectImage(ori);
	setSlice(KT);
	

	run("Find Maxima...", "prominence=150 strict exclude output=[Single Points]");
}





