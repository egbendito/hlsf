import numpy as np
import time
import os
import sys
import xarray as xr
import cdsapi


year = int(sys.argv[1])
month = int(sys.argv[2])
xmin = float(sys.argv[3])
xmax = float(sys.argv[4])
ymin = float(sys.argv[5])
ymax = float(sys.argv[6])
area = [ymax, xmin, ymin, xmax,]

# CDS API credentials

url = open('/media/.cdsapirc').readlines()[0].strip('\n').strip().split(": ", 1)[1]
key = open('/media/.cdsapirc').readlines()[1].strip('\n').strip().split(": ", 1)[1]

c = cdsapi.Client(url = url, key = key)

variables = ['total_precipitation', 'maximum_2m_temperature_in_the_last_24_hours']

for var in variables:
    dataset = 'seasonal-original-single-levels'
    times = ["{:01d}".format(n) for n in range(24, 5166, 24)]
    if var == 'total_precipitation':
      out = '/media/data/input/s5/ecmwf_s5_rain_' + str(year) + '_' + str("{:02d}".format(month)) + '.nc'
    else:
      out = '/media/data/input/s5/ecmwf_s5_tmax_' + str(year) + '_' + str("{:02d}".format(month)) + '.nc'
    request = {
        'originating_centre': 'ecmwf',
        'system': '51',
        'variable': var,
        'year': year,
        'month': month,
        'day': '01',
        'leadtime_hour': times,
        'area': area,
        'data_format': 'netcdf'
    }
    c.retrieve(dataset, request, out)
    time.sleep(1)
    if var == 'total_precipitation':
      rain = xr.open_dataset('/media/data/input/s5/ecmwf_s5_rain_' + str(year) + '_' + str("{:02d}".format(month)) + '.nc')
      rain = rain * 1000
      rain = rain.mean(dim = 'number')
      rain.to_netcdf('/media/data/intermediate/forecast/ecmwf_s5_rain_' + str(year) + '_' + str("{:02d}".format(month)) + '.nc')
    else:
      tmax = xr.open_dataset('/media/data/input/s5/ecmwf_s5_tmax_' + str(year) + '_' + str("{:02d}".format(month)) + '.nc')
      tmax = tmax-273.15
      tmax = tmax.mean(dim = 'number')
      tmax.to_netcdf('/media/data/intermediate/forecast/ecmwf_s5_tmax_' + str(year) + '_' + str("{:02d}".format(month)) + '.nc')
