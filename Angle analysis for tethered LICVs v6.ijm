tifName = getTitle();
dir1 = getDirectory("image");
Name = replace(tifName, ".czi", "");///////////////////////////////////////////
getDimensions(width, height, channels, slices, frames);
rename("Raw");
run("Duplicate...", "title=Result");
selectWindow("Raw");
run("Set Scale...", "distance=0 known=0 unit=pixel");
resolutionF = 2;
FWidth = resolutionF * width;
FHeight = resolutionF * height;
Fsize = resolutionF * 28
selectWindow("Result");
run("Size...", "width=FWidth height=FHeight depth=1 constrain average interpolation=Bilinear");

//Mito identification
	//Get ridge of mito
		selectWindow("Raw");
		run("Gaussian Blur...", "sigma=1");	
		run("Size...", "width=FWidth height=FHeight depth=1 constrain average interpolation=Bilinear");
		run("Duplicate...", "title=BG");
		selectWindow("BG");
		run("Gaussian Blur...", "sigma=5");
		imageCalculator("Subtract", "Raw","BG");
		selectWindow("BG");
		close();
		selectWindow("Raw");	
		run("8-bit");
		//run("Auto Local Threshold", "method=Phansalkar radius=5 parameter_1=0 parameter_2=0 white");
		run("Auto Local Threshold", "method=Sauvola radius=3 parameter_1=0 parameter_2=0 white");
		run("Find Maxima...", "prominence=10 light output=[Segmented Particles]");
		rename("Ridge");

	//Get junction points of each mito
		selectWindow("Ridge");
		setThreshold(129, 255);
		run("Analyze Particles...", "size=Fsize-Infinity exclude add");
		newImage("Junction", "8-bit black", FWidth, FHeight, 1);
		c = roiManager("count");
		if (c>=2) {
			for (i = 0; i < c; i++) {
				selectWindow("Junction");
				roiManager("select", i);
				run("Enlarge...", "enlarge=1");
				run("Draw", "slice");
			}
			run("Select None");	
			/*roiManager("deselect");
			roiManager("delete");*/
			selectWindow("Junction");
			setThreshold(2, 255);
			run("Convert to Mask");
			run("Skeletonize");
			run("Analyze Skeleton (2D/3D)", "prune=none");
			selectWindow("Junction");
			close();
			selectWindow("Tagged skeleton");
			setThreshold(70, 70);
			run("Convert to Mask");
			selectWindow("Tagged skeleton");
			rename("Junction");
			run("Clear Results");
			//run("Analyze Particles...", "size=0-Infinity exclude add");
		}
		else{
			print("Less than two mito are detected.");
		}

	//Label each mito	
		a = roiManager("count");
		for (i = 0; i < a; i++) {
			roiManager("select", i);
			//run("Convex Hull");
			roiManager("Add");
		}
		for (i = 0; i < a; i++) {
			roiManager("select", 0);
			roiManager("Delete");
		}
		newImage("Mito label", "32-bit black", FWidth, FHeight, 1);
		for (i = 0; i < a; i++) {
			selectWindow("Mito label");
			roiManager("select", i);
			lb = i+1;
			run("Add...", "value=lb");
		}
		roiManager("Deselect");
		roiManager("Delete");
		run("Select None");
		setThreshold(1.0000, 1000000000000000000000000000000.0000);
		run("NaN Background");
	//Clear 
		selectWindow("Raw");
		close();
		selectWindow("Ridge");
		close();
		
