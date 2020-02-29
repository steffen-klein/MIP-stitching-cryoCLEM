/*

---------------------------------------------------------------------

FIJI Macro for image stitching of files acquired with Leica cryoCLEM microscope
Copyright Chlanda Lab Heidelberg, 2018, Script by Steffen Klein

---------------------------------------------------------------------

This Macro was only tested for Unix Systems

Only for files acquired using the LAS X Screener and exported in LAS X as RAW Tif. The files need to be organized like this:
- "name"_s00_z000_RAW_ch00
- "name" is not allowed to have any spaces

---------------------------------------------------------------------

*/

// Enable batch mode
setBatchMode(true);

// Function to convert decimal to string
function d2s(number, width, character) { 
        number = toString(number); // force string 
        character = toString(character); 
        for (len = lengthOf(number); len < width; len++) 
                number = character + number; 
        return number;
}

// Setting up script
//-----------------------
	
	// Create dialog to ask to for all variables 
		// Show dialog
			Dialog.create("New Stitching for cryoCLEM");
 				Dialog.addString("Project Title:", "project_title");
 				Dialog.addString("file name (name_):", "file_name");
 				Dialog.addNumber("Number of Channels", 3);
 				Dialog.addString("Color Ch00", "Grays");
 				Dialog.addString("Color Ch01", "Magenta");
 				Dialog.addString("Color Ch02", "Green");
 				Dialog.addString("Color Ch03", "Cyan");
 				Dialog.addString("Color Ch04", "");
				Dialog.addNumber("Pixel Size", 7.6961);
 				Dialog.addNumber("Tiles X:", 3);
 				Dialog.addNumber("Tiles Y:", 3);
 				Dialog.addNumber("Z slides:", 100);
 				Dialog.addNumber("Z distance in µm:", 0.3);
 				Dialog.addNumber("Overlap (%):", 10);
 				Dialog.addChoice("Brightfield channel", newArray("00","01","02","03","04","05"));
 				Dialog.addChoice("Save Stacks", newArray("1","0"));
			Dialog.show();
		// Save dialog input to variables
			project_title = Dialog.getString();
			file_base_name = Dialog.getString();
			channel_number = Dialog.getNumber();
			ch0_color = Dialog.getString();
			ch1_color = Dialog.getString();
			ch2_color = Dialog.getString();
			ch3_color = Dialog.getString();
			ch4_color = Dialog.getString();
			pixel_size = Dialog.getNumber();
			tiles_x = Dialog.getNumber();
			tiles_y = Dialog.getNumber();
			z_slices = Dialog.getNumber();
			z_scale = Dialog.getNumber();
			overlap = Dialog.getNumber();
			bf_channel = Dialog.getChoice();
			save_stack = Dialog.getChoice();
		// Asks for  input directory with tile folders of extractet tif files from LAS X
			folder_location = getDirectory("Choose folder with  extracted tif file (name_s00_z000_RAW_ch00.tif)");	
		// Asks for output directory for processed files
			output = getDirectory("Choose output directory");

		// Calculate tile number:
			tile_number = tiles_x*tiles_y;

		// Calculate length of Z-slice number:
			actual_z_slice_number = z_slices -1;
			if (actual_z_slice_number < 10) {
				z_slice_length = 1;
			}
				else if (actual_z_slice_number < 100) {
					z_slice_length = 2;
			}
					else if (actual_z_slice_number < 1000) {
						z_slice_length = 4;
			}

	// Create all neccesary folders in output directory
		// create new folder for z-stacks
			if (save_stack==1) {
				stack_dir = output + "01_z-stacks/";
				File.makeDirectory(stack_dir);
				composite_z = output + "03_composite_z_stacks/";
				File.makeDirectory(composite_z);
			}
		// create new folder for maximim projection
			max_dir = output + "02_max_projection/";
			File.makeDirectory(max_dir);
		// create new folder for stacks
			composite_max = output + "04_composite_max_projection/";
			File.makeDirectory(composite_max);	
		// create new folder for saving stitched image
			stitching_dir = output + "/05_stitched_image/";
			File.makeDirectory(stitching_dir);

