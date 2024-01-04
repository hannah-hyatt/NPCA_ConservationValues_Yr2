# ---------------------------------------------------------------------------------------------------- #
# * NOTE: Please make a copy of this script before editing and/or running. 
# * This script calculates the total area of each species' binary habitat within a boundary.
# * The default is to loop through all MoBI species to clip the habitat.
#   This can be narrowed down to a specific list of species by changing the text file containing a list of the desired cutecodes under "Create Cutecode List" section
# * NOTE: This needs to be run twice because "picobore" and "ambycing" models don't end in "MOBI"
#   (see If/Else statement that selects species' model)
#   At some point we should fix this - potentially make copies of the final models and rename them.
# * 4 variables need to be updated by the user:
#   1) Boundary: Specified boundary to clip the rasters
#   2) tablepath: output workpace folder for tables
#   3) outTable: output dbf file
#   4) Boundary_field: field of boundary to summarize data
# * Script written by Ellie Linden with help from Tandena Wagner in the summer of 2020
# * Script updated by Hannah Hyatt(Ceasar) in 2023
# ---------------------------------------------------------------------------------------------------- #

# Import Modules
import os
import arcpy
from arcpy import env
from arcpy.sa import *
import datetime

# Get the current date and time
current_datetime = datetime.datetime.now()
timestamp = current_datetime.strftime("%Y-%m-%d %H:%M:%S")
print(f"Script started at: {timestamp}")

# Set Environments
WS = r"S:\Data\NatureServe\Species_Distributions\MoBI_HabitatModels\spp_models" # Folder containing all species' folders/models
env.workspace = WS
arcpy.env.overwriteOutput = True

# Set Variables
Boundary = r"S:\Projects\NPCA\Data\Intermediate\GAP_Analysis.gdb\StudyAreas_PADUS_CONUS_AnalysisLayerV2" # UPDATE
tablepath = r"S:\Projects\NPCA\_Year2\Data\Intermediate\EndemicSpeciesSummaries\GreaterYellowstone_IntTbls" # UPDATE
outTable = r"MoBIshms_TabAreaMerge_GreaterEverglades" # UPDATE
Boundary_field = "NPCA_Status_GAP_StudyArea" # UPDATE

# Create Cutecode List
cutecodelist = []
cutecode_file = open(r'S:\Projects\NPCA\_Year2\Data\Intermediate\ExtractSpeciesList\GreaterYellowstone\GreaterYellowstone_SpsList.txt', 'r') # UPDATE IF NEEDED
for word in cutecode_file:
    word = word.rstrip("\n") # this removes the spaces after each word
    cutecodelist.append(word)

# Loop through cutecodes to get rasters and calculate area
i = 1
for i in range(len(cutecodelist)):
    try:
        cutecode = cutecodelist[i]
        srpath = WS + "\\" + cutecode + "\outputs\model_predictions\\"
        filelist = os.listdir(srpath)
        i = 1
        for i in range(len(filelist)):
            if (filelist[i].endswith(('MOBI.tif','binary.tif'))): 
                rastername = filelist[i]

        SpeciesRaster = srpath + rastername

        # Calculate area in meters squared
        area_dbf = tablepath + "\\" + cutecode + "_areatable.dbf"
        TabulateArea(Boundary, Boundary_field, SpeciesRaster, "Value", area_dbf, SpeciesRaster)

        # Add/calculate cutecode field in dbf output
        field = "cutecode"
        expression = str(cutecode)
        print(cutecode)
        arcpy.AddField_management(area_dbf, field, "TEXT")
        arcpy.CalculateField_management(area_dbf, field, '"'+expression+'"',"PYTHON")
        
    except:
        print("model doesn't overlap")

# Merge all output dbfs
env.workspace = tablepath
listTable = arcpy.ListTables()
Areas_merged = outTable
arcpy.Merge_management(listTable, Areas_merged)
print("merge complete")

# join species information
cutecode_crosswalk = r"S:\Projects\_Workspaces\Hannah_Hyatt\MoBI_Gov_Relations\SpeciesLists\CuteCodeCrosswalk.csv"
arcpy.management.JoinField(Areas_merged, "cutecode", cutecode_crosswalk, "cutecode", "Scientific_Name;Common_Name;Rounded_GRank;ESA_Status")
current_datetime = datetime.datetime.now()
timestamp = current_datetime.strftime("%Y-%m-%d %H:%M:%S")
print("Script complete at: {timestamp}")

