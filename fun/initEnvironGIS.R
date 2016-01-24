#'@name initEnvironGIS
#'
#'@title Function that initializes RSAGA, GRASS GDAL and the R packages 
#'
#'@description Function that initializes environment pathes, SAGA, GRASS and GDAL support (and the bindings to the corresponding R packages and the R packages *NOTE* you probably have to customize some settings ini file
#' 
#'@usage initEnvironGIS(ini.file)
#'
#'@param ini.file name of the session ini.file
#'@param DEMfname name of used raster DEM (GDAL format)
#'
#'@author Chris Reudenbach 
#'
#'
#'@return initEnvironGIS initializes the usage of the GIS packages and other utilities
#'@export initEnvironGIS
#'
#'@examples   
#'#### Example to initialize the enviroment and GIS bindings for use with R
#'#### uses the ini list from an ini file
#'       
#' ini.example=system.file("demo.ini", package="perfectPeak")
#' dem.example=system.file("test.asc", package="perfectPeak")
#' initEnvironGIS(ini.example,dem.example)
#' gmeta6()
#' 

initEnvironGIS <- function(fname,DEMfname){
  
  # check for packages and if necessary install libs 
  libraries<-c("downloader","sp","raster","maptools","osmar",
               "RSAGA","rgeos","gdata","Matrix","igraph",
               "rgdal","gdistance", "spgrass6", "gdalUtils")
  
  # Install CRAN packages (if not already installed)
  inst <- libraries %in% installed.packages()
  if(length(libraries[!inst]) > 0) install.packages(libraries[!inst])
  
  # Load packages into session 
  lapply(libraries, require, character.only=TRUE)
  
  # get environment
  ini<-iniParse(fname)  
  
  # (R) assign local vars for working folder 
  root.dir <- ini$Pathes$workhome               # project folder 
  working.dir <- ini$Pathes$runtimedata         # working folder 
  
  ### assign correct projection information
  # To derive the correct proj.4 string for Austria MGI (EPSG:31254) is very NOT straightforward
  # please refer to: http://moc.environmentalinformatics-marburg.de/doku.php?id=courses:msc:advanced-gis:code-examples:ag-ce-09-01
  # taget EPSG code
  epsg.code<-ini$Projection$targetepsg
  
  # target projection (actually the projection of the DEM)
  target.proj4<-ini$Projection$targetproj4
  
  # we will also need the  basic latlon wgs84 proj4 string
  latlon.proj4<-as.character(CRS("+init=epsg:4326")) 
  
  ### now starting the setup of the packages bindings
  
  
  ## (gdalUtils) check for a valid GDAL binary installation on your system
  # Sollte kein GDAL gefunden werden, ist es nicht korrekt installiert, oder der search_path muss angepasst werden
  gdal_setInstallation(search_path = "C:/OSGeo4W64/bin")
  valid.install<-!is.null(getOption("gdalUtils_gdalPath"))
  if (!valid.install){stop('no valid GDAL/OGR found')} else{print('gdalUtils status is ok')}
  
  
  # (R) set working directory
  setwd(file.path(root.dir, working.dir))
  workingpath <- file.path(root.dir, working.dir)
  
  
  # Definiere die Umgebungen für RSAGA und die Pfade für die OSGeo4W shell und die saga_cmd für Windows oder Linux
  if(Sys.info()["sysname"] == "Windows"){
    # (RSAGA) define SAGA environment Windows
    myenv=rsaga.env(check.libpath=FALSE,
                    check.SAGA=FALSE,
                    workspace=file.path(root.dir, working.dir),
                    os.default.path="C:/OSGeo4W64/apps/saga",
                    modules="C:/OSGeo4W64/apps/saga/modules")
    # Definiere Pfade zu den Shells
    osgeo_bat <- "C:/OSGeo4W64/OSGeo4W.bat" # Pfad zur OSGeo4W.bat
    saga_cmd <- "C:/OSGeo4W64/apps/saga/saga_cmd.exe" # Pfad zur saga_cmd.exe
    saga_cmd_new <- "C:/OSGeo4W64/apps/saga-new/saga_cmd.exe" #Pfad zur saga_cmd.exe einer neuen SAGA Version
    #INFO: Getestet wurde das Script mit SAGA 2.1.2. Bis auf einen Befehl lief das Script einwandfrei
    #Der Befehl zur erstellung des Proximity-Grid in der Funktion calculateDominance2 funkttionierte nur in SAGA 2.2.2, daher 
    #existiert hier ein extra Pfad zur cmd der neuen Version.
    
  }else if (Sys.info()["sysname"] == "Linux"){ # (RSAGA) define SAGA environment Linux
    myenv=rsaga.env(check.libpath=FALSE,
                    check.SAGA=FALSE,
                    workspace=file.path(root.dir, working.dir),
                    os.default.path="/home/creu/SAGA-2.1.0-fixed/initial/bin",
                    modules="/home/creu/SAGA-2.1.0-fixed/initial/lib/saga")
    
    # Definiere Pfade zu den Shells
    osgeo_bat <- "" 
    saga_cmd <- "saga_cmd"
    saga_cmd_new <- "saga_cmd"
  }  
  
  
  # (R) set R working directory
  setwd(file.path(root.dir, working.dir))
  getwd()

  
  # provide myenv and parameterlist for common use
  result=list(ini,myenv)
  names(result)=c('ini','myenv')
  return (result)  
}

