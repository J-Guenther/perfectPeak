# Funktion, die von Anfang an im Perfect-Peak Script war
calculateDominance <- function(x.coord, y.coord, altitude, int=TRUE){
  # Calculates the Dominance Value for a given tuple of coordinates and altitude
  # as derived from DEM
  #
  # Args: x.coord: Value of the x axis coordinate y.coord: Value of the y axis
  # coordinate altitude: Value of the altitude
  #
  # Returns: The dominance value in meter
  
  #- we need to create a mask file nodata=no peaks/1= current peak to calculate
  # the proximity:
  # (1)  write x.coord, y.coord, altitude to an ASCII file
  # (2)  convert ASCII file to SHP file
  # (3)  create a raw raster file with nodata
  # (4)  write the position of the current peak into the raster with the cellvalue= 1
  
  # (R)  (1) write peak-tupel to csv format
  write.table(list(x.coord, y.coord, altitude), 'run.xyz', row.names = FALSE, col.names = c('1','2','3') , dec = ".",sep ='\t')
  # (SAGA) (2) create a point shapefile from the extracted line
  rsaga.geoprocessor("io_shapes", 3, env = myenv, list(X_FIELD="1", Y_FIELD="2", SHAPES="run_peak.shp", FILENAME="run.xyz"))
  # (SAGA) (3) create a nodata raster for rasterizing the peak position
  #  for running SAGA proximity a nodata grid is necessary 
  rsaga.grid.calculus('mp_fil_dem.sgrd', 'run_peak.sgrd','(a/a*(-99999))',env=myenv)
  # (RGDAL) (4) rasterize point Shape (current peak) into nodata raster file
  gdal_rasterize('run_peak.shp', 'run_peak.sdat', burn=1)
  
  
  #- (SAGA) dominance calculations needs 4 steps:
  # (1) calculate distance from peak to all grid cells in the raster
  # (2) create a mask raster with : all cells with an altitude <= current peak = nodata and all cells with an altitude > corrent peak = 1
  # (3) to derive the valid distance values multply mask raster with distance raster
  # (4) extract the minum distance valu from the resulting raster
  
  # (1) (SAGA) creates a distance raster with reference to the current peak
  #system('D:/Programme/OSGeo4W64/apps/saga/saga_cmd.exe grid_tools "Proximity Grid" -FEATURES run_peak.sgrd -DISTANCE run_dist.sgrd')
  rsaga.geoprocessor("grid_tools", "Proximity Grid", env = myenv, list(FEATURES="run_peak.sgrd", DISTANCE="run_dist.sgrd"))
  # (2) mask altitudes altidude >  current peak altitude
  # (SAGA) mask level >  floor(altitude)+1 set remaining grid to nodata
  rsaga.grid.calculus('mp_fil_dem.sgrd', 'run_level.sgrd', (paste0("ifelse(gt(a,", ceiling(altitude) ,"),1,-99999)")), env=myenv)
  
  # (3) (SAGA) multiply level-mask by proximity raster to keep all valid distance values
  rsaga.geoprocessor("grid_calculus", 1, env = myenv, list(GRIDS="run_level.sgrd;run_dist.sgrd", RESULT="run.sgrd", FORMULA="a*b"))
  
  # (4.1) (R) clean file garbage from occassional opening files with QGIS
  file.remove(list.files(file.path(root.dir, working.dir), pattern =('.sdat.aux.xml'), full.names = TRUE, ignore.case = TRUE))
  # (4.2) (GDAL) extractiong file Info
  file.info<-gdalinfo("run.sdat", mm = TRUE)
  # (4.3)( R) Minimum value is the dominance value
  dominance<-as.numeric(substring(file.info[29], regexpr("Min/Max=", file.info[29])+8,regexpr(",", file.info[29])-1))
  
  
  return (dominance)
}