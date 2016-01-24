#' Calculation of the independence-value
#'
#' This function calculates the independence-value from a digital elevation model. 
#'@author Luise Wraase, Jannik GÃ¼nther, Henning Reinarz und Johannes Schaal <team1@none.com>,  
#' \cr
#' \emph{Maintainer:} Luise Wraase, Jannik GÃ¼nther, Henning Reinarz und Johannes Schaal \email{team1@none.com}
#'@references \url{http://www.alpenverein.de/chameleon/public/e73377b2-4b18-f439-1392-c5758cd00d88/Panorama-2-2012-Prominente-Berge_19663.pdf} 
#'
#' @param fname.control 
#' @param fname.DEM The path to the digital elevation model
#'
#' @return The independence-value 
#' @export Rpeak




Rpeak <- function(fname.control, fname.DEM){
  
  # INI File
  fname.control <- "C:/Users/Jannik/Dropbox/Marburg/PackageProject/perfectPeak/R/control2.ini"
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
  myenv <- i$myenv
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
  kernel.size <- as.numeric(ini$Params$filterkernelsize) # Size of filter for mode=1; range 3-30, default= 3
  make.peak.mode <- ini$Param$makepeakmode # mode:1=minmax, 2=wood$co
  run.makePeak<- ini$Param$runmakePeak
  exact.enough <- as.numeric(ini$Params$exactenough) # Annaehrungswert beim Fluten für die Prominenz
  epsg.code <- ini$Projection$targetepsg #EPSG Code
  target.proj4 <- ini$Projection$targetproj4 # correct string from the ini file
  latlon.proj4 <- ini$Projection$latlonproj4 # basic latlon wgs84 proj 4 string
  
  
  # (R) call MakePeak if necessary
  if (run.makePeak) {
    final.peak.list<-makePeak(dem.in, peak.list,make.peak.mode,epsg.code, kernel.size, myenv)
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
  #file.remove(list.files(file.path(root.dir, working.dir), pattern =('mp_'), full.names = TRUE, ignore.case = TRUE))
  #file.remove(list.files(file.path(root.dir, working.dir), pattern =('run'), full.names = TRUE, ignore.case = TRUE))
  
  print("That's it")
  
}

