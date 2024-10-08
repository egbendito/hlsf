# bbox
pol <- terra::vect('/media/data/input/gadm/roi.gpkg', layer = 'roi')
bb <- terra::ext(pol)
bb <- data.frame("x" = c(bb[1][[1]],bb[2][[1]]), "y" = c(bb[3][[1]], bb[4][[1]]))

dir.create(path = paste0("/media/data/input/s5/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("/media/data/intermediate/forecast/"), recursive = TRUE, showWarnings = FALSE)

# Download ECMWF-S5 for specific year and transform
cat("\n Downloading ECMWF S51 seasonal forecast from C3S... \n")
year <- format(Sys.Date(), "%Y")
month <- format(Sys.Date(), "%m")
system(paste('python3 ./app/prc/s5download.py', year, month, bb[1,1], bb[2,1], bb[1,2], bb[2,2], sep = ' '))
x <- terra::rast(paste0("/media/data/intermediate/forecast/ecmwf_s5_rain_", year, "_", month, ".nc"))
o <- terra::rast()
for (lyr in 1:terra::nlyr(x)) {
  if (lyr == 1){
    terra::add(o) <- x[[lyr]]
  }
  else {
    s0 <- x[[lyr-1]]
    s1 <- x[[lyr]]
    s <- s1 - s0
    terra::add(o) <- s
  }
}
terra::crs(o) <- "EPSG:4326"
terra::time(o) <- seq(as.Date(paste0(year, "-", month, "-01"))+1, by = "day", length.out = terra::nlyr(o))
terra::writeCDF(o, paste0("/media/data/intermediate/forecast/ecmwf_s5_rain_", year, "_", month, ".nc"), overwrite=TRUE,
                unit="mm", varname = "tp", compression = 5)
y <- terra::rast(paste0("/media/data/intermediate/forecast/ecmwf_s5_tmax_", year, "_", month, ".nc"))
terra::crs(y) <- "EPSG:4326"
terra::time(y) <- seq(as.Date(paste0(year, "-", month, "-01"))+1, by = "day", length.out = terra::nlyr(y))
terra::writeCDF(y, paste0("/media/data/intermediate/forecast/ecmwf_s5_tmax_", year, "_", month, ".nc"), overwrite=TRUE,
                unit="°C", varname = "mx2t24", compression = 5)
cat("\n Seasonal forecast download completed... \n")