// Create stacks and maximum projection for each channel per tile
//-----------------------------------------------------------
	// Go through each tile
	for (i=0; i<tile_number; i++) {
		// Go through each channel of tile
		for (j=0; j<channel_number; j++) { 
			// Open each slices of the channels
			for (k=0; k<z_slices; k++) { 
				open(""" + folder_location + file_base_name + "_s" + d2s(i,2,0) + "_z" + d2s(k,z_slice_length,0) + "_RAW_ch" + d2s(j,2,0) + ".tif" + """);
			}
			// Create stack
				run("Images to Stack", "name=Stack title=[] use");
			// Rename stack
				rename(file_base_name + "_tile" + d2s(i,2,0) + "_ch" + d2s(j,2,0));
			if (save_stack==1) { // Check if stack should be saved'
				// Save Stack		
					saveAs("Tiff", stack_dir + file_base_name + "_tile" + d2s(i,2,0) + "_ch" + d2s(j,2,0) + ".tif");
			}
			// Rename stack
				rename(file_base_name + "_tile" + d2s(i,2,0) + "_ch" + d2s(j,2,0));
			// Create maximum projection of stack
				run("Z Project...", "projection=[Max Intensity]");		
			// Save maximum projection
				saveAs("Tiff", max_dir + file_base_name + "_tile" + d2s(i,2,0) + "_ch" + d2s(j,2,0) + "_max_projection.tif");
				close();		
			// Close stack
				selectWindow(file_base_name + "_tile" + d2s(i,2,0) + "_ch" + d2s(j,2,0));
				close();
			// Clear memory
				run("Collect Garbage");
		}
	}

	if (save_stack==1) {
	// Create a composite of Z-stacks
	//---------------------------------------
		// Go through each tile
			for (i=0; i<tile_number; i++) {
				
			//open all channels of the tile
				for (j=0; j<channel_number; j++) {
					open(stack_dir + file_base_name + "_tile" + d2s(i,2,0) + "_ch" + d2s(j,2,0) + ".tif");
				}							
			// create stack
				if (channel_number==1) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00.tif create");
				}
				if (channel_number==2) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00.tif c2=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch01.tif create");
				}
				if (channel_number==3) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00.tif c2=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch01.tif c3=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch02.tif create");
				}	
				if (channel_number==4) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00.tif c2=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch01.tif c3=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch02.tif c4=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch03.tif create");
				}
				if (channel_number==5) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00.tif c2=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch01.tif c3=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch02.tif c4=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch03.tif c5="+ file_base_name + "_tile" + d2s(i,2,0) + "_ch04.tif create");
				}

			// Go to central slice to set correct brightness
				setSlice(round(z_slices/2));

			// Set correct colors to channel and adjust brightness
				if (channel_number>=1) {
					Stack.setChannel(1) 
					run(ch0_color);
					run("Enhance Contrast...", "saturated=0.3");
				}
				if (channel_number>=2) {
					Stack.setChannel(2) 
					run(ch1_color);
					run("Enhance Contrast...", "saturated=0.3");
				}
				if (channel_number>=3) {
					Stack.setChannel(3) 
					run(ch2_color);
					run("Enhance Contrast...", "saturated=0.3");
				}	
				if (channel_number==4) {
					Stack.setChannel(4) 
					run(ch3_color);
					run("Enhance Contrast...", "saturated=0.3");
				}
				if (channel_number==5) {
					Stack.setChannel(5) 
					run(ch4_color);
					run("Enhance Contrast...", "saturated=0.3");
				}		
			// Set correct scale for Leica cryoCLEM 50x (7.6961)
				run("Set Scale...", "distance="+pixel_size+" known=1 unit=µm");
				run("Properties...", "voxel_depth="+z_scale+"");
			// Save composite
				saveAs("Tiff", composite_z + file_base_name + "_tile" + d2s(i,2,0) +  "_ch" + d2s(j,2,0) + "_composite.tif");				
				close();
			// Clear memory
				run("Collect Garbage");
		}
	}

	// Correct Brightfield channel for different exposures, this is neccesary because the Leica cryoCLEM tends to have quite different intensitiy levels for different tiles
	//------------------------------------------------------------
	
		// load all images of brightfield channel
			run("Image Sequence...", "open=["+ max_dir +"] file=ch"+bf_channel+" use");
			original_stack = getTitle;
		// Perform Bleaching Correction
			run("Bleach Correction", "correction=[Simple Ratio] background=0");
			corrected_stack = getTitle;
		// Close original stack
			selectImage(original_stack);
		// Save each file individually
			selectImage(corrected_stack);
			run("Image Sequence... ", "format=TIFF use save="+max_dir+"");
		// close original and corrected stack
			close();
			close();
		// Clear memory
			run("Collect Garbage");

	// Create a composite of all maximum projected channels
	//---------------------------------------
		// go through each tile
			for (i=0; i<tile_number; i++) {
						
			//open all channels of the tile
				for (j=0; j<channel_number; j++) {
					open(max_dir + file_base_name + "_tile" + d2s(i,2,0) + "_ch" + d2s(j,2,0) + "_max_projection.tif");
				}						
			// create stack
				if (channel_number==1) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00_max_projection.tif create");
				}
				if (channel_number==2) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00_max_projection.tif c2=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch01_max_projection.tif create");
				}
				if (channel_number==3) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00_max_projection.tif c2=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch01_max_projection.tif c3=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch02_max_projection.tif create");
				}	
				if (channel_number==4) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00_max_projection.tif c2=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch01_max_projection.tif c3=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch02_max_projection.tif c4=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch03_max_projection.tif create");
				}
				if (channel_number==5) {
					run("Merge Channels...", "c1=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch00_max_projection.tif c2=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch01_max_projection.tif c3=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch02_max_projection.tif c4=" + file_base_name + "_tile" + d2s(i,2,0) + "_ch03_max_projection.tif c5="+ file_base_name + "_tile" + d2s(i,2,0) + "_ch04_max_projection.tif create");
				}


			// Set correct colors to channel and adjust brightness
				if (channel_number>=1) {
					Stack.setChannel(1) 
					run(ch0_color);
					run("Enhance Contrast...", "saturated=0.3");
				}
				if (channel_number>=2) {
					Stack.setChannel(2) 
					run(ch1_color);
					run("Enhance Contrast...", "saturated=0.3");
				}
				if (channel_number>=3) {
					Stack.setChannel(3) 
					run(ch2_color);
					run("Enhance Contrast...", "saturated=0.3");
				}	
				if (channel_number==4) {
					Stack.setChannel(4) 
					run(ch3_color);
					run("Enhance Contrast...", "saturated=0.3");
				}
				if (channel_number==5) {
					Stack.setChannel(5) 
					run(ch4_color);
					run("Enhance Contrast...", "saturated=0.3");
				}
			
			// Set correct scale for Leica cryoCLEM 50x (7.6961)
				run("Set Scale...", "distance="+pixel_size+" known=1 unit=µm");

			// Save composite
				saveAs("Tiff", composite_max + file_base_name + "_tile" + d2s(i,2,0) + "_max_projection_composite.tif");
				close();

			// Clear memory
				run("Collect Garbage");
			}

	// Perform actual stitching
	//---------------------------------
	// Run stitching
		run("Grid/Collection stitching", "type=[Grid: snake by rows] order=[Right & Down                ] grid_size_x="  + tiles_x + " grid_size_y=" + tiles_y + " tile_overlap=" + overlap + " first_file_index_i=0 directory=" + composite_max + " file_names=" + file_base_name + "_tile{ii}_max_projection_composite.tif output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 add_tiles_as_rois compute_overlap ignore_z_stage subpixel_accuracy computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
	// Save ROI to file and delete from image
		run("ROI Manager...");
		run("Select All");
		roiManager("Save", stitching_dir + project_title + "_tiles_ROIset.zip");
		run("ROI Manager...");
		roiManager("Show None");
	// hide ROIs
		run("Remove Overlay");
	// Set correct colors to channel and adjust brightness
		if (channel_number>=1) {
			Stack.setChannel(1) 
			run(ch0_color);
			run("Enhance Contrast...", "saturated=0.3");
		}
		if (channel_number>=2) {
			Stack.setChannel(2) 
			run(ch1_color);
			run("Enhance Contrast...", "saturated=0.3");
		}
		if (channel_number>=3) {
			Stack.setChannel(3) 
			run(ch2_color);
			run("Enhance Contrast...", "saturated=0.3");
		}	
		if (channel_number==4) {
			Stack.setChannel(4) 
			run(ch3_color);
			run("Enhance Contrast...", "saturated=0.3");
		}
		if (channel_number==5) {
			Stack.setChannel(5) 
			run(ch4_color);
			run("Enhance Contrast...", "saturated=0.3");
		}		
	// Set correct scale for Leica cryoCLEM 50x (7.6961)
		run("Set Scale...", "distance="+pixel_size+" known=1 unit=µm");		
	// save and close file
		saveAs("Tiff", stitching_dir + project_title);
		close();
	// Clear memory
		run("Collect Garbage");		

	// 02 - Create serialEM Navigator file
	//----------------------
	// not there yet...

// Disable Batch mode
setBatchMode(false);
