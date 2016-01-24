searchProm <- function(peakRange, low, high, epsgnumber, GA_prom, peaklist_prom, exact.enough) {
  
  # Erste Bedingung: Funktion wird abgebrochen oder ausgeführt
  if ( high < low ) {                                # Ist die Obergrenze des Suchbereichs kleiner als die Untergrenze
    return("high wurde kleiner als low: Error")      # Wird die Funktion mit einer Fehlermeldung abgebrochen
  } 
  else {
    # Dem Prominenzwert wird sich mit einer Genauigkeit von 1 angenähert
    # WENN der Suchbereich (Differenz aus High und Low) KLEINER ODER GLEICH 1 ist, wird das aktuelle Niveau erzeugt und ausgegeben
    if ((high-low) <= exact.enough){
      niveau <- ceiling((low + high) / 2)
      return(niveau)
    } else {
      # Das Niveau ist die Variable, die den Prominenzwert finden soll. Sie repräsentiert die aktuelle Hoehe die überprüft wird
      # Das Niveau ergibt sich aus der Hälfte des Suchbereichs: Also aus der geteilten Summe von low und high
      # Das Niveau wird dabei mit ceiling() gerundet
      niveau <- ceiling((low + high) / 2)
      
      # WENN das Niveau UEBER dem Prominenzwert liegt (also prominence_true_false 1 zurueck gibt)
      # DANN soll searchProm erneut aufgerufen werden, jedoch soll die obere Grenze des Suchbereichs das aktuelle Niveau sein
      # Der gesuchte Wert kann nicht mehr Hoeher sein, als das Niveau, also wird der Suchbereich nach oben eingegrenzt
      if ( prominence_true_false(epsgnumber, GA_prom, peaklist_prom, peakRange[niveau]) == 1 )          
        return(searchProm(peakRange, low, niveau, epsgnumber, GA_prom, peaklist_prom,exact.enough))
      
      # WENN das Niveau UNTER dem Prominenzwert liegt (also prominence_true_false 0 zurueck gibt)
      # DANN soll searchProm erneut aufgerufen werden, jedoch soll die untere Grenze des Suchbereichs das aktuelle niveau sein
      # Der gesuchte Wert kann nicht mehr kleiner sein, als das Niveau, also wird der Suchbereich nach unten eingegrenzt
      else if ( prominence_true_false(epsgnumber, GA_prom, peaklist_prom, peakRange[niveau]) == 0 )
        return(searchProm(peakRange, niveau, high, epsgnumber, GA_prom, peaklist_prom, exact.enough))
    }
    
  }
}

prominence_true_false <- function(epsgnumber, GA_spd.df, list_spd.df, niveau){
  
  # Entferne polygon_niveau Shapefile, damit keine Überschreibungsfehler entstehen
  file.remove(list.files(file.path(root.dir, working.dir), pattern =('polygon_niveau'), full.names = TRUE, ignore.case = TRUE))
  
  
  # Maske erstellen. Alles ueber Gipfelniveau = 1, alles dadrunter oder gleich = NA
  rsaga.grid.calculus('mp_dem.sgrd', 'run_rcl.sgrd', (paste0("ifelse(gt(a,", ceiling(niveau) ,"),1,-99999)")), env=myenv)
  
  #Polygonisierung der Maske
  gdal.cmd <- paste0(osgeo_bat,' gdal_polygonize run_rcl.sdat -f "ESRI Shapefile" ', getwd(), ' run_polygon_niveau ID')
  system(gdal.cmd)
  
  #Einlesen der polygonisierten Maske
  vector <- readOGR("run_polygon_niveau.shp", layer = "run_polygon_niveau")
  vector$ID <- seq(vector$ID) #Erzeugung von korrekten ID-Werten um die Polygone unterscheiden zu können
  projection(vector) <- CRS(paste0("+init=epsg:", epsgnumber)) # Zuweisung der korrekten Projection
  
  #Ueberpruefung auf Intersection
  
  # Intersection mit Polygon pruefen und speichern: Dabei kommt heraus in welchem Polygon wie viele Gipfel sind
  intersect_GA <- over(GA_spd.df, vector, fn = sum)
  intersect_peaklist <- over(list_spd.df, vector, fn = sum)
  
  # Umwandeln der Insection-Ueberpruefung in Data Frame
  intersect_GA.table <- as.data.frame(table(intersect_GA$ID))
  print("Intersect GA Table:")
  print(intersect_GA.table)
  
  intersect_peaklist.table <- as.data.frame(table(intersect_peaklist$ID))
  print("Intersect Gipfelliste Table:")
  print(intersect_peaklist.table)
  
  # Ueberpruefen: In welchem Polygon liegt der GA?
  GA_poly_ID <- intersect_GA.table$Var1[which(intersect_GA.table$Freq == 1)]
  GA_poly_ID <- as.numeric(as.character(GA_poly_ID))
  print("ID vom Polygon mit GA:")
  print(GA_poly_ID)
  
  # Ueberpruefen: Wie viele andere Gipfel sind in dem Polygon?
  peaklist_freq <- intersect_peaklist.table$Freq[which(intersect_peaklist.table$Var1 == GA_poly_ID)]
  print("Peaklist Frequenz im Gipfelpolygon:")
  print(peaklist_freq)
  print("Niveau:")
  print(niveau)
  
  if(length(peaklist_freq) == 0){
    peaklist_freq <- 0
  } else {
    peaklist_freq <- peaklist_freq
  }
  
  # Wenn mehr Gipfel als der aktuelle Gipfel (GA) im Polygon sind, dann gib "1" zurück
  # Wenn NUR der aktuelle Gipfel (also 0 andere Gipfel) im Polygon sind, dann gib "0" zurück
  # Wenn gar nichts von beidem Eintritt: Fehlermeldung
  if (peaklist_freq == 0){
    print("1")
    return(1)
  } else if (peaklist_freq > 0){
    print(0)
    return(0)
  } else{
    print("Es ist kein Gipfel im Polygon")
  }
  
} 


