#' Calculation of the independence-value
#'
#' This function calculates the independence-value. 
#'@author Luise Wraase, Jannik Günther, Henning Reinarz und Johannes Schaal <team1@none.com>,  
#' \cr
#' \emph{Maintainer:} Luise Wraase, Jannik Günther, Henning Reinarz und Johannes Schaal \email{team1@none.com}
#' @references \url{http://www.alpenverein.de/chameleon/public/e73377b2-4b18-f439-1392-c5758cd00d88/Panorama-2-2012-Prominente-Berge_19663.pdf} 
#' @param altitude The altitude of the peak to be calculated
#' dom The dominance of the peak to be calculated
#' prom The prominence of the peak to be calculated
#' @return The independence-value 
#' @export calculateEValue

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