//Measure angle
	//Get centroid of junction when two mito are detected. If not, increase the search area. If more than 2 mito are detected, delete it in the list.
		//Get array of center for each juntion
			selectWindow("Junction");
			run("Select None");
			roiManager("Show All without labels");
			roiManager("Show None");
			setThreshold(129, 255);
			run("Set Measurements...", "centroid redirect=None decimal=1");
			run("Analyze Particles...", "display exclude add");//ROI of enlarged Junctions
			c = roiManager("count");
			ArrayVx = newArray(0);
			ArrayVy = newArray(0);
			for (i = 0; i < c; i++) {
				X = getResult("X", i);
				Y = getResult("Y", i);
				ArrayVx = Array.concat(ArrayVx, X);
				ArrayVy = Array.concat(ArrayVy, Y);
			}
			//Array.print(ArrayVx);/////////////////////////////////////////////////////////////////////////////////////////////cp
			//Array.print(ArrayVy);/////////////////////////////////////////////////////////////////////////////////////////////cp
			run("Clear Results");
		//If less than two mito are detected, increase the search area.
			selectWindow("Mito label");
			setThreshold(-1000000000000000000000000000000.0000, 1000000000000000000000000000000.0000);
			c = roiManager("count");
			for (i = 0; i < c; i++) {
				selectWindow("Mito label");
				roiManager("select", i);
				run("Analyze Particles...", "display");
				n = nResults;
				//print(i, n , c);////////////////////////////////////////////////////////////////////////////////////////////cp
				if (n<2) {
					roiManager("select", i);
					run("Enlarge...", "enlarge=2");
					roiManager("Update");
					run("Clear Results");
				}
			}
		//If more than three mito are detected, delete it from the roi list and the arrays of center.		
			for (i = 0; i < c; i++) {
				selectWindow("Mito label");
				roiManager("select", i);
				run("Analyze Particles...", "display");
				n = nResults;
				//print(i, n , c);////////////////////////////////////////////////////////////////////////////////////////////cp
				if (n>=3) {
					roiManager("select", i);
					roiManager("delete");
					ArrayVx = Array.deleteIndex(ArrayVx, i);
					ArrayVy = Array.deleteIndex(ArrayVy, i);
					i = i -1;
					c = c -1;
					run("Clear Results");
				}
				else{
					run("Clear Results");
				}
			}
			//Array.print(ArrayVx);////////////////////////////////////////////////////////////////////////////////////////////cp
			//Array.print(ArrayVy);////////////////////////////////////////////////////////////////////////////////////////////cp
			selectWindow("Junction");
			//close();
			selectWindow("Mito label");
			resetThreshold();
			roiManager("Show None");
	//Get mito pair
		//Get the centroid of junction and the mito pair
			run("Set Measurements...", "min centroid redirect=None decimal=1");
			selectWindow("Mito label");
			roiManager("Show All");
			roiManager("Measure");
			Table.renameColumn("Min", "Mitopair A");
			Table.renameColumn("Max", "Mitopair B");
			//Table.renameColumn("X", "Vx");
			//Table.renameColumn("Y", "Vy");
			//Array.print(ArrayVx);////////////////////////////////////////////////////////////////////////////////////////////cp
			//Array.print(ArrayVy);////////////////////////////////////////////////////////////////////////////////////////////cp
			Table.setColumn("Vx", ArrayVx);
			Table.setColumn("Vy", ArrayVy);
			Table.rename("Results", "Junction point");
	//Measure the coordinates of the other two points to get the angle of interest
		n = Table.size;
		for (i = 0; i < n; i++) {///////////////////////////////////////////////////////////////////////////////////////////// 0 n*************************************
			selectWindow("Junction point");
			mito1 = Table.get("Mitopair A", i);
			mito2 = Table.get("Mitopair B", i);
			Vx = Table.get("Vx", i);
			Vy = Table.get("Vy", i);
			if (mito1 != mito2) {
				//Get mito pair mask
					selectWindow("Mito label");
					roiManager("Show None");
					setThreshold(mito1, mito1);
					run("Create Selection");
					run("Convex Hull");
					run("Enlarge...", "enlarge=1");
					run("Create Mask");
					selectWindow("Mask");
					rename("mask1");
					selectWindow("Mito label");
					setThreshold(mito2, mito2);
					run("Create Selection");
					run("Convex Hull");
					run("Enlarge...", "enlarge=1");
					run("Create Mask");
					selectWindow("Mask");
					rename("mask2");	
					imageCalculator("OR create", "mask1","mask2");
					selectWindow("Result of mask1");
					rename("Mito pair mask");
					selectWindow("mask1");
					close();
					selectWindow("mask2");
					close();
				//Get mito pair convex hull mask
					selectWindow("Mito pair mask");
					setThreshold(129, 255);
					run("Create Selection");
					run("Convex Hull");
					newImage("Convex Hull", "8-bit black", FWidth, FHeight, 1);
					run("Restore Selection");
					setForegroundColor(255, 255, 255);
					run("Fill", "slice");
					
					
					
					
					
					
				//Get triangle of each junction
					imageCalculator("Subtract create", "Convex Hull","Mito pair mask");
					selectWindow("Result of Convex Hull");
					setThreshold(129, 255);
					run("Set Measurements...", "centroid feret's redirect=None decimal=1");
					run("Analyze Particles...", "size=6-Infinity display exclude");
				//Get the closest triangle to the junction point
						selectWindow("Results");
						m = Table.size;
						ArrayDt = newArray(0);
						for (j = 0; j < m; j++) {
							testerX = getResult("X", j);
							testerY = getResult("Y", j);
							dt = sqrt(((Vx - testerX) * (Vx - testerX) + (Vy - testerY) * (Vy-testerY)));
							selectWindow("Results");
							Table.set("Distance to vertex", j, dt);
							ArrayDt = Array.concat(ArrayDt,dt);
							b = lengthOf(ArrayDt);
						}
						//Array.print(ArrayDt);
						if (b >1) {
							MinId = Array.findMinima(ArrayDt, 0);
							//Array.print(MinId);
							MinId = MinId[0];
						}
						if (b ==1) {
							MinId = 0;
						}
				 	//Calculate data	
						selectWindow("Results");
						P2x = getResult("FeretX", MinId);
						P2y = getResult("FeretY", MinId);
						P2FeretAngle = getResult("FeretAngle", MinId);
						P2Feret = getResult("Feret", MinId);
                        //DisToVertex2 = getResult("Distance to vertex", MinId);
                        DisToVertex2 = sqrt((P2x-Vx)*(P2x-Vx)+(P2y-Vy)*(P2y-Vy));
						P2FeretAngleInRad = P2FeretAngle *(PI/180);
						if(P2FeretAngle<90){
							P3x = P2x + P2Feret * cos(P2FeretAngleInRad);
							P3y = P2y - P2Feret * sin(P2FeretAngleInRad);
						}
						if(P2FeretAngle>90){
							P2FeretAngle = 180- P2FeretAngle;
							P2FeretAngleInRad = P2FeretAngle *(PI/180);
							P3x = P2x + P2Feret * cos(P2FeretAngleInRad);
							P3y = P2y + P2Feret * sin(P2FeretAngleInRad);
						}
						DisToVertex3 = sqrt((Vx - P3x)*(Vx - P3x)+ (Vy-P3y)*(Vy-P3y));
						InterestAngle = acos((P2Feret * P2Feret - DisToVertex2 * DisToVertex2 -DisToVertex3 * DisToVertex3)/(-2*DisToVertex2*DisToVertex3))*(180/PI);
						selectWindow("Junction point");
						Table.set("Distance between P2 to vertex", i, DisToVertex2);
						Table.set("P2x", i, P2x);
						Table.set("P2y", i, P2y);
						Table.set("FeretAngle from P2", i, P2FeretAngle);
						Table.set("Feret from P2", i, P2Feret);
						Table.set("P3x", i, P3x);
						Table.set("P3y", i, P3y);
						Table.set("Distance between P3 to vertex", i, DisToVertex3);
						Table.set("Interest Angle", i, InterestAngle);
						
						

				//Clear
					
					selectWindow("Convex Hull");
					close();
					selectWindow("Mito pair mask");
					close();
					selectWindow("Result of Convex Hull");
					close();
					run("Clear Results");
			}
		}
		selectWindow("Junction point");
		saveAs("Results", dir1 + File.separator + "Junction point.csv");
		roiManager("Deselect");
		roiManager("Delete");
		selectWindow("Junction point.csv");
		run("Close");
