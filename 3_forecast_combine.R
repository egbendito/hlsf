# Nigeria bbox
NGA <- terra::vect('./data/input/gadm/gadm36_NGA.gpkg', layer = 'gadm36_NGA_1')
bb <- terra::ext(NGA)
bb <- data.frame("x" = c(bb[1][[1]],bb[2][[1]]), "y" = c(bb[3][[1]], bb[4][[1]]))

# Load climatic
omp <- terra::rast("./data/intermediate/climatic/climatic_monthly_prec.nc")
omt <- terra::rast("./data/intermediate/climatic/climatic_monthly_tmax.nc")

# Load forecast
year <- format(Sys.Date(), "%Y")
months <- format(seq(Sys.Date(), by = paste (1, "months"), length = 6), "%m")
t.f <- terra::rast(paste0("./data/intermediate/forecast/ecmwf_s5_tmax_", year, ".nc")) # Load seasonal forecast tmax
p.f <- terra::rast(paste0("./data/intermediate/forecast/ecmwf_s5_rain_", year, ".nc")) # Load seasonal forecast prec

# monthly stack (sum of daily values)
# make a monthly index first
names(t.f) <- format(terra::time(t.f), "%m")
names(p.f) <- format(terra::time(p.f), "%m")
# aggregate the stack
t.f.m = terra::tapp(t.f, index = names(t.f), fun = mean)
p.f.m = terra::tapp(p.f, index = names(p.f), fun = sum)

# Forecast at highest resolution with interpolation
re <- terra::extend(omp, terra::ext(NGA) + 1) # Extend AOI
p.f.m.r <- terra::resample(p.f.m, re, method = "bilinear") # Interpolate with a first-order bilinear spline technique across an extent larger than our high-resolution climatology dataset
t.f.m.r <- terra::resample(t.f.m, re, method = "bilinear") # Interpolate with a first-order bilinear spline technique across an extent larger than our high-resolution climatology dataset
# Extract data
data.p <- as.data.frame(omp, xy = T, na.rm = FALSE, cells = T)
# colnames(data.p)[4:9] <- paste0("clim_rain_", sprintf("%02d", as.integer(gsub("climatic_monthly_prec_", "", colnames(data.p)[4:9]))+3))
colnames(data.p)[4:9] <- paste0("clim_rain_", months)
colnames(data.p)[1] <- "ID"
data.t <- terra::extract(omt, data.p[,c(2,3)])
# colnames(data.t)[2:7] <- paste0("clim_tmax_", sprintf("%02d", as.integer(gsub("climatic_monthly_tmax_", "", colnames(data.t)[2:7]))+3))
colnames(data.t)[2:7] <- paste0("clim_tmax_", months)
data <- merge(data.p, data.t, by = "ID")
d <- terra::extract(p.f.m.r[[1]], data[,c(2,3)])
colnames(d) <- c("ID", paste0("forecast_rain_", gsub("X","", colnames(d)[2])))
for (lyr in 2:6) {
  l <- p.f.m.r[[lyr]]
  ll <- terra::extract(l, data[,c(2,3)])
  colnames(ll) <- c("ID", paste0("forecast_rain_", gsub("X","", colnames(ll)[2])))
  d <- merge(d,ll, by="ID")
}
data <- merge(data, d, by = "ID")
c <- terra::extract(t.f.m.r[[1]], data[,c(2,3)])
colnames(c) <- c("ID", paste0("forecast_tmax_", gsub("X","", colnames(c)[2])))
for (lyr in 2:6) {
  l <- t.f.m.r[[lyr]]
  ll <- terra::extract(l, data[,c(2,3)])
  colnames(ll) <- c("ID", paste0("forecast_tmax_", gsub("X","", colnames(ll)[2])))
  c <- merge(c,ll, by="ID")
}
data <- merge(data, c, by = "ID")

