import numpy as np
import time
import os
import sys
import xarray as xr # Need to install
import cdsapi # Need to install


year = int(sys.argv[1])
month = int(sys.argv[2])
xmin = float(sys.argv[3])
xmax = float(sys.argv[4])
ymin = float(sys.argv[5])
ymax = float(sys.argv[6])
area = [ymax, xmin, ymin, xmax,]

c = cdsapi.Client()

variables = ['total_precipitation', 'maximum_2m_temperature_in_the_last_24_hours']

for var in variables:
    if var == 'total_precipitation':
      times = ["{:01d}".format(n) for n in range(24, 5166, 24)]
      out = './data/input/s5/ecmwf_s5_rain_' + str(year) + '.nc'
    else:
      times = ["{:01d}".format(n) for n in range(24, 5166, 24)]
      out = './data/input/s5/ecmwf_s5_tmax_' + str(year) + '.nc'
    c.retrieve(
        'seasonal-original-single-levels',
        {
            'format': 'netcdf',
            'variable': var,
            'originating_centre': 'ecmwf',
            'system': '51',
            'year': year,
            'month': month,
            'day': '01',
            'leadtime_hour': times,
            'area': area,
        },
        out
    )
    time.sleep(1)
    if var == 'total_precipitation':
      rain = xr.open_dataset('./data/input/s5/ecmwf_s5_rain_' + str(year) + '.nc')
      rain = rain * 1000
      rain = rain.mean(dim = 'number')
      rain.to_netcdf('./data/intermediate/forecast/ecmwf_s5_rain_' + str(year) + '.nc')
    else:
      tmax = xr.open_dataset('./data/input/s5/ecmwf_s5_tmax_' + str(year) + '.nc')
      tmax = tmax-273.15
      tmax = tmax.mean(dim = 'number')
      tmax.to_netcdf('./data/intermediate/forecast/ecmwf_s5_tmax_' + str(year) + '.nc')
  
        