//Draw result image1
	//newImage("Result", "8-bit black", width, height, 1);
	selectWindow("Mito label");
	run("Select None");
	resetThreshold();
	setMinAndMax(0, 4);
	run("RGB Color");
	selectWindow("Result");
	run("RGB Color");
	run("Set Measurements...", "shape redirect=None decimal=1");
	open(dir1 + File.separator + "Junction point.csv");
	selectWindow("Junction point.csv");
	o = Table.size;
	for (i = 0; i < o; i++) {////////////////////////////////////////////////////////////////0 o
    	RArray= newArray(255, 255, 255, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 255);
    	GArray= newArray(0, 129, 255, 255, 0, 255, 0, 0, 129, 255, 255, 0, 255, 0);
    	BArray= newArray(0, 0, 0, 0, 255, 255, 220, 0, 0, 0, 0, 255, 255, 220);
    	setForegroundColor(RArray[i], GArray[i], BArray[i]);
    	selectWindow("Junction point.csv");
    	mito1 = Table.get("Mitopair A", i);
		mito2 = getResult("Mitopair B", i);
		if (mito1 != mito2) {
	    	Vx = getResult("Vx", i);
			Vy = getResult("Vy", i);
			P2x = getResult("P2x", i);
			P2y = getResult("P2y", i);
			P3x = getResult("P3x", i);
			P3y = getResult("P3y", i);
			//Draw mito label
				selectWindow("Mito label");
				fillRect(Vx, Vy, 1, 1);
				fillRect(P2x, P2y, 1, 1);
				fillRect(P3x, P3y, 1, 1);
			//Draw result
				selectWindow("Result");
				run("Specify...", "width=1 height=1 x=Vx y=Vy");
				run("Fill", "slice");
				run("Specify...", "width=1 height=1 x=P2x y=P2y");
				run("Fill", "slice");
				run("Specify...", "width=1 height=1 x=P3x y=P3y");
				run("Fill", "slice");
			//Measure angle directly
				makeSelection("angle",newArray(P2x,Vx,P3x),newArray(P2y,Vy,P3y));
				run("Measure");
				selectWindow("Results");
				Angle = getResult("Angle", 0);
				selectWindow("Junction point.csv");
				Table.set("Angle measured", i, Angle);
				selectWindow("Results");
				run("Clear Results");
				selectWindow("Result");
				run("Select None");
		}
    }
    selectWindow("Junction point.csv");
	Table.renameColumn("Mitopair A", "LICV A");
	Table.renameColumn("Mitopair B", "LICV B");
 	saveAs("Results", dir1 + File.separator + "Junction point.csv");