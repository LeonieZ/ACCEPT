%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Example of batch mode for GUI Testing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%run ACCEPT in command line interface mode with a specified input path.
batchmodeInstance=ACCEPT('cli'); % default is test_images

%load sample and save it to currentSample
currentSample = batchmodeInstance.io.load_next_sample();

%go to the next one and save again
batchmodeInstance.currentSample = batchmodeInstance.io.load_next_sample();

%information about the current data frame (z = 7)
frame=batchmodeInstance.io.loader.load_data_frame(7);

%show locations of all ctcs, show the first row
batchmodeInstance.currentSample.priorLocations(1,:)



