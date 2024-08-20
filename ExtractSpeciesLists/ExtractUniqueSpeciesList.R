rm(list=ls())
# ---------------------------------------------------------------------------------------------------- #
# * NOTE: Please make a copy of this script before editing and/or running.
# * The script reads the dbf files exported from the python script "ExtractSpeciesFromHypergridsWithinBoundary.py"
#   to a single csv containing a clean list of unique species.
# * 2 variables need to be updated by the user:
#   1) base.dir: Base directory containing the dbf's.
#   2) out.csv: output csv file that will contain a list of species.
# * Script written by Ellie Linden in March 2020
# ---------------------------------------------------------------------------------------------------- #

library(foreign) # read.dbf
library(dplyr)
library(stringr)
library(janitor) #remove_empty

base.dir <- "S:/Projects/NPCA/_Year2/Data/Intermediate/ExtractSpeciesList/SpeciesList/" # UPDATE 
out.csv <- "S:/Projects/NPCA/_Year2/Data/Intermediate/ExtractSpeciesList/GreaterEverglades/BICY_EVER_SpsList.csv" # UPDATE 
cutecodes <- read.csv("S:/Projects/_Workspaces/Hannah_Hyatt/MoBI_Gov_Relations/SpeciesLists/CuteCodeCrosswalk.csv")

# Import dbf files #
aquatic <-read.csv(paste0(base.dir, "aqu_inverts.csv"))
plants1 <- read.csv(paste0(base.dir, "plants_gp1.csv"))
plants2 <- read.csv(paste0(base.dir, "plants_gp2.csv"))
pollinators <- read.csv(paste0(base.dir, "poll_inverts.csv"))
vertebrates <- read.csv(paste0(base.dir, "vertebrates.csv"))

# fix cutecode field
cutecodes$cutecode <- paste0(cutecodes$ï..cutecode)

# Combine species ataframes #
species.list <- rbind(aquatic, plants1, plants2, pollinators, vertebrates)

# Create new row for each cutecode #
species.list <- as.data.frame(unlist(strsplit(as.character(species.list$spplist), "[,]"))) 

# Rename column
names(species.list)[1] <- "species"

# Remove blank spaces in dataframe
species.list$species <- str_trim(species.list$species)

# Remove Duplicate and blank rows #
species.list <- species.list %>%
  distinct() %>%
  remove_empty("rows")

species.list.joined <- species.list %>% 
  left_join(., cutecodes, by=c("species"="cutecode"))

write.csv(species.list.joined, out.csv)
