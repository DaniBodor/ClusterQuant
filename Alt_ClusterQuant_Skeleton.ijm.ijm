box = 16;

print("\\Clear");
run("Select None");

setThreshold(1, 255)
run("Analyze Particles...", "display clear add");
roiManager("Show None");

for (i = 0; i < roiManager("count"); i++) {
	roiManager("select", i);
	getSelectionBounds(x, y, width, height);
	makeRectangle(x-box/2, y-box/2, box+1, box+1);
	roiManager("update");
	print(getValue("IntDen"));
}
