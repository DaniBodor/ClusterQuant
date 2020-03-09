MacroName = "CenClusterQuant";
image_identifier="PRJ";	// only files containing this identifier in the file name will be opened (empty string will include all)
printDIRname = 1;		// set to 0 or 1 depending on whether you want directory name printed to log
printIMname = 0;		// set to 0 or 1 depending on whether you want image name printed to log
printStartEnd = 1;		// set to 0 or 1 depending on whether you want start and end time printed to log
saveLogResults = 0;		// set to 0 or 1 depending on whether you want to save log results
non_data_prefix="##### "// printed in lines that are not data

// set up
run ("Close All");	print ("\\Clear");
dir = getDirectory ("Choose CenClusterQuant main directory");

// recognize own location
BaseDir = File.getParent(dir);
CurrentFolder = File.getName(BaseDir);
while (CurrentFolder != MacroName){
	BaseDir = File.getParent(BaseDir);
	CurrentFolder = File.getName(BaseDir);
}
// other paths required
MacroPath = BaseDir + File.separator  + "src" + File.separator + MacroName + ".ijm";
OutputPath = BaseDir + File.separator  + "results" + File.separator + "output"+File.separator;
print(non_data_prefix+"Running", MacroName, "on" , File.getName(dir));

timestamp = fetchTimeStamp();
if(printStartEnd==1)	print(non_data_prefix+"Start time: " +substring(timestamp,lengthOf(timestamp)-4));

subdirs = getFileList (dir);


// lots of loops and conditions to find correct files in correct folders
for (d = 0; d < subdirs.length; d++) {
	subdirname = dir + subdirs [d];
	if ( endsWith (subdirname, "/")){
		filelist = getFileList (subdirname);
		if (printDIRname == 1)	print("***" + File.getName(subdirname));
		for (f = 0; f < filelist.length; f++) {
		//for (f = 0; f < 5; f++) {
			filename = subdirname + filelist [f];
			if ( endsWith (filename, ".tif") || endsWith (filename, ".dv") ){
				if (indexOf(filelist [f] , image_identifier) >= 0 ){
					// correct files were found
					
					//print(non_data_prefixfilename);
					open ( filename );
					ori = getTitle ();
					
					RunCode (ori);
					
					run ("Close All"); 	
					for (i = 0; i < 3; i++) run("Collect Garbage");

					// save output
					selectWindow("Log");
					if (saveLogResults)		saveAs("Text", OutputPath+"Log_"+timestamp+".txt");
				}
			}
		}
	}
}


// print end time if desired
if(printStartEnd==1){
	endtime = fetchTimeStamp();
	print(non_data_prefix+"End time: " +substring(endtime,lengthOf(endtime)-4));
}
print (non_data_prefix+"All done");
saveAs("Text", OutputPath+"Log_"+timestamp+".txt");




function RunCode(IM){
	if (printIMname == 1)	print(non_data_prefix+IM);
	//fullMacroFileLocation = MacroPath + File.separator + MacroName + ".ijm";
	runMacro(MacroPath,OutputPath);
	
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
	DateTime = DateString+TimeString;
	return DateTime;
}
