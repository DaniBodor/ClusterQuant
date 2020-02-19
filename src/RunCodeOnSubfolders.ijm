
MacroPath = "C:\\Users\\dani\\Dropbox (Personal)\\____Recovery\\Fiji.app\\Custom_Codes\\CenClusterQuant\\src";
MacroName = "CenClusterQuant.ijm";
printDIRname = 1;		// set to 0 or 1 depending on whether you want directory name printed to log
printIMname = 0;		// set to 0 or 1 depending on whether you want image name printed to log
printStartEnd = 1;		// set to 0 or 1 depending on whether you want start and end time printed to log


// set string identifier of images to include. Only files containing this identifier in the file name will be opened (empty string will include all)
image_identifier	= "D3D_PRJ";


run ("Close All");	print ("\\Clear");
dir = getDirectory ("Choose a Directory");
print(MacroName, "==>" , dir);

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
if(printStartEnd==1)	print("start time",hour+":"+minute);


subdirs = getFileList (dir);
for (d = 0; d < subdirs.length; d++) {
	subdirname = dir + subdirs [d];
	if ( endsWith (subdirname, "/")){
		filelist = getFileList (subdirname);
		if (printDIRname == 1)	print(subdirname);
		for (f = 0; f < filelist.length; f++) {
			filename = subdirname + filelist [f];
			if ( endsWith (filename, ".tif") || endsWith (filename, ".dv") ){
				if (indexOf(filelist [f] , image_identifier) >= 0 ){
					//print(filename);
					open ( filename );
					ori = getTitle ();
					RunCode (ori);
					run ("Close All"); 	
					for (i = 0; i < 3; i++) run("Collect Garbage");
				}
			}
		}
	}
}
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

if(printStartEnd==1){
	if (minute < 10)	minute = "0"+d2s(minute,0);
	print("end time",IJ.pad(hour,2)+":"+IJ.pad(minute,2));
}
print ("All done");

function RunCode(IM){
	if (printIMname == 1)	print(IM);
	fullMacroFileLocation = MacroPath + File.separator + MacroName;
	runMacro(fullMacroFileLocation);
	
	//waitForUser(IM);
	
}