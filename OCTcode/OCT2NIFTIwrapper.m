function OCTNIFTIout=OCT2NIFTIwrapper(path2RawSubjectCSV,path2CentroidFile)
%OCTNIFTIout=OCT2NIFTIwrapper(path2RawSubjectCSV,path2CentroidFile)
%
%  This function converts a ******* [company name]  ***** [format] raw data
%  output to an ad hoc nifti file.  Includes an affine transform for
%  alignment purposes.  Uses standard nifti_tools resources.  In essence,
%  this is the equivalent of an ACPC alignment for ******* [company name]
%  ***** [format] raw data using the centroid data in [path2CentroidFile]
%  as the specification of the ACPC origin.
%
%  INPUTS
%
%  - path2RawSubjectCSV:  Path to this subject's raw csv output from
%     ******* [company name]  ***** [format], will be parsed by parseCsvExport
%
%  - path2CentroidFile= path to the CSV file containing the data indicating
%     the centroid? of the eye
%
%  OUTPUTS
%
%  OCTNIFTIout:  an ad hoc nifti with the X dimension corresponding to
%  ******* [company name]  ***** [format] position data, Y to slice data,
%  and Z to layer data.  The equivalent of the ACPC origin is the centroid
%  in path2CentroidFile for the specified subject
%
%EXAMPLE DATA PATHS
%path2RawSubjectCSV='/N/u/dnbulloc/Carbonate/OCT_Data/Data/001_OD_T.csv';
%path2CentroidFile='/N/u/dnbulloc/Carbonate/OCT_Data/Location/Location.csv';
%% Begin Code

%get current subject/eye ID
[~,currSubjFile,~]=fileparts(path2RawSubjectCSV);

%load centroidCsv
centroidTable=readtable(path2CentroidFile);

%get centroid slice from table (Y centroid); it's kind of like pandas
centroidSlice=centroidTable{find(strcmp(currSubjFile,centroidTable.Filename)),'slice'};
%same for position (X centroid)
centroidPosition=centroidTable{find(strcmp(currSubjFile,centroidTable.Filename)),'position'};

%use parseCsvExport to create nifti Data structure
niftiDataStruc=parseCsvExport(path2RawSubjectCSV);

%make a nifti from this
%nii = make_nii(img, [voxel_size], [origin], [datatype], [description])

%HUGE ASSUMPTION:  we're going to initialize this as isometric, even though
%its not actually, we won't be doing rotations, so this will probably be
%fine
voxel_size=[1,1,1];

%we're basing the orign off of the x and y centroid, and just arbitrarily
%setting the Z centroid at 1, as this is the first data entry in that
%dimension
origin=[centroidPosition,centroidSlice,1];

%Create a nifit from this information
%NOTE: this doesn't actually appear to be taking in the origin information
%appropriately, debug this at a later point.
OCTNIFTIout = make_nii(niftiDataStruc, voxel_size, origin);

%temporary workaround:
%because the nifti_tools package doesn't seem to set the header right, here
%we do it manually.

OCTNIFTIout.hdr.hist.qoffset_x = centroidPosition;
OCTNIFTIout.hdr.hist.qoffset_y = centroidSlice;
OCTNIFTIout.hdr.hist.qoffset_z = 1;
OCTNIFTIout.hdr.hist.srow_x = [voxel_size(1) 0 0 centroidPosition];
OCTNIFTIout.hdr.hist.srow_y = [0 voxel_size(2) 0 centroidSlice];
OCTNIFTIout.hdr.hist.srow_z = [0 0 voxel_size(3) 1];

end
