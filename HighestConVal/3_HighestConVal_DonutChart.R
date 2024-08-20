## This script is the final step in a series of process which creates donut charts 
## representing the GAP status and Managment status of areas of highest conservation 
## value within the study area of interest

setwd("S:/Projects/NPCA/_Year2/Workspace/Hannah_Ceasar/NPCA_ConservationValues_Yr2/HighestConVal")
library(tidyverse)
library(arcgisbinding)

arc.check_product()
options(scipen=999) # don't use scientific notation

inputTabAreaGAP <- "S:/Projects/NPCA/_Year2/Data/Intermediate/TabulateAreaTables_yr2.gdb/TabArea_NorthCascades10pctHighestConVal_GAPsts" # UPDATE Input Tabulate Area table - Managed Lands or GAP status focused
inputTabAreaGAP <- arc.open(inputTabAreaGAP)
inputTabAreaGAP <- arc.select(inputTabAreaGAP)
inputTabAreaGAP <- as.data.frame(inputTabAreaGAP)

inputTabAreaGAP$OBJECTID <- NULL

# Create Gap Status field
inputTabAreaGAP$GAPstatus <- paste0("GAP",inputTabAreaGAP$GAP_Sts)

# Create plot
StudyArea_subset1 <- inputTabAreaGAP %>% #groups by study area and calculates the total area
  group_by( Value, GAPstatus) %>%
  summarise(Area = sum(Area)) %>% 
  ungroup()

StudyArea_subset2 <- StudyArea_subset1 %>% #calculates the percentages
  group_by(Value) %>%
  mutate(PercentArea =   (Area / sum(Area)*100) )

StudyArea_subset2$GAPstatus <- factor(StudyArea_subset2$GAPstatus, levels = c("GAPNA","GAP4","GAP3","GAP2","GAP1"))
StudyArea_subset2$ymax = cumsum(StudyArea_subset2$PercentArea) #sets top of rectangle for ggplot
StudyArea_subset2$ymin = c(0, head(StudyArea_subset2$ymax, n=-1)) #sets bottom of rectange for ggplot

p<- StudyArea_subset2 %>%
  ggplot (aes(x=2, ymax=ymax,ymin=ymin, xmax=4, xmin=3, fill = GAPstatus))+
  geom_rect()+
  ggtitle("North Cascades") +
  coord_polar(theta = "y")+ #makes plot circular
  scale_fill_manual(values=c("#b1b1b1","#bed5cf","#659fb5","#869447","#27613b"))+
  theme_void()+ #punches hole in donut
  theme(legend.position = "none", legend.title = element_blank(),plot.title.position = "plot")+
  xlim(1,4) #sets width of donut
#write.csv(StudyArea_subset2, "S:/Projects/NPCA/MapExports/Draft/EsriMapGallery/Data/HighestConVal_GAPsts_SouthernApp.csv")
plot(p)
ggsave(paste0("NorthCascades_HighestConVal_GAPsts.png"), plot = p, bg = "transparent",dpi = 300)


##----------------------------------------------------------------------------------------------------------------------#
## Donut charts based on PADUS Management fields - simplified 


inputTabAreaManaged <- "S:/Projects/NPCA/_Year2/Data/Intermediate/TabulateAreaTables_yr2.gdb/TabArea_NorthCascades10pctHighestConVal_MANGsts"
inputTabAreaManaged <- arc.open(inputTabAreaManaged)
inputTabAreaManaged <- arc.select(inputTabAreaManaged)
inputTabAreaManaged <- as.data.frame(inputTabAreaManaged)

inputTabAreaManaged$OBJECTID <- NULL

## replace NA for GAPstatus where the lands are unprotected
inputTabAreaManaged$Manager <- paste(inputTabAreaManaged$Mang_NS) 

#lstManagers <- unique(inputTabAreaManaged$Mang_NS)

#create plot
StudyArea_subset1 <- inputTabAreaManaged %>% #groups by study area and calculates the total area
  group_by( Value, Mang_NS) %>%
  summarise(Area = sum(Area)) %>% 
  ungroup()

StudyArea_subset2 <- StudyArea_subset1 %>% #calculates the percentages
  group_by(Value) %>%
  mutate(PercentArea =   (Area / sum(Area)*100) )

StudyArea_subset2$Mang_NS <- factor(StudyArea_subset2$Mang_NS, levels=c('PVT','USFS','NPS','LOC','FED','DOE','DOD','NGO','BLM','FWS','TRIB','STAT','Unmanaged'))
#StudyArea_subset2$Mang_NS <- fct_rev(StudyArea_subset2$Mang_NS) # reverses the order of the factor
StudyArea_subset2 <- plyr::ddply(StudyArea_subset2, c('Mang_NS')) # sorts data frame in the same order as the factor levels

StudyArea_subset2$ymax = cumsum(StudyArea_subset2$PercentArea) #sets top of rectangle for ggplot
StudyArea_subset2$ymin = c(0, head(StudyArea_subset2$ymax, n=-1)) #sets bottom of rectange for ggplot

p <- StudyArea_subset2 %>%
  ggplot (aes(x=2, ymax=ymax,ymin=ymin, xmax=4, xmin=3, fill = Mang_NS))+
  geom_rect()+
  ggtitle("North Cascades") +
  coord_polar(theta = "y")+ #makes plot circular
  #scale_y_reverse()+
  # scale_fill_manual(values=c("Unmanaged" = "#B1B1B1",
  #                            "UNK" = "#7F7F7F", 
  #                            "PVT" = "#6a3d9a", 
  #                            "TRIB" = "#b15928",
  #                            "USFS" = "#1F601A",
  #                            "NPS" = "#3BB432",
  #                            "STAT" = "#ffff99", 
  #                            "LOC" = "#e31a1c", 
  #                            "FED" = "#fb9a99",
  #                            "DOE" = "#b2df8a",
  #                            "DOD" = "#1f78b4", 
  #                            "NGO" = "#ff7f00", 
  #                            "BLM" = "#a6cee3",
  #                            "FWS" = "#fdbf6f"))+
  scale_fill_manual(values=c("Unmanaged" = "#B1B1B1",
                             "UNK" = "#7F7F7F", 
                             "PVT" = "#6a3d9a", 
                             "TRIB" = "#b15928",
                             "USFS" = "#1F601A",
                             "NPS" = "#3BB432",
                             "STAT" = "#ffff99", 
                             "LOC" = "#e31a1c", 
                             "FED" = "#fb9a99",
                             "DOE" = "#b2df8a",
                             "DOD" = "#1f78b4", 
                             "NGO" = "#ff7f00", 
                             "BLM" = "#a6cee3",
                             "FWS" = "#fdbf6f"))+
  theme_void()+ #punches hole in donut
  theme(legend.position = "bottom", legend.title = element_blank(),plot.title.position = "plot")+
  xlim(1,4) #sets width of donut
plot(p)
ggsave(paste0("NorthCascades_HighestConVal_Mangsts.png"), plot = p, bg = "transparent",dpi = 300)
#write.csv(StudyArea_subset2, "S:/Projects/NPCA/MapExports/Draft/EsriMapGallery/Data/HighestConVal_Mangsts_SouthernApp.csv")
