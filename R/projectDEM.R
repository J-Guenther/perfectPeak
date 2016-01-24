projectDEM <- function(dem.in, epsg, int=TRUE){
  # Diese Funktion dient dazu dem Höhenmodell eine Projektion zuzuweisen.
  # Falls die Gipfelliste schon vorliegt und die makePeak Funktion auf false gesetzt ist,
  # dann fehlt die Zuweisung einer Projektion, da dies nur in der makePeak Funktion stattfindet
  # Diese Funktion soll Abhilfe schaffen und dafür sorgen, dass das DEM auch ohne der Ausführung
  # der makePeak Funktion eine Projektion zugewiesen bekommt
  
  
  of='-of SAGA'
  fname='mp_dem.sdat'
  
  # (GDAL) gdalwarp is used to (1) convert the data format (2) assign the
  # projection information to the data.
  # generate the gdalwarp command string
  gdalwarp(dem.in, fname, s_srs=c(epsg.code), of=c('SAGA'), overwrite=T )
  
}