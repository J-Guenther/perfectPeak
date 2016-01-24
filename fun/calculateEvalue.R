calculateEValue <- function(altitude, dom, prom){
  # Calculates the Prominence Value for a given tuple of coordinates and altitude as derived from DEM 
  #
  # Args:
  #   dom:         dominance value
  #   prom:        prominence value
  #   altitude:    current peaks altitude
  # Returns:
  #   independence (E) value 
  
  
  if(dom < 100000){
    e <- (-1)*((log(2*(altitude/8848))+log(2*(dom/100000))+log(2*(prom/altitude)))/3)
  } else{
    e <- (-1)*((log(2*(altitude/8848))+log(2*(prom/altitude)))/3)
  }
  
  return(e)
} 