## Script that is in the process of being adapted from Chris Tracey's original script
## Goal is to get the NVC groups that are at risk and overlap at least 1% with each study area
## These NVC groups have their protection status and management status represented in bar charts both inside and outside of the study areas

library(tidyverse)
library(arcgisbinding)

arc.check_product()
options(scipen=999) # don't use scientific notation

inputTabAreaGAP <- "S:/Projects/NPCA/_Year2/Data/Intermediate/TabulateAreaTables_yr2.gdb/TabArea_NVCgrps_GAPsts_20250219" # UPDATE Input Tabulate Area table - Managed Lands or GAP status focused
inputTabAreaGAP <- arc.open(inputTabAreaGAP)
inputTabAreaGAP <- arc.select(inputTabAreaGAP)
inputTabAreaGAP <- as.data.frame(inputTabAreaGAP)

inputTabAreaManaged <- "S:/Projects/NPCA/_Year2/Data/Intermediate/TabulateAreaTables_yr2.gdb/TabArea_NVCgrps_Mangsts"
inputTabAreaManaged <- arc.open(inputTabAreaManaged)
inputTabAreaManaged <- arc.select(inputTabAreaManaged)
inputTabAreaManaged <- as.data.frame(inputTabAreaManaged)

# inputRaster <- "S:/Projects/NPCA/Data/Intermediate/NationalAnalysis.gdb/Landfire_EVT_2020_IVC_join_2023" #
# inputRaster <- arc.open(inputRaster)
# inputRaster <- arc.select(inputRaster)
# inputRaster <- as.data.frame(inputRaster)

inputRaster <- read.csv("S:/Data/NatureServe/Ecosystem_Terrestrial/IVC_GroupsMap_v0pt94/IVCgroups_v0pt946_fields.csv")

inputTabAreaGAP$OBJECTID <- NULL
inputTabAreaManaged$OBJECTID <- NULL

## split out study area
inputTabAreaGAP$StudyArea <- "NA"
inputTabAreaGAP$StudyArea <- gsub("\\(([^()]+)\\)", "\\1",str_extract(inputTabAreaGAP$NPCA_Status_GAP_StudyArea, "\\(([^()]+)\\)"))

## split out protected unprotected
inputTabAreaGAP$Protected <- "NA"
inputTabAreaGAP$Protected <- gsub("^(.*?),.*", "\\1", inputTabAreaGAP$NPCA_Status_GAP_StudyArea)

## split out GAP status
inputTabAreaGAP$GAPstatus <- "NA"
inputTabAreaGAP$GAPstatus <- sub(".*GAP ", "", inputTabAreaGAP$NPCA_Status_GAP_StudyArea)
inputTabAreaGAP$GAPstatus <- sub(".*?(\\d+)", "\\1", inputTabAreaGAP$NPCA_Status_GAP_StudyArea)
inputTabAreaGAP$GAPstatus <- as.integer(substring(inputTabAreaGAP$GAPstatus, 1, 1))

# this enables verification of Naturalness in a later step
inputTabAreaGAP <- left_join(inputTabAreaGAP, 
                             select(inputRaster, GroupNam, ELCODE, RdGrank, Natural_), 
                             by = c("GroupNam" = "GroupNam"),
                             suffix = c("_x", "_y"),
                             relationship = "many-to-many")

# subset by G Rank
#inputTabAreaGAP$G_RANK <- substr(inputTabAreaGAP$ROUNDED_G_RANK_x, 1, 2)
#inputTabAreaGAP <- inputTabAreaGAP[which(inputTabAreaGAP$G_RANK %in% c("G1", "G2", "G3","G4", "G5")), ]


lstStudyAreas <- unique(inputTabAreaGAP$StudyArea)


