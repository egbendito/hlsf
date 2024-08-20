chirps <- function(startDate, endDate, raster = FALSE, coordPoints = NULL){
  dates <- seq.Date(as.Date(startDate, format = "%Y-%m-%d"), as.Date(endDate, format = "%Y-%m-%d"), by = "day")
  year <- unique(format(dates, "%Y"))
  chirps <- terra::rast()
  for (file in list.files("/media/data/input/chirps", pattern = paste0(year, collapse = '|'), full.names = TRUE)) {
    terra::add(chirps) <- terra::rast(file)
  }
  names(chirps) <- as.character(format(as.Date(terra::time(chirps)), "%Y%m%d"))
  chirps <- chirps[[as.character(format(dates, format = "%Y%m%d"))]]
  if (raster){
    aoi <- suppressWarnings(terra::vect(sf::st_as_sf(sf::st_as_sfc(sf::st_bbox(c(xmin = min(coordPoints[,1]), xmax = max(coordPoints[,1]), ymax = max(coordPoints[,2]), ymin = min(coordPoints[,2])), crs = sf::st_crs(4326))))))
    chirps <- terra::crop(chirps,aoi)
    return(chirps)
  }
  else {
    w <- data.frame()
    for (pnt in seq(1:nrow(coordPoints))){
      lon <- coordPoints[pnt, 1]
      lat <- coordPoints[pnt, 2]
      z <- terra::extract(chirps,data.frame(lon,lat))
      out <- data.frame("dates" = dates)
      out$X <- lon
      out$Y <- lat
      out$RAIN <- as.vector(t(z[2:length(z)]))
      out <- data.frame("X" = out$X, "Y" = out$Y, "dates" = out$dates,
                      "year" = format(as.Date(out$dates), format = "%Y"),
                      "month" = format(as.Date(out$dates), format = "%m"),
                      "day" = format(as.Date(out$dates), format = "%d"),
                      "rain" = out$RAIN)
      w <- rbind(w, out)
    }
    return(w)
  }
}
