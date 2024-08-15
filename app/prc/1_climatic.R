# bbox
pol <- terra::vect('./data/input/gadm/roi.gpkg', layer = 'roi')
bb <- terra::ext(pol)
bb <- data.frame("x" = c(bb[1][[1]],bb[2][[1]]), "y" = c(bb[3][[1]], bb[4][[1]]))

# Load reference functions
source("chirts.R")
source("chirps.R")

# List of climatic files
file.checks <- c("./data/intermediate/climatic/climatic_monthly_prec.nc",
                 "./data/intermediate/climatic/climatic_monthly_tmax.nc",
                 "./data/intermediate/climatic/climatic_monthly_ts_prec.nc",
                 "./data/intermediate/climatic/climatic_monthly_ts_tmax.nc")

# Check if climate data file exists before processing everything
if(!all(file.exists(file.checks))){
  cat("\nProcessing climatic baseline (1983 - 2016)...\n")
  # Process climatic means
  years <- 1983:2016
  weights <- exp(-0.1*(years[length(years)]-years))
  tsp <- terra::rast()
  tst <- terra::rast()
  omp <- terra::rast()
  omt <- terra::rast()
  for (month in sprintf("%02d", 1:12)) {
    mp <- terra::rast()
    mt <- terra::rast()
    for (year in years) {
      days <- lubridate::days_in_month(as.Date(paste0(year, "-", month, "-01"), "%Y-%m-%d"))
      sdate <- paste0(year, "-", month, "-01")
      edate <- paste0(year, "-", month, "-", days)
      # Extract CHIRPS data for rainfall
      p <- chirps(startDate = sdate, endDate = edate, coordPoints = bb, raster = TRUE)
      p <- terra::app(p, fun = "sum", cores = 12)
      names(p) <- paste0(year, month, "_rain")
      terra::add(mp) <- p
      # Extract CHIRTS data for temperature
      t <- chirts(startDate = sdate, endDate = edate, coordPoints = bb, raster = TRUE)
      t <- terra::app(t, fun = "mean", cores = 12)
      names(t) <- paste0(year, month, "_tmax")
      terra::add(mt) <- t
    }
    # Process CHIRPS data for rainfall
    op <- terra::weighted.mean(mp, weights, na.rm = TRUE)
    names(op) <- paste0("rain_", month)
    terra::add(omp) <- op
    terra::add(tsp) <- mp
    # Process CHIRTS data for temperature
    ot <- terra::weighted.mean(mt, weights, na.rm = TRUE)
    names(ot) <- paste0("tmax_", month)
    terra::add(omt) <- ot
    terra::add(tst) <- mt
  }
  # Write intermediate monthly aggregates
  dir.create(path = paste0("./data/intermediate/climatic/"), recursive = TRUE, showWarnings = FALSE)
  terra::writeCDF(omp, "./data/intermediate/climatic/climatic_monthly_prec.nc", overwrite=TRUE, unit="mm", compression = 5)
  terra::writeCDF(omt, "./data/intermediate/climatic/climatic_monthly_tmax.nc", overwrite=TRUE, unit="C", compression = 5)
  terra::writeCDF(tsp, "./data/intermediate/climatic/climatic_monthly_ts_prec.nc", overwrite=TRUE, unit="mm", compression = 5)
  terra::writeCDF(tst, "./data/intermediate/climatic/climatic_monthly_ts_tmax.nc", overwrite=TRUE, unit="C", compression = 5)
} else {
  cat("\nClimatic baseline (1983 - 2016) already processed.\n")
}