calculateProminence <- function(peaks,x.coord, y.coord, altitude,exact.enough=5, epsg.code, int=TRUE){
  # Calculates the Prominence Value for a given tuple of coordinates and altitude
  # as derived from DEM
  #
  # Args: x.coord: Value of the x axis coordinate y.coord: Value of the y axis
  # coordinate altitude: Value of the altitude
  #
  # Returns: The prominence value in meter
  
  #--- doing some prepcocessing
  
  # first deleting all files that are related to the prominence function
  # due to the SAGA behaviour that is appending instead of overwriting the .mgrd xml files
  # (R) delete temporary files
  file.remove(list.files(file.path(root.dir, working.dir), pattern =('run_pro_'), full.names = TRUE, ignore.case = TRUE))
  
  #Lese aus der Variable epsg.code die Ziffern aus und speichere sie in epgsgnumber
  epsg.code.digit <- gregexpr('[0-9]+',epsg.code)
  epsg.code.digit
  epsgnumber <- regmatches(epsg.code,epsg.code.digit)
  
  # Erzeuge aktuellen Gipfel
  GA <- data.frame(xcoord = x.coord, ycoord = y.coord, altitude = altitude)
  # Erzeuge Liste der Gipfel, die Hoeher als GA sind
  peak_higherGA <- subset(peaks, peaks$altitude > GA$altitude)
  # Erzeuge Peakrange
  peakRange <- 1:GA$altitude
  
  #GA als SpatialPointDataframe mit korrekter Projektion
  GA_spd <- GA 
  coordinates(GA_spd) <- ~xcoord+ycoord 
  proj4string(GA_spd) <- CRS(paste0("+init=epsg:", epsgnumber)) 
  GA_spd.df <- SpatialPointsDataFrame(GA_spd, data.frame(id=1:length(GA_spd))) #Erzeuge einen SpatialPointsDataframe
  
  #Peaklist_prom als SpatialPointDataframe mit korrekter Projektion
  list_spd <- peak_higherGA 
  coordinates(list_spd) <- ~xcoord+ycoord 
  proj4string(list_spd) <- CRS(paste0("+init=epsg:", epsgnumber))
  list_spd.df <- SpatialPointsDataFrame(list_spd, data.frame(id=1:length(list_spd))) #Erzeuge einen SpatialPointsDataframe
  
  
  # Erzeuge Minimumwert des DEMs
  # (4.1) (R) clean file garbage from occassional opening files with QGIS
  file.remove(list.files(file.path(root.dir, working.dir), pattern =('.sdat.aux.xml'), full.names = TRUE, ignore.case = TRUE))
  # (4.2) (GDAL) extractiong file Info
  #file.info<-system('D:/Programme/OSGeo4W64/OSGeo4W.bat gdalinfo -mm mp_fil_dem.sdat', intern = TRUE)
  file.info<-gdalinfo("mp_dem.sdat", mm = TRUE)
  # (4.3)( R) Minimum value is the dominance value
  dgm_min<-as.numeric(substring(file.info[29], regexpr("Min/Max=", file.info[29])+8,regexpr(",", file.info[29])-1))
  
  
  
  
  # Aufrufen der Funktion
  schartenhoehe <- searchProm(peakRange, dgm_min, GA$altitude, epsgnumber, GA_spd.df, list_spd.df, exact.enough)
  prominence <- GA$altitude - schartenhoehe

  return (prominence)
}