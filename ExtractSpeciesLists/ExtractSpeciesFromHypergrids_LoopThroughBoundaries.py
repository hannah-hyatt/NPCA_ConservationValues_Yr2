# ---------------------------------------------------------------------------------------------------- #
# * NOTE: Please make a copy of this script before editing and/or running.
# * The script loops through the final "hypergrid" rasters that show which species' models fall within each pixel,
#   clips these rasters to a specified boundary, and exports the species lists as dbf files.
# * Once this script is complete, the R script "ExtractUniqueSpeciesList.R needs to be run in order
#   to extract all unique species' cutecodes to a single csv file
# * 3 variables need to be updated by the user:
#   1) boundary: Folder containing boundaries to clip the hypergrid rasters
#   2) outTemp: Geodatabase to contain temporary raster files
#   3) outWS: output workpace folder
# * Script written by Ellie Linden in March 2020 and edited in Feb 2022, edited again for NPCA project by Hannah Ceasar in 2023
# ---------------------------------------------------------------------------------------------------- #

import arcpy, os
from arcpy import env
from arcpy.sa import *
arcpy.CheckOutExtension("Spatial")

# Variables and Environments
raster_workspace = r"S:\Data\NatureServe\Species_Distributions\MoBI_HabitatModels\hypergrids\hypergrid_LA.gdb"
boundary = r"S:\Projects\NPCA\Data\Final\StudyAreas_fin.gdb\GreaterYellowstone" # UPDATE - area of interest
outTemp = r"S:\Projects\NPCA\_Year2\Pro\Temp.gdb" # UPDATE - geodatabase
outWS = r"S:\Projects\NPCA\_Year2\Data\Intermediate\ExtractSpeciesList\SpeciesList" # UPDATE - folder
arcpy.env.overwriteOutput = True
arcpy.env.scratchWorkspace = outTemp

# Loop through raster to extract from
arcpy.env.workspace = raster_workspace
rasters = arcpy.ListRasters()

# Loop through rasters to mask
for raster in rasters:
    print(raster)
    # Extract by Mask
    raster_file = raster_workspace + "\\" + raster
    outExtractByMask = ExtractByMask(raster_file, boundary)
    outRaster = outTemp + "\\" + raster + "_extract"
    outExtractByMask.save(outRaster)
    # Export Attribute Table as dbf
    outTable = raster + ".csv"
    arcpy.TableToTable_conversion(outRaster, outWS, outTable)
print ("Script Finished")
