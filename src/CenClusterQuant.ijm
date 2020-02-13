cropEdges = 0;
cropsize = 16;
gridsize = 16;

DNAchannel = 1;
COROchannel = 2;
MTchannel = 3;
KTchannel = 4;

ThreshType = "Huang";	//"RenyiEntropy";
Gauss_sigma = 40;


makeRectangle(cropsize, cropsize, getWidth-cropsize*2, getHeight-cropsize*2);
if (cropEdges)	run("Crop");


roiManager("reset");
MAIN = getTitle();

makeGrid(gridsize);
makeSlidingWindow();
makeDNAMask(DNAchannel);
findKinetochores(KTchannel);
makeMeasurements


function makeGrid(gridsize) {
	selectImage(MAIN);
	H0 = (getHeight() % gridsize) / 2;
	W0 = (getWidth()  % gridsize) / 2;
	for (i = W0; i < getWidth()-W0; i+=gridsize) {
		for (j = H0; j < getHeight()-H0; j+=gridsize) {
			makeRectangle(j, i, gridsize, gridsize);
			roiManager("add");
/*			for (k = 1; k <= nSlices; k++) {
				setSlice(k);
				run("Measure");
			}
*/
		}
	}
	roiManager("Remove Channel Info");
	roiManager("Remove Slice Info");
	roiManager("Remove Frame Info");
}

function makeDNAMask(DNA){
	// prep images
	selectImage(MAIN);
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
	selectImage(MAIN);
	setSlice(KT);
	

	run("Find Maxima...", "prominence=150 strict exclude output=[Single Points]");
}





