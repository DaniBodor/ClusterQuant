BaseDirName = "CenClusterQuant";
image_identifier="";	// only files containing this identifier in the file name will be opened (empty string will include all)
printDIRname = 1;		// set to 0 or 1 depending on whether you want directory name printed to log
printIMname = 0;		// set to 0 or 1 depending on whether you want image name printed to log
printStartEnd = 1;		// set to 0 or 1 depending on whether you want start and end time printed to log
saveLogResults = 1;		// set to 0 or 1 depending on whether you want to save log results
non_data_prefix="##### "// printed in lines that are not data

// set up
run ("Close All");
print ("\\Clear");
dir = getDirectory ("Choose CenClusterQuant data directory");
subdirs = getFileList (dir);

// recognize own location
BaseDir = File.getParent(dir);
CurrentFolder = File.getName(BaseDir);
while (CurrentFolder != BaseDirName){
	BaseDir = File.getParent(BaseDir);
	CurrentFolder = File.getName(BaseDir);
}

// other paths required
MacroPath = BaseDir + File.separator  + "src" + File.separator + BaseDirName + ".ijm";
OutputPath = BaseDir + File.separator  + "results" + File.separator + "output"+File.separator;
print(non_data_prefix+"Running", BaseDirName, "on" , File.getName(dir));

// fetch time
timestamp = fetchTimeStamp();
if(printStartEnd==1)	print(non_data_prefix+"Start time: " +substring(timestamp,lengthOf(timestamp)-4));


// lots of loops and conditions to find correct files in correct folders

// loop through individual conditions within base data folder
for (d = 0; d < subdirs.length; d++) {
	subdirname = dir + subdirs [d];

	// check that it is indeed  folder
	if ( endsWith (subdirname, "/")){
		filelist = getFileList (subdirname);
		if (printDIRname == 1)	print("***" + File.getName(subdirname));
		
		// loop through individual images within condition-folder
		for (f = 0; f < filelist.length; f++) {
		//for (f = 0; f < 5; f++) {		// use for testing on few images
			filename = subdirname + filelist [f];

			// check that file is an image (*.tif or *.dv) abd that it contains the identifier set at the top
			if ( endsWith (filename, ".tif") || endsWith (filename, ".dv") ){
				if (indexOf(filelist [f] , image_identifier) >= 0 ){
					// correct files were found
					
					// open image and run macro
					open(filename);
					ori = getTitle();
					RunCode(ori);

					// save output
					selectWindow("Log");
					if (saveLogResults)		saveAs("Text", OutputPath+"Log_"+timestamp+".txt");

					// close and dump memory
					run ("Close All"); 	
					memoryDump(3);
				}
			}
		}
	}
}

	
// print end time if desired
if (printStartEnd == 1){
	endtime = fetchTimeStamp();
	print(non_data_prefix+"End time: " + substring(endtime, lengthOf(endtime)-4) );
}

print (non_data_prefix + "All done");
if (saveLogResults)		saveAs("Text", OutputPath + "Log_" + timestamp + ".txt");



function RunCode(IM){
	if (printIMname == 1)	print(non_data_prefix+IM);
	argument1 = OutputPath;
	argument2 = File.getName(subdirname);
	passArgument = argument1 + "#%#%#%#%" + argument2;
	runMacro(MacroPath, passArgument);
		
	//waitForUser(IM);
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function fetchTimeStamp(){
	// allows for nice formatting of datetime
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// set to readable output
	year = substring(d2s(year,0),2);
	DateString = year + IJ.pad(month+1,2) + IJ.pad(dayOfMonth,2);
	TimeString = IJ.pad(hour,2) + IJ.pad(minute,2);

	// concatenate and return
	DateTime = DateString+"_"+TimeString;
	return DateTime;
}


function memoryDump(n){
	print("memory used prior to memory dump: " + IJ.freeMemory());
	for (i = 0; i < n; i++) run("Collect Garbage");
	print("memory used after " + n + "x memory dump: " + IJ.freeMemory());
}
