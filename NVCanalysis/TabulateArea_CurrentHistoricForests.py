# IUCN analysis for study areas
# Before this script:
# flattened PADUS layer was unioned to Study Areas which were unioned to CONUS (CONUS_AnalysisLayer below)
# Flags for inside/outside of study areas (field = "StudyArea"), managed/unmanaged lands (field = "managed"), protected/unprotected lands(field = "prot")
# merged flags with GAP status or Manager Name and name of study areas in format fitting for R code (location of R code here)

# Details on script below:
# Tabulate area for the field which outlines if the lands are protected, what status of protection they hold, and if it falls inside or outside of study areas.
# Tabulate area for the field which outlinse if the lands are managed, who is the land manager (Manager Name), and if it falls inside or outisde of study areas.

# Outputs:
# to be used in R code which creates bar chart visual of the above.

import arcpy, os
from arcpy import env
from arcpy.sa import *
from datetime import datetime
arcpy.CheckOutExtension('Spatial')
arcpy.env.overwriteOutput = True

##set variables
AnalysisLayer = r"S:\Projects\NPCA\_Year2\Pro\DeepDives\GreaterEverglades\GreaterEverglades.gdb\GreaterEverglades_simplified"
CurrentForests = r"S:\Projects\NPCA\_Year2\Pro\DeepDives\GreaterEverglades\GreaterEverglades.gdb\CurrentForests"
HistoricForests = r"S:\Projects\NPCA\_Year2\Pro\DeepDives\GreaterEverglades\GreaterEverglades.gdb\HistoricForests"
TabAreaCurrentForests_out = r"S:\Projects\NPCA\_Year2\Pro\DeepDives\GreaterEverglades\GreaterEverglades.gdb\TabArea_Everglades_CurrentForests"
TabAreaHistoricForests_out = r"S:\Projects\NPCA\_Year2\Pro\DeepDives\GreaterEverglades\GreaterEverglades.gdb\TabArea_Everglades_HistoricForests"
print ("variables set")

## Tabulate area of NVC groups found within and outside of protected lands within and outside of study areas
print("1 - Working on Tabulate area for Current Forests inside of Greater Everglades")
arcpy.sa.TabulateArea(AnalysisLayer, "StudyArea", CurrentForests, "Value", TabAreaCurrentForests_out, CurrentForests, "CLASSES_AS_ROWS")

## Tabulate Area of NVC groups found within/outside managed lands and within/outside of study areas
print("1 - Working on Tabulate area for Historic Forests inside of Greater Everglades")
arcpy.sa.TabulateArea(AnalysisLayer, "StudyArea", HistoricForests, "Value", TabAreaHistoricForests_out, CurrentForests, "CLASSES_AS_ROWS")

print ("Complete")