for(i in 1:length(lstStudyAreas)){
  print(paste("working on ", lstStudyAreas[i], sep=""))
  StudyArea_subset <- inputTabAreaGAP[which(inputTabAreaGAP$StudyArea==lstStudyAreas[i]),]
  
  #lstGroups_subset <- unique(StudyArea_subset[which(StudyArea_subset$Naturalnes=="Natural"),"GroupNam"] )
  lstGroups_subset <- unique(StudyArea_subset$GroupNam)
  
  # create an empty data frame
  StudyAreaGroup_subsetComb <- inputTabAreaGAP[0,]
  
  for(j in 1:length(lstGroups_subset)){  #
    print(paste("working on ", lstGroups_subset[j], sep=""))
    StudyAreaGroup_subset <- inputTabAreaGAP[which(inputTabAreaGAP$GroupNam==lstGroups_subset[j]),]
    StudyAreaGroup_subset[which(StudyAreaGroup_subset$StudyArea!=lstStudyAreas[i]),"StudyArea"] <- NA
    
    StudyAreaGroup_subsetComb <- rbind(StudyAreaGroup_subsetComb, StudyAreaGroup_subset)
    
    StudyAreaGroup_subset1 <- StudyAreaGroup_subsetComb %>%
      group_by( StudyArea, Protected, GAPstatus, GroupNam, RdGrank) %>% #NPCA_status_GAP_StudyArea,
      summarise(TotalArea = sum(Area)) %>% 
      ungroup()
    
    StudyAreaGroup_subset2 <- StudyAreaGroup_subset1 %>%
      group_by(GroupNam) %>%
      mutate(PercentArea =   (TotalArea / sum(TotalArea)*100) ) %>%
      mutate(TotalArea2 = if_else(is.na(StudyArea), -TotalArea, TotalArea)) %>%
      mutate(PercentArea2 = if_else(is.na(StudyArea), -PercentArea, PercentArea))
    
    StudyAreaGroup_subset3 <- StudyAreaGroup_subset2 %>%
      group_by(GroupNam) %>%
      mutate(TotalPosPercent =sum(PercentArea2[PercentArea2>0]))
    
    StudyAreaGroup_subset3 <- StudyAreaGroup_subset3[which(StudyAreaGroup_subset3$TotalPosPercent>2),]
    
    StudyAreaGroup_subset3$axislable <- paste0(StudyAreaGroup_subset3$GroupNam, " (", StudyAreaGroup_subset3$RdGrank, ")") 
    #StudyAreaGroup_subset3$axislable <- paste0(StudyAreaGroup_subset3$IVC_Name) 
    StudyAreaGroup_subset3$GAPstatus <- paste0("GAP",StudyAreaGroup_subset3$GAPstatus)
    StudyAreaGroup_subset3$GAPstatus[which(StudyAreaGroup_subset3$GAPstatus=="GAPNA")] <- "Unprotected"
    StudyAreaGroup_subset3$GAPstatus <- factor(StudyAreaGroup_subset3$GAPstatus, levels = c("Unprotected","GAP4","GAP3","GAP2","GAP1"))
    
    
    p <- StudyAreaGroup_subset3 %>%
      ggplot(aes(x = reorder(axislable, TotalPosPercent),
                 y = PercentArea2,
                 fill = GAPstatus)) +
      geom_col() +
      coord_flip() +
      geom_abline(slope=0, intercept=0.0,  col = "white") +
      ggtitle(paste(lstStudyAreas[i])) +
      ylab("Outside Study Area                                                             Inside Study Area") +
      scale_y_continuous(limits = c(-100, 100), breaks=c(-100,-75,-50,-25, 0, 25,50,75,100), labels=c("100%","75%","50%","25%", "0%", "25%","50%","75%","100%")) +
      scale_fill_manual(values=c("#b1b1b1","#bed5cf","#659fb5","#869447","#27613b"), guide = guide_legend(reverse = TRUE)) +
      theme_minimal() +
      theme(
        panel.grid = element_blank(),
        legend.title = element_blank(),
        axis.title = element_blank(),
        legend.position = "none",
        # plot.title = element_text(color = "white"),  # White title text
        # axis.text = element_text(color = "white"),  # White axis text
        # axis.ticks = element_line(color = "white"), # White axis ticks
        # legend.text = element_text(color = "white") # White legend text
      )
    plot(p)
  }
}
plot(p)
ggsave(paste0("NorthCascades_IVCgroups_GAPsts.png"), plot = p, bg = "transparent",dpi = 300)
write.csv(StudyAreaGroup_subset3, "S:/Projects/NPCA/_Year2/Data/Intermediate/NorthCascades/Tables/NVCgroups_NorthCascades.csv")

#-----------------------------------------------------------------------
### Repeat the above steps for results summarized by Manager Name


## split out study area
inputTabAreaManaged$StudyArea <- "NA"
inputTabAreaManaged$StudyArea <- gsub("\\(([^()]+)\\)", "\\1",str_extract(inputTabAreaManaged$NPCA_Status_Mang_StudyArea, "\\(([^()]+)\\)"))

## split out managed unmanaged
inputTabAreaManaged$Managed <- "NA"
inputTabAreaManaged$Managed <- gsub("^(.*?),.*", "\\1", inputTabAreaManaged$NPCA_Status_Mang_StudyArea)

## split out Manager Name
inputTabAreaManaged$Mang_Name <- "NA"
#inputTabAreaManaged$Mang_Name <- sub("\\).*", ")",inputTabAreaManaged$NPCA_Status_Mang_StudyArea)
inputTabAreaManaged$Mang_Name <- sub(".*?-", "",inputTabAreaManaged$NPCA_Status_Mang_StudyArea)
inputTabAreaManaged$Mang_Name <- sub(",.*", "",inputTabAreaManaged$Mang_Name)
inputTabAreaManaged$Mang_Name <- sub("\\(.*", "",inputTabAreaManaged$Mang_Name)
inputTabAreaManaged$Mang_Name <- trimws(inputTabAreaManaged$Mang_Name)

# this enables verification of Naturalness in a later step
inputTabAreaManaged <- merge(inputTabAreaManaged, inputRaster[c("IVC_NAME","ROUNDED_G_RANK", "Naturalnes")], by.x="IVC_NAME", by.y="IVC_NAME") 

