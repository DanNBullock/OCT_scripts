This is a guide for converting a group-level directory structure into a subject-level directory structure for Voxeleron OCT data. The overall goal of this scripting is to permit a conversion between a standard local directory structure, into a directory structure that is compatible with brainlife.io

To begin, let us describe the presumed structure of the input:

# Input structuring

There are two primary input categories for createRawOCTSubjectDirectoryStructure (note that input variable targetOutputDir merely specifies the output directory path). These two input categories are [rawVoxelronData] and [centroidData]. Note that those names ([rawVoxelronData] and [centroidData]) do not correspond to the actual input variable names (subjDataDir andcentroidCSVPath) , nor do the categories actually respond to the actual input entity, but rather the data category that is being passed by those variables.

Next we describe the actual format and content of these inputs

## Voxelron data directory

The data input via the subjDataDir variable corresponds to the Voxelron OCT data. The subjDataDir variable is, as described by the createRawOCTSubjectDirectoryStructure function documentation:

subjDataDir: The directory that contains the subject/eye specific data. Should contain no files other than the relevant CSVs. Directory can contain sub-directories, though this function will not search for files within them.

Each file contained within the subjDataDir is presumed to adhere to the following format [numerical subject ID]\_[Eye Indicator]\_[someFileLeaf]. That is, the characters preceding the first underscore are presumed to indicate the subject number (which is an integer). After this first underscore there is the eye indicator, which is either OS or OD (OS for left, OD for right). This eye indicator is then followed by another underscore. Further naming features (i.e. to the right of the second underscore) are ignored. This file is expected to be a csv. The actual content of these objects is presumed to be the raw output of the Voxelron OCT and thus compatible with the parseCsvExport function.

Thus &#39;000\_OD\_T.csv&#39;, &#39;10000\_OS\_.csv&#39; and &#39;1\_OS\_Whatever.csv&#39; are all valid input file names, but &#39;subject1\_OD\_T.csv&#39;, &#39;10000\_OS.csv&#39; and &#39;1\_Whatever\_OS.csv&#39; are not.

## Centroid CSV

Unlike the subjDataDir variable, which is a directory, the centroidCSVPath is is just that, a path to a csv file. Specifically, it is a path to a csv minimally containing the following headings:

| Filename | slice | position |
| --- | --- | --- |

Wherein Filename corresponds to the file name of the csv that the slice and position indicate the matrix index of this foveal centre in the Voxelron OCT output CSV structure.

NOTE: Each file in subjDataDir should be accounted for in this csv file. This function will error if this is not the case.

(the following description of how to compute the position relates to preprocessing that can/should be done prior to use of this conversion function)

> Assuming that you have a csv table arranged thusly:
> 
> | Filename | Eye | slice | position | Size X pixel | Size x mm | Position on HEE |
> | --- | --- | --- | --- | --- | --- | --- |
> 
> Size X pixels and X mm are determined by the OCT scan parameters and may be identical across all images. On the OCT software, such as Heidelberg, identify the foveal centre in the original image. Record the slice this is found in. The final column contains the precise X location of the foveal centre. The pixel index (position) is then calculated by (SizeXpixel / SizeXmm) \* Position on HEE.

# Function use

Once the input data are appropriately formatted and structured you may now use the createRawOCTSubjectDirectoryStructure function in the manner described by the function documentation:

> createRawOCTSubjectDirectoryStructure(subjDataDir,targetOutputDir, centroidCSVPath)
> 
> This is a function that is used to create a subject level directory structure for OCT data analysis. Previously, centroid data was kept in a separate, group level file (input here as centroidCSVPath) and all subject&#39;s data were contained within the same directory. However, for cloud/parallel processing purposes group level files like this are not ideal. As such, this function creates a directory structure with the raw input data and the associated centroid file.
>
> INPUTS:
> 
> subjDataDir: The directory that contains the subject/eye specific data. Should contain no files other than the relevant CSVs. Directory can contain sub-directories, though this function will not search for files within them.
> 
> targetOutputDir: the directory that the output of this function should be saved to. If not specified creates an output directory (&#39;primaryOutput&#39;) within the \&lt;subjDataDir\&gt; directory
> 
> centroidCSVPath: path to the CSV file containing the data indicating the foveal centroid of the eye.
>
> OUTPUTS:
>
> none, saves output CSVs to specified directory

Having described the input structure and formatting previously, we now move on to describing the output.

# Output

The output directory structuring will be found in the path specified by targetOutputDir. In this directory you will find a subdirectory for each unique subject ID featured in the input data CSV files found in the subjDataDir directory. Within each of these subdirectories you should find the following:

For each eye-CSV (i.e. OD or OS) in the input directory associated with this subject, a corresponding [eye]\_raw.csv file and a [eye]\_centroid.csv. It is not assumed that each subject has data for each eye. Thus for a standard subject (with both eyes) with subject number 001 we would expect the directory contents to looks as follows:

>[001]$ dir
>
> OD\_raw.csv OD\_centroid.csv OS\_raw.csv OS\_centroid.csv


These files can then be uploaded using the brainlife interface in accordance with the datatype norms here ([https://brainlife.io/datatype/5ebe0bbbb969982124072325/edit](https://brainlife.io/datatype/5ebe0bbbb969982124072325/edit))
