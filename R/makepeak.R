#' Generation of a Peaklist
#'
#' This function generates a raw list of local maxima and corresponding altitudes that 
#' will be assumed as peaks.
#'@author Luise Wraase, Jannik GÃ¼nther, Henning Reinarz und Johannes Schaal <team1@none.com>,  
#' \cr
#' \emph{Maintainer:} Luise Wraase, Jannik GÃ¼nther, Henning Reinarz und Johannes Schaal \email{team1@none.com}
#'   
#' @param dem.in A digital elevation model from which peaks will be extracted
#' peak.list Name of the  the ASCII file containing all peak parameters
#' mode 1=minmax,2=wood,3=harry
#' kernel.size Size of filter kernel in pixel, default=3. 
#' @return List of with the the x-coordiantes, y-coordinates and altitutes of the found peaks
#' @export makePeak
makePeak <- function(dem.in, peak.list,make.peak.mode,epsg,kernel.size=3,myenv, int=TRUE){
  #  Wrapper function that generates a raw list of local maxima and
  #  corresponding altitudes that will be assumed as peaks. Available are:
  #  (1) minmax: extracts local maxima altitudes from an arbitrary Digital
  #      Elevation Model (DEM) (optionally you may filter the data)
  #  (2) wood: extract peaks from a DEM by analyzing morphometry and
  #      landscape forms using the algorithm of Jo Wood (not implemented yet)
  #  (3) Extract peaks from "Harry's Bergliste" (not implemented yet)
  #
  #  The raw output will be cleaned up using the function CleanPeakLists()
  #
  # Args:
  #   dem.in:     name of the original DEM
  #   peak.list:  name of the  the ASCII file containing all peak parameters
  #   mode:       1=minmax,2=wood,3=harry
  #   kernel.size size of filter kernel in pixel, default=3
  #
  # Returns:
  #   the peak list as data frame
  dem.in <- "C:/geography/advancedgis/perfectpeak/lz_10m_float_clip.asc"
  epsg <- 'EPSG:31255'
  str(epsg)
  # (1=SAGA) (2=GRASS, 3=gdal both not not implemented)
  if (make.peak.mode==1){
    #-- option 1 SAGA  makes use of the system() function of R to run commands
    # in the shell of the used OS This is very straightforward and usually there
    # is no connection between 'outside R' and 'inside R' you just start the
    # command line commands from R insteas of using the shell
    
    of='-of SAGA'
    fname1='mp_dem.sdat'
    
    gdal_setInstallation(search_path = "C:/OSGeo4W64/bin")
    valid.install<-!is.null(getOption("gdalUtils_gdalPath"))
    if (!valid.install){stop('no valid GDAL/OGR found')} else{print('gdalUtils status is ok')}
    
    # (GDAL) gdalwarp is used to (1) convert the data format (2) assign the
    # projection information to the data.
    # generate the gdalwarp command string
    gdalwarp(dem.in, fname1, s_srs=c(epsg), of=c('SAGA'), overwrite=T )
    
    # (SAGA) generate the filter command string
    print('Filtering the DEM - may take a while...')
    rsaga.filter.gauss("mp_dem.sgrd", "mp_fil_dem.sgrd", 1, kernel.size, env = myenv)
    
    # (SAGA) extract local minimum and maximum coordinates and altitude values from "fil_dem"
    rsaga.geoprocessor("shapes_grid", "Local Minima and Maxima", env = myenv, list(GRID="mp_fil_dem.sgrd",
                                                                                   MINIMA="mp_min",
                                                                                   MAXIMA="mp_max"))
    
    # (SAGA) generate convert shp 2 ASCII command string
    rsaga.geoprocessor("io_shapes", 2, env = myenv, list(FIELD="Z", SEPARATE="0", SHAPES="mp_max.shp", FILENAME="run_peak_list.txt"))
    
    
    ### generate peaklist from make.peak.mode=1
    # (R) read the converted max data was stored in "run_peak_list.txt" into a data frame
    df=read.table("run_peak_list.txt",  header = FALSE, sep = "\t",dec='.')
    
    # Bereinige "run_peak_list.txt" von den NoData-Werten
    # Wandle die Spalte der Z-Werte in numerische Werte um, um mit ihnen rechnen zu können
    df$V3 <- as.numeric(as.character(df$V3))
    # speichere in der Variable df alle Z-Werte, die größer/gleich 0 und kleiner/gleich 8848 sind
    # Das ist notwendig um die -99999 Werte und die 700000000 Werte (also die NoDATA-Werte) zu eliminieren
    df <- df[df$V3 >= 0 & df$V3 <= 8848,]
    # Wandle die Spalte mit den X und Y Werte ebenfalls in numerische Werte um
    df$V1 <- as.numeric(as.character(df$V1))
    dfV2 <- as.numeric(as.character(df$V2))
    
    # (R) delete headline
    #df<-df[-c(1), ]
    # (R) name the cols
    colnames(df)=c("xcoord","ycoord","altitude")
    # (R) sort by altitude
    df<-df[order(df$altitude, decreasing=TRUE),]
    # (R) add required cols
    df['dominance'] <-NA
    df['prominence'] <-NA
    df['name'] <-NA
    df['E'] <-NA
    write.table(df,peak.list,row.names=F)
  } else {
    stop("not implemented yet")
  }
  return(df)
}