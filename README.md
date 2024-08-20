# Hyper-local Seasonal Forecasts

This repository contains the workflow to produce seasonal weather forecasts in collaboration with [Sprout Open Content ](https://www.sproutopencontent.com/). The tool uses several data sources listed below to create historical baselines (1983 - 2016) as a reference to compare with the seasonal weather forecasts from ECMWF-S51 and calculate quantiles. The tool needs to be updated on a monthly basis (6th day of each month).

## Requirements:
- Docker installed
- [CDS API](https://cds-beta.climate.copernicus.eu/how-to-api)

## Deployment:

### 1. Pull existing image:
```
docker pull egbendito/eia-transform:hlsf-last
```

### 2. Set-up:
```
docker run -it --rm --name hlsf -v /path/to/your/volume:/media egbendito/eia-transform:hlsf-last setup-hlsf $ISO3
```
For the first time (or any subsequent re-deployments) you will need to set-up the tool. This downloads historical data, and creates the baseline for the country you select (`$ISO3`). Please, substitute `$ISO3` for the 3-letter code of your country of interest (see [here](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3)). Make sure you mount a persistent volume on the container to be able to persist the data. It will be mapped to the `/media` folder of the container.

### 3. Update forecasts: 
```
docker run -it --rm --name hlsf -v /path/to/your/volume:/media/hlsf egbendito/eia-transform:hlsf-last update-hlsf
```
This uses the [CDS API](https://cds-beta.climate.copernicus.eu/how-to-api), which should be placed in the directory you are mounting to the container (`/path/to/your/volume`) in a file called `.cdsapirc` with the following structure:
```
url: https://cds-beta.climate.copernicus.eu/api
key: your_api_key_here
```

### 4. Results:
You will be able to retrieve all the data, including the outputs from your `/path/to/your/volume/data/`. There you'll find:
- inputs:
```
├── chirps
│   ├── 1983.nc
│   ├── ...
│   └── 2016.nc
├── chirts
│   ├── 1983.nc
│   ├── ...
│   └── 1984.nc
├── gadm
│   ├── gadm41_$ISO3.gpkg
│   └── roi.gpkg
└── s5
    ├── ecmwf_s5_rain_$YEAR_$MONTH.nc
    ├── ...
    └── ecmwf_s5_tmax_$YEAR_$MONTH.nc
```
- intermediate:
```
├── climatic
│   ├── climatic_monthly_prec.nc
│   ├── climatic_monthly_tmax.nc
│   ├── climatic_monthly_ts_prec.nc
│   └── climatic_monthly_ts_tmax.nc
└── forecast
    ├── ecmwf_s5_rain_$YEAR_$MONTH.nc
    ├── ...
    └── ecmwf_s5_tmax_$YEAR_$MONTH.nc
```
- outputs:
```
├── sprout_forecast_s5_$YEAR_$MONTH-( $MONTH + 9 ).csv
└── ...
```

## Data Sources:

| Source | URL |
|---|---|
| C3S | https://cds-beta.climate.copernicus.eu/datasets/seasonal-original-single-levels |
| GADM | https://gadm.org/index.html |
| CHIRPS | https://chc.ucsb.edu/data/chirps |
| CHIRTS | https://chc.ucsb.edu/data/chirtsdaily |

## Acknowledgements:

![](https://static.wixstatic.com/media/062a35_abb888b49e6143ee81b91ecf8299543f~mv2.png/v1/fill/w_302,h_84,al_c,q_85,usm_0.66_1.00_0.01,enc_auto/062a35_abb888b49e6143ee81b91ecf8299543f~mv2.png) ![](https://eia.cgiar.org/_next/image?url=%2Fimages%2Flogos%2Feia-logo-full.png&w=256&q=75)