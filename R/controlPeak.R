#' Demo Digital Elevation Model DEM
#'
#' The example Digital Elevation Model DEM is taken from the Authority of Tirol
#' it is dervied from LIDAR data and can downloaded for Tirol. 
#' The demo data is an Arc ASCII Grid with 324 cols by 360 rows and the following extent:
#' lon_min 11.35547, lon_max 11.40009, lat_min 47.10114, lat_max 47.13512
#'
#' \itemize{
#'   \item resolution : 10 Meter,10 Meter
#'   \item datatype, 32 Bit floating point
#'   \item projection, MGI_Austria_GK_West
#'   \item EPSG-Code, 31254
#'   \item unit, Meter
#'   \item datum, D_MGI
#'   \item Copyright:   \url{https://www.tirol.gv.at/data/nutzungsbedingungen/},  \url{Creative Commons Namensnennung 3.0 Österreich Lizenz (CC BY 3.0 AT).}
#'   }
#' @source Data source: \url{https://www.tirol.gv.at/data/datenkatalog/geographie-und-planung/digitales-gelaendemodell-tirol/}
#'         
#' @docType data
#' @keywords datasets
#' @name input.DEM
#' @usage raster('stubai.asc')
#' @format Arc ASCII Grid
NULL

#' Demo Ini File
#'
#' The example control file provides all necessary settings for using the perfectPeak package
#'
#' \itemize{
#'   \item [Pathes]
#'   \item workhome='/home/creu/MOC/aGIS/Rpeak'
#'   \item rawdata='./data'
#'   \item runtimedata='run'
#'   \item src='./src'
#'}
#' \itemize{   
#'   \item [Files]
#'   \item peaklist='peaklist.txt'       output fname for ASCII peaklist
#'   \item fndem='stubai.asc'            input DEM (has to be GDAL conform)
#'}
#' \itemize{   
#'   \item [Projection]
#'   \item targetepsg='31254'             epsg code of DEM data 
#'   \item targetproj4='+proj=tmerc +lat_0=0 +lon_0=10.33333333333333 +k=1 +x_0=0 +y_0=-5000000 +ellps=bessel +towgs84=577.326,90.129,463.919,5.137,1.474,5.297,2.4232 +units=m +no_defs'  
#'   \item latlonproj4='+proj=longlat +datum=WGS84 +no_defs'
#'}
#' \itemize{
#'   \item [Params]
#'   \item makepeakmode=3        1=simple local minmax, 2=wood 3=fuzzylandforms
#'   \item filterkernelsize=9    size of filter for makepeak=1; range 3-30; default=9 
#'   \item externalpeaks='osm'   harry= Harrys Peaklist osm= OSM peak data
#'   \item mergemode=1           merging peak names from harry/OSM/user data 1=distance 2=costpath (slow)
#'   \item exactenough=5         prominnence treshold of vertical matching exactness (m)
#'   \item domthres=100          threshold of minimum dominance distance (makepeak=2&3)
#'}
#' \itemize{
#'   \item [Wood]               Wood parameters refers to SAGA
#'   \item WSIZE=11
#'   \item TOL_SLOPE=14.000000
#'   \item TOL_CURVE=0.00001
#'   \item EXPONENT=0.000000
#'   \item ZSCALE=1.000000
#'}
#' \itemize{
#'   \item [FuzzyLf]            FuzzyLandforms parameters refers to SAGA
#'   \item SLOPETODEG=0
#'   \item T_SLOPE_MIN=0.0000001
#'   \item T_SLOPE_MAX=25.000000
#'   \item T_CURVE_MIN=0.00000001
#'   \item T_CURVE_MAX=0.001
#'}
#'
#' \itemize{
#'   \item [SysPath]             SYSPAth for Linux and Windows 
#'   \item wossaga='C:/MyApps/GIS_ToGo/QGIS_portable_Chugiak_24_32bit/QGIS/apps/saga'
#'   \item wsagamodules='C:/MyApps/GIS_ToGo/QGIS_portable_Chugiak_24_32bit/QGIS/apps/saga/modules'
#'   \item wgrassgisbase='C:/MyApps/GIS_ToGo/GRASSGIS643/bin'
#'   \item lossaga='/home/creu/SAGA-2.1.0-fixed/initial/bin'
#'   \item lsagamodules='/home/creu/SAGA-2.1.0-fixed/initial/lib/saga'
#'   \item lgrassgisbase='/usr/lib/grass64'
#'   }
#'         
#' @docType data
#' @keywords datasets
#' @name input.INI
#' @usage iniparse('demo.ini')
#' @format Windows style INI file
NULL

