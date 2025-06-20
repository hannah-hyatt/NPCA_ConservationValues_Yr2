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
AnalysisLayer = r"S:\Projects\NPCA\Data\Intermediate\GAP_Analysis.gdb\StudyAreas_PADUS_CONUS_AnalysisLayerV2"
#NVCgroups = r"S:\Projects\Ecology\GroupMap_v0pt9\Symbology\NVCmap_symbology\IVC_v0p9.gdb\NVC_Groups_v0p9_RemovedPixels_16bitunsig"
NVCgroups = r"S:\Data\NatureServe\Ecosystem_Terrestrial\IVC_GroupsMap_v0pt94\IVC_Groups_v2022_0pt946.tif"
TabAreaGAP_out = r"S:\Projects\NPCA\_Year2\Data\Intermediate\TabulateAreaTables_yr2.gdb\TabArea_NVCgrps_GAPsts_20250219"
TabAreaMang_out = r"S:\Projects\NPCA\_Year2\Data\Intermediate\TabulateAreaTables_yr2.gdb\TabArea_NVCgrps_Mangsts_20250219"
print ("variables set")

## Tabulate area of NVC groups found within and outside of protected lands within and outside of study areas
print("1 - Working on Tabulate area for Protected Areas")
arcpy.sa.TabulateArea(AnalysisLayer, "NPCA_Status_GAP_StudyArea", NVCgroups, "GroupNam", TabAreaGAP_out, NVCgroups, "CLASSES_AS_ROWS")

# ## Tabulate Area of NVC groups found within/outside managed lands and within/outside of study areas
# print("2 - Working on Tabulate area for management status")
# arcpy.sa.TabulateArea(AnalysisLayer, "NPCA_Status_Mang_StudyArea", NVCgroups, "IVC_NAME", TabAreaMang_out, NVCgroups, "CLASSES_AS_ROWS")

print ("Complete")