# subset by G Rank
inputTabAreaManaged$G_RANK <- substr(inputTabAreaManaged$ROUNDED_G_RANK, 1, 2)
inputTabAreaManaged <- inputTabAreaManaged[which(inputTabAreaManaged$G_RANK %in% c("G1", "G2", "G3","G4")), ]

lstStudyAreas <- unique(inputTabAreaManaged$StudyArea)
lstManagers <- unique(inputTabAreaManaged$Mang_Name)

for(i in 1:length(lstStudyAreas)){
  print(paste("working on ", lstStudyAreas[i], sep=""))
  StudyArea_subset <- inputTabAreaManaged[which(inputTabAreaManaged$StudyArea==lstStudyAreas[i]),]
  
  lstGroups_subset <- unique(StudyArea_subset[which(StudyArea_subset$Naturalnes=="Natural"),"IVC_NAME"] )
  
  
  # create an empty data frame
  StudyAreaGroup_subsetComb <- inputTabAreaManaged[0,]
  
  for(j in 1:length(lstGroups_subset)){  #
    print(paste("working on ", lstGroups_subset[j], sep=""))
    StudyAreaGroup_subset <- inputTabAreaManaged[which(inputTabAreaManaged$IVC_NAME==lstGroups_subset[j]),]
    StudyAreaGroup_subset[which(StudyAreaGroup_subset$StudyArea!=lstStudyAreas[i]),"StudyArea"] <- NA
    
    StudyAreaGroup_subsetComb <- rbind(StudyAreaGroup_subsetComb, StudyAreaGroup_subset)
    
    StudyAreaGroup_subset1 <- StudyAreaGroup_subsetComb %>%
      group_by( StudyArea, Managed, Mang_Name, IVC_NAME, G_RANK) %>% 
      summarise(TotalArea = sum(Area)) %>% 
      ungroup()
    
    StudyAreaGroup_subset2 <- StudyAreaGroup_subset1 %>%
      group_by(IVC_NAME) %>%
      mutate(PercentArea =   (TotalArea / sum(TotalArea)*100) ) %>%
      mutate(TotalArea2 = if_else(is.na(StudyArea), -TotalArea, TotalArea)) %>%
      mutate(PercentArea2 = if_else(is.na(StudyArea), -PercentArea, PercentArea))
    
    StudyAreaGroup_subset3 <- StudyAreaGroup_subset2 %>%
      group_by(IVC_NAME) %>%
      mutate(TotalPosPercent =sum(PercentArea2[PercentArea2>5]))
    
    StudyAreaGroup_subset3 <- StudyAreaGroup_subset3[which(StudyAreaGroup_subset3$TotalPosPercent>0),]
    
    StudyAreaGroup_subset3$axislable <- paste0(StudyAreaGroup_subset3$IVC_NAME, " (", StudyAreaGroup_subset3$G_RANK, ")") 
    StudyAreaGroup_subset3$Manager <- factor(StudyAreaGroup_subset3$Mang_Name, levels = c(lstManagers))
    StudyAreaGroup_subset3$Manager <- factor(StudyAreaGroup_subset3$Manager, levels =c('NA','UNK','PVT','TRIB','STAT','LOC','FED','DOE','DOD','NGO','BLM','FWS','USFS','NPS'))
    #StudyAreaEcosystem_subset3 <- StudyAreaEcosystem_subset3[order(levels(StudyAreaEcosystem_subset3$Manager)),]
    
    StudyAreaGroup_subset3 %>%
      ggplot(aes(x = reorder(axislable, TotalPosPercent),
                 y = PercentArea2,
                 fill = Manager)) +
      geom_col() +
      coord_flip() +
      geom_abline(slope=0, intercept=0.0,  col = "white") +
      ggtitle(paste(lstStudyAreas[i],"Study Area")) +
      ylab("Outside Study Area                                                             Inside Study Area") +
      scale_y_continuous(limits = c(-100, 100), breaks=c(-100,-75,-50,-25, 0, 25,50,75,100), labels=c("100%","75%","50%","25%", "0%", "25%","50%","75%","100%")) +
      scale_fill_manual(values=c("NA" = "#B1B1B1",
                                 "UNK" = "#7F7F7F", 
                                 "PVT" = "#6a3d9a",
                                 "TRIB" = "#b15928",
                                 "STAT" = "#ffff99", 
                                 "LOC" = "#e31a1c", 
                                 "FED" = "#fb9a99",
                                 "DOE" = "#b2df8a",
                                 "DOD" = "#1f78b4",
                                 "NGO" = "#ff7f00", 
                                 "BLM" = "#a6cee3",
                                 "FWS" = "#fdbf6f",
                                 "USFS" = "#1F601A", 
                                 "NPS" = "#3BB432"), guide = guide_legend(reverse = TRUE)) +
      theme_minimal() +
      theme(axis.title.y = element_blank(),
            panel.grid = element_blank(),
            legend.title=element_blank(),
            legend.position = "none",
            plot.title.position = "plot")
  }
}    
