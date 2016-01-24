# author: Chris Reudenbach
# edited by: Jannik Guenther
# PerfectPeak.R v1.02
# version:2015-11-22
# license: = "GNU GPL, see http://www.gnu.org/licenses/"


Rpeak <- function(fname.control, fname.DEM){
  
  # INI File
  fname.control <- ""
  # DEM
  fname.DEM <- "C:/geography/advancedgis/perfectpeak/lz_10m_float_clip.asc"
  # Ordner mit den Funktionen
  path <- "C:/Users/Jannik/Dropbox/Marburg/PackageProject/perfectPeak/fun"
  
  # Funktion sourceDir
  source(file.path(path,"sourceDir.R"))
  # Funktionen aus dem path Pfad in die Umgebung holen mit der Funktion sourceDir
  sourceDir(path)
  
  # Umgebung neu definieren
  i <- initEnvironGis(fname.control,fname.DEM)
  ini <- i$ini
  myenv <- i$env
  extent <- i$extent
  
  root.dir <- ini$Pathes$workhome         #Project folder
  working.dir <- ini$Pathes$runtimedata   #Working folder
  
  
  # Set filenames
  peak.list <- ini$Files$peaklist
  dem.in <- fname.DEM
  if (dem.in==""){
    dem.in <- ini$Files$fndem
    fname.DEM <- dem.in
  }
  
  #Set runtime arguments
  ext.peak <- ini$Params$externalpeaks  #harry = Harrys Peaklist; osm = OSM data
  kernel.size <- ini$Params$filterkernelsize # Size of filter for mode=1; range 3-30, default= 5
  make.peak.mode <- ini$Param$makepeakmode # mode:1=minmax, 2=wood$co
  exact.enough <- as.numeric(ini$Params$exactenough) # Annaehrungswert beim Fluten für die Prominenz
  epsg.code <- as.numeric(ini$Projection$targetepsg) #EPSG Code
  target.proj4 <- ini$Projection$targetproj4 # correct string from the ini file
  latlon.proj4 <- ini$Projection$latlonproj4 # basic latlon wgs84 proj 4 string

  
  # (R) call MakePeak if necessary
  if (run.makePeak) {
    final.peak.list<-makePeak(dem.in, peak.list,make.peak.mode,epsg.code, kernel.size)
  } else {
    if (file.exists(peak.list)){
      final.peak.list<-read.table(peak.list, header = TRUE, sep = " ",dec='.')
      # Da nur in makePeak das Höhenmodell eine Projektion zugewiesen bekommt, soll an dieser Stelle extra nochmal eine Projektion zugewiesen werden
      # Falls man makePeak überspringt.
      projectDEM(dem.in, epsg.code)
    } else{
      stop('There is no valid peaklist')
    }
  }
  
  for (i in 2:6){
    # call calculate functions and put retrieved value into the dataframe field.
    final.peak.list[i,4]<-calculateDominance(final.peak.list[i,1], final.peak.list[i,2],final.peak.list[i,3])
    final.peak.list[i,5]<-calculateProminence(final.peak.list,final.peak.list[i,1], final.peak.list[i,2],final.peak.list[i,3],exact.enough, epsg.code)
    final.peak.list[i,7]<-calculateEValue(final.peak.list[i,3], final.peak.list[i,4],final.peak.list[i,5])
  }
  
  # make it a spatialObject
  # set the xy coordinates
  coordinates(final.peak.list) <- ~xcoord+ycoord
  # set the projection
  proj4string(final.peak.list) <- target.proj4
  
  ### to have something as a result
  # write it to a shape file
  writePointsShape(final.peak.list, "finalpeaklist.shp")
  
  plot(final.peak.list)
  
  # (R) delete all runtime files with filenames starting with run_
  file.remove(list.files(file.path(root.dir, working.dir), pattern =('mp_'), full.names = TRUE, ignore.case = TRUE))
  file.remove(list.files(file.path(root.dir, working.dir), pattern =('run'), full.names = TRUE, ignore.case = TRUE))
  
  print("That's it")
  
}
  