#'@name Rpeak
#'@title Example script that can be used as a wrapper function to start the 
#'perfect peak analysis 
#'
#'@description Organises all necessary processing steps for calculating the 
#'perfect peak  parameters and generating the output. It  performs preprocessing 
#'and controls the calculations of dominance, prominence, independence (E) value 
#'for a given georeferencend Digital Elevation Model (DEM)
#'
#'You can use the function as it is or alternatively use it as skeleton control
#' script that you cab adapt to your needs.
#'
#'@usage Rpeak(fname.control,fname.DEM)
#' 
#'@param fname.control name of control file containing all setting and parameters for analysis
#'@param fname.DEM name Digtial Elevation Model has to be a GDAL raster file
#'
#'@author Chris Reudenbach 
#'
#'@references Marburg Open Courseware Advanced GIS: \url{http://moc.environmentalinformatics-marburg.de/doku.php?id=courses:msc:advanced-gis:description}
#'@references Rauch. C. (2012): Der perfekte Gipfel.  Panorama, 2/2012, S. 112 \url{http://www.alpenverein.de/dav-services/panorama-magazin/dominanz-prominenz-eigenstaendigkeit-eines-berges_aid_11186.html}
#'@references Leonhard, W. (2012): Eigenständigkeit von Gipfeln.\url{http://www.thehighrisepages.de/bergtouren/na_orogr.htm}
#'@return Rpeak returns the complete list as a dataframe of all parameters and results and 
#' generates some output (maps and tables)
#'
#'@seealso
#' \code{\link{initEnvironGIS}}, \code{\link{calculateDominance}}, 
#' \code{\link{calculateProminence}}, \code{\link{calculateEValue}}, 
#' \code{\link{makePeak}},
#'
#'@export Rpeak
#'@examples   
#'#### Example to use Rpeak for a common analysis of the 
#'     dominance, prominenece and independence values of an specifified area
#'
#' # You need a georeferenced DEM (GDAL format) as data input. 
#' # All parameters are read from the control INI file - use the 'demo.ini' as a template  
#' # NOTE the existing projection of the data file has to be exactly the same 
#' # as provided in target.proj4  variable in the ini file
#'
#'
#' ini.example=system.file("data","demo.ini", package="perfectPeak")
#' dem.example=system.file("data","test.asc", package="perfectPeak")
#' Rpeak(ini.example,dem.example)
#' 
#' 
Rpeak()

Rpeak <- function(fname.control, fname.DEM){
  
  # INI File
  fname.control <- "C:/Users/Jannik/Dropbox/Marburg/PackageProject/perfectPeak/R/control.ini"
  # DEM
  fname.DEM <- "C:/geography/advancedgis/perfectpeak/lz_10m_float_clip.asc"
  # Ordner mit den Funktionen
  path <- "C:/Users/Jannik/Dropbox/Marburg/PackageProject/perfectPeak/fun"
  
  # Funktion sourceDir
  source(file.path(path,"sourceDir.R"))
  # Funktionen aus dem path Pfad in die Umgebung holen mit der Funktion sourceDir
  sourceDir(path)
  
  # Umgebung neu definieren
  i <- initEnvironGIS(fname.control,fname.DEM)
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
  run.makePeak<- ini$Param$runmakePeak
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
