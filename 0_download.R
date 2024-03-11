# ROI
iso <- c("NGA")

origin<- getwd()

dir.create(path = paste0("./data/input/gadm/"), recursive = TRUE, showWarnings = FALSE)

if(!file.exists("./data/input/gadm/roi.gpkg")){
  # Download files
  for (i in iso) {
    url <- paste0("https://geodata.ucdavis.edu/gadm/gadm4.1/gpkg/gadm41_", i, ".gpkg")
    dir.create("./data/input/gadm/", showWarnings = FALSE)
    download.file(url, destfile = paste0("./data/input/gadm/gadm41_", i, ".gpkg"))
  }

  # Merge files
  # Check validity of geometries
  if (length(list.files("./data/input/gadm/", pattern = ".gpkg")) > 1) {
    fname <- paste0("./data/input/gadm/gadm41_", iso[1], ".gpkg")
    A <- sf::st_read(paste0("./data/input/gadm/gadm41_", iso[1], ".gpkg"), layer = sf::st_layers(fname)[[1]][1], quiet = T)
    for (l in sf::st_layers(fname)[2]) {
      pol <- sf::st_read(fname, layer = l[length(l)], quiet = T)
      A <- sf::st_union(dplyr::bind_rows(list(A,pol)), by_feature = T)
    }
    for (f in list.files("./data/input/gadm/", pattern = ".gpkg")[2:length(list.files("./data/input/gadm/",pattern = ".gpkg"))]) {
      iso <- substr(gsub(".gpkg","",f), 8,10)
      fname <- paste0("./data/input/gadm/", f)
      for (l in sf::st_layers(fname)[[1]][2:length(sf::st_layers(fname)[[1]])]) {
        pol <- sf::st_read(fname, layer = l, quiet = T)
        A <- sf::st_union(dplyr::bind_rows(list(A,pol)), by_feature = T)
      }
    }
  } else {
    fname <- paste0("./data/input/gadm/gadm41_", iso[1], ".gpkg")
    A <- sf::st_read(paste0("./data/input/gadm/gadm41_", iso[1], ".gpkg"), layer = sf::st_layers(fname)[[1]][1], quiet = T)
    for (l in sf::st_layers(fname)[[1]][2:length(sf::st_layers(fname)[[1]])]) {
      pol <- sf::st_read(fname, layer = l, quiet = T)
      A <- sf::st_union(dplyr::bind_rows(list(A,pol)), by_feature = T)
    }
  }
  sf::write_sf(obj = A, dsn = "./data/input/gadm/roi.gpkg", layer = "roi", append = FALSE)
}

setwd(origin)

cat('\n Succesfully completed GADM download')

## CHIRPS
vars <- c("prec", "tmax")
names(vars) <- c("chirps", "chirts")
years <- seq(1983, 2016, 1)
pol <- terra::vect("./data/input/gadm/roi.gpkg", layer = "roi")
bb <- terra::ext(pol)
origin<- getwd()

cat('\n #############################################################################\n')

for (i in seq_along(vars)) {
  vname <- names(vars[i])
  v <- vars[i][[1]]
  dir.create(path = paste0("./data/input/", vname), recursive = TRUE, showWarnings = FALSE)
  for (year in years){
    if(!file.exists(paste0("./data/input/", vname, "/", year, ".nc"))){
      if(vname == "chirps"){
        file <- list.files("/home/jovyan/common_data/chirps_af/chirps/netcdf", full.names = TRUE, pattern = paste0(year, collapse = '|'))
      }
      else {
        file <- list.files("/home/jovyan/common_data/chirts/netcdf/tmax/africa", full.names = TRUE, pattern = paste0(year, collapse = '|'))
      }
      R <- terra::rast(file)
      R <- terra::crop(R, bb)
      terra::writeCDF(R, filename = paste0("./data/input/", vname, "/", year, ".nc"), prec = "float", compression = 5, overwrite = TRUE)
      cat(paste0("\n Processing ", toupper(vname), " for year ", year))
    }
  }
}

setwd(origin)

cat('\n #############################################################################\n')