# Write outputs
out <- data
tsp <- terra::rast("./data/intermediate/climatic/climatic_monthly_ts_prec.nc")
tst <- terra::rast("./data/intermediate/climatic/climatic_monthly_ts_tmax.nc")
np <- c()
nt <- c()
# for (month in sprintf("%02d", 4:9)) {
for (month in months) {
  for (year in 1983:2016) {
    nt <- c(nt, paste0(year, month, "_tmax"))
    np <- c(np, paste0(year, month, "_rain"))
  }
}
names(tsp) <- np
names(tst) <- nt
out <- data
for (v in c("rain", "tmax")) {
  if(v == "rain"){r <- tsp} else {r <- tst}
  n <- length(months)
  # for (month in sprintf("%02d", 4:9)) {
  for (month in months) {
    # month <- sprintf("%02d", seq(as.integer(month), ifelse(as.integer(month)+6 > 9, 9, as.integer(month)+6), length.out = ))
    month <- format(seq(Sys.Date(), by = paste (1, "months"), length = n), "%m")
    n <- n - 1
    rr <- r[[grep(paste0(paste0(rep(1983:2016, each = length(month)), month, collapse="|"), "_", v), names(r), value=TRUE)]]
    rr <- rr[[order((as.integer(substr(names(rr), start = 1, stop = 4))))]] # Re-ordering by year
    if(v == "rain"){
      rr <- terra::tapp(rr, index = rep(1:length(1983:2016), each = length(month)), fun = sum)
    } else {
      rr <- terra::tapp(rr, index = rep(1:length(1983:2016), each = length(month)), fun = mean)
    }
    qr <- terra::quantile(rr, seq(0,1,0.2), na.rm = T)
    q <- terra::extract(qr, data[,c(2,3)])[,c("ID","q0.2","q0.4","q0.6","q0.8")]
    out <- merge(out, q, by = "ID")
    f <- out[,c(paste0("forecast", "_", v, "_", month), "q0.2", "q0.4", "q0.6", "q0.8")]
    if(v == "rain" & length(paste0("forecast", "_", v, "_", month)) > 1){
      ft <- ifelse(rowSums(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) <= f$q0.2, "Very Low",
                   ifelse(rowSums(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) < f$q0.4, "Low",
                          ifelse(rowSums(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) < f$q0.6, "Average",
                                 ifelse(rowSums(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) < f$q0.8, "High",
                                        ifelse(rowSums(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) >= f$q0.8, "Very High", NA)))))
    }
    else if(v == "tmax" & length(paste0("forecast", "_", v, "_", month)) > 1){
      ft <- ifelse(rowMeans(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) <= f$q0.2, "Very Low",
                   ifelse(rowMeans(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) < f$q0.4, "Low",
                          ifelse(rowMeans(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) < f$q0.6, "Average",
                                 ifelse(rowMeans(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) < f$q0.8, "High",
                                        ifelse(rowMeans(f[,paste0("forecast", "_", v, "_", month)], na.rm = F) >= f$q0.8, "Very High", NA)))))
    } else {
      ft <- ifelse(f[,paste0("forecast", "_", v, "_", month)] <= f$q0.2, "Very Low",
                   ifelse(f[,paste0("forecast", "_", v, "_", month)] < f$q0.4, "Low",
                          ifelse(f[,paste0("forecast", "_", v, "_", month)] < f$q0.6, "Average",
                                 ifelse(f[,paste0("forecast", "_", v, "_", month)] < f$q0.8, "High",
                                        ifelse(f[,paste0("forecast", "_", v, "_", month)] >= f$q0.8, "Very High", NA)))))
    }
    out <- cbind(out,ft)
    colnames(out)[length(colnames(out))] <- paste0("text", "_", v, "_", paste0(month[1],"-",month[length(month)]))
    colnames(out)[grepl("q", colnames(out))] <- paste0("threshold", "_", v, "_", paste0(month[1],"-",month[length(month)]), "_", as.integer(gsub("^.*\\.","", colnames(out)[grepl("q", colnames(out))]))*10)
    out <- out[, colnames(out)[!grepl("q", colnames(out))]]
  }
}
oout <- out[complete.cases(out),c(1,2,3,grep(paste0("text", "_"), colnames(out)))]
dir.create(path = paste0("./data/output/"), recursive = TRUE, showWarnings = FALSE)
write.table(oout, "./data/output/forecast_2023_seas_Sprout.csv", row.names = FALSE, sep = ",")