#   ###   --- setup section ---
#   
#   # (R) cleanup global environment
#   rm(list = ls())
#   start.time <- proc.time()
#   
#   #(R) if necessary install raster and rgdal
#   # if (!require(RSAGA)){install.packages('RSAGA')}
#   # if (!require(rgdal)){install.packages('rgdal')}
#   # if (!require(raster)){install.packages('raster')}
#   # if (!require(gdalUtils)){install.packages('gdalUtils')}
#   # if (!require(gdalUtils)){install.packages('rgdal')}
#   # if (!require(gdalUtils)){install.packages('sp')}
#   # if (!require(gdalUtils)){install.packages('maptools')}
#   
#   # (R) load libs
#   library(RSAGA)
#   library(gdalUtils)
#   library(raster)
#   library(sp)
#   library(rgdal)
#   library(maptools)
#   
#   #Pathdummys for copy-paste
#   #Jannik Laptop:
#   #C:/OSGeo4W64/
#   #C:/geography/advancedgis/perfectpeak/
#   #C:/Dropbox/Marburg/agis/scripts/
#   #
#   #Jannik PC:
#   #D:/Programme/OSGeo4W64/
#   #D:/Geographie/Advanced_GIS/Projekt_perfektpeak/
#   #D:/Dropbox/Dropbox/Marburg/agis/Scripts/
#   
#   ## (gdalUtils) check for a valid GDAL binary installation on your system
#   # Sollte kein GDAL gefunden werden, ist es nicht korrekt installiert, oder der search_path muss angepasst werden
#   gdal_setInstallation(search_path = "C:/OSGeo4W64/bin")
#   valid.install<-!is.null(getOption("gdalUtils_gdalPath"))
#   if (!valid.install){stop('no valid GDAL/OGR found')} else{print('gdalUtils status is ok')}
#   
#   ## (R) define some parameters
#   root.dir <- "C:/geography/advancedgis/perfectpeak/"   # root folder
#   working.dir <- "tmp"         # working folder
#   script.dir <- "C:/Users/Jannik/Dropbox/Marburg/agis/scripts/" # Script Folder
#   
#   peak.list <- "peaklist.txt"         # outputname of peaklist
#   dem.in <- "lz_10m_float_clip.asc"        # input DEM
#   if (dem.in==''){dem.in<-file.choose()}
#   
#   run.makePeak<-T               # if TRUE run makePeak
#   kernel.size<-25                   # range 3-30 bigger numbers=smoother terrain and slower!
#   make.peak.mode<-1                 # mode:1=minmax,2=wood,3=harry (2,3 not implemented)
#   epsg.code<-'EPSG:31255'           # EPSG Code for input ASC file
#   exact.enough<-5                   # vertical exactness of flooding in meter
#   
#   
#   
#   # (R) set working directory
#   setwd(file.path(root.dir, working.dir))
#   workingpath <- file.path(root.dir, working.dir)
#   
#   
#   # Definiere die Umgebungen für RSAGA und die Pfade für die OSGeo4W shell und die saga_cmd für Windows oder Linux
#   if(Sys.info()["sysname"] == "Windows"){
#     # (RSAGA) define SAGA environment Windows
#     myenv=rsaga.env(check.libpath=FALSE,
#                     check.SAGA=FALSE,
#                     workspace=file.path(root.dir, working.dir),
#                     os.default.path="C:/OSGeo4W64/apps/saga",
#                     modules="C:/OSGeo4W64/apps/saga/modules")
#     # Definiere Pfade zu den Shells
#     osgeo_bat <- "C:/OSGeo4W64/OSGeo4W.bat" # Pfad zur OSGeo4W.bat
#     saga_cmd <- "C:/OSGeo4W64/apps/saga/saga_cmd.exe" # Pfad zur saga_cmd.exe
#     saga_cmd_new <- "C:/OSGeo4W64/apps/saga-new/saga_cmd.exe" #Pfad zur saga_cmd.exe einer neuen SAGA Version
#     #INFO: Getestet wurde das Script mit SAGA 2.1.2. Bis auf einen Befehl lief das Script einwandfrei
#     #Der Befehl zur erstellung des Proximity-Grid in der Funktion calculateDominance2 funkttionierte nur in SAGA 2.2.2, daher 
#     #existiert hier ein extra Pfad zur cmd der neuen Version.
#     
#   }else if (Sys.info()["sysname"] == "Linux"){ # (RSAGA) define SAGA environment Linux
#     myenv=rsaga.env(check.libpath=FALSE,
#                     check.SAGA=FALSE,
#                     workspace=file.path(root.dir, working.dir),
#                     os.default.path="/home/creu/SAGA-2.1.0-fixed/initial/bin",
#                     modules="/home/creu/SAGA-2.1.0-fixed/initial/lib/saga")
#     
#     # Definiere Pfade zu den Shells
#     osgeo_bat <- "" 
#     saga_cmd <- "saga_cmd"
#     saga_cmd_new <- "saga_cmd"
#   }  
#   
#   # Laden der einzelnen Funktionen, welche in externen R Scripten ausgelagert sind.
#   if(!exists("makepeak", mode="function")){source(paste0(script.dir,"makepeak.R"))}
#   if(!exists("projectDEM", mode="function")){source(paste0(script.dir,"projectDEM.R"))}
#   if(!exists("calculateDominance", mode="function")){source(paste0(script.dir,"calculateDominance.R"))}
#   if(!exists("calculateProminence", mode="function")){source(paste0(script.dir,"calculateProminence.R"))}
#   if(!exists("calculateEvalue", mode="function")){source(paste0(script.dir,"calculateEvalue.R"))}
#   
#   # (R) delete all runtime files with filenames starting with 'run_'
#   file.remove(list.files(file.path(root.dir, working.dir), pattern =('run'), full.names = TRUE, ignore.case = TRUE))
#   
#   ###   --- end setup section ---
#   
#   
#   
#   ###   --- start main ---
#   
#   # (R) call MakePeak if necessary
#   if (run.makePeak) {
#     final.peak.list<-makePeak(dem.in, peak.list,make.peak.mode,epsg.code, kernel.size)
#   } else {
#     if (file.exists(peak.list)){
#       final.peak.list<-read.table(peak.list, header = TRUE, sep = " ",dec='.')
#       # Da nur in makePeak das Höhenmodell eine Projektion zugewiesen bekommt, soll an dieser Stelle extra nochmal eine Projektion zugewiesen werden
#       # Falls man makePeak überspringt.
#       projectDEM(dem.in, epsg.code)
#     } else{
#       stop('There is no valid peaklist')
#     }
#   }
#   # (R) calculate dominance and prominence
#   #for (i in 1: nrow(final.peak.list)){
#   for (i in 2:6){
#     # call calculate functions and put retrieved value into the dataframe field.
#     final.peak.list[i,4]<-calculateDominance(final.peak.list[i,1], final.peak.list[i,2],final.peak.list[i,3])
#     final.peak.list[i,5]<-calculateProminence(final.peak.list,final.peak.list[i,1], final.peak.list[i,2],final.peak.list[i,3],exact.enough, epsg.code)
#     final.peak.list[i,7]<-calculateEValue(final.peak.list[i,3], final.peak.list[i,4],final.peak.list[i,5])
#   }
#   write.table(final.peak.list,'peaklist.txt',row.names=F)
#   
#   # (R) delete all runtime files with filenames starting with run_
#   file.remove(list.files(file.path(root.dir, working.dir), pattern =('mp_'), full.names = TRUE, ignore.case = TRUE))
#   file.remove(list.files(file.path(root.dir, working.dir), pattern =('run'), full.names = TRUE, ignore.case = TRUE))
#   
#   proc.time()-start.time
# }
# 
