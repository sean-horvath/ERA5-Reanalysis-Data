###############################################################################
# This script uses the CDS API to download hourly data from ERA5 reanalysis.  #
# These are very large files, so we subset the spatial domain (north of 60N), #
# and download files one month at a time.  Once downloaded, this script then  #
# converts hourly data into daily means, saves the new daily NetCDF, and      #
# deletes the hourly files.                                                   #
###############################################################################


import cdsapi
import calendar
import xarray as xr
import os
import datetime

c = cdsapi.Client()

# We want data from years 1979 through 2018
allyear = range(1979,2019)

# Here we'll loop through all years, months, and days that we're interested in
for myyear in allyear:
    mymonth = ['03','04','05','06','07']
    for mo in mymonth:
        ndays = calendar.monthrange(myyear,int(mo))[1]
        mydays = []
        for i in range(ndays):
            mydays.append(str(i+1).zfill(2))
        
        c.retrieve(
        'reanalysis-era5-single-levels',
        {
            'product_type':'reanalysis',
            'variable':[
                'low_cloud_cover','mean_sea_level_pressure','mean_surface_downward_long_wave_radiation_flux',
                'vertical_integral_of_eastward_heat_flux','vertical_integral_of_eastward_water_vapour_flux',
                'vertical_integral_of_northward_heat_flux','vertical_integral_of_northward_water_vapour_flux'
            ],
            'year':str(myyear),
            'month':mo,
            'day':mydays,
            'area':[90, 0, 60, 360],
            'time':[
                '00:00','01:00','02:00',
                '03:00','04:00','05:00',
                '06:00','07:00','08:00',
                '09:00','10:00','11:00',
                '12:00','13:00','14:00',
                '15:00','16:00','17:00',
                '18:00','19:00','20:00',
                '21:00','22:00','23:00'
            ],
            'format':'netcdf'
        },
        str('NetCDF/'+str(myyear)+mo+'.nc'))
        
        # After download, we open the file to create daily mean file
        mfdataDIR = 'NetCDF/' + str(myyear) + mo + '.nc'
        DS = xr.open_dataset(mfdataDIR)
        
        # Group by day of year
        da_1 = DS.groupby('time.dayofyear').mean('time')
        
        start = datetime.datetime.strptime("01-" + mo + '-' + str(myyear), "%d-%m-%Y")
        end = datetime.datetime.strptime(str(ndays) + "-" + mo + "-" + str(myyear), "%d-%m-%Y")
        date_generated = [start + datetime.timedelta(days=x) for x in range(0, (end-start).days + 1)]
        
        mydates = []
        for date in date_generated:
            mydates.append(date.strftime("%d-%m-%Y"))
            
        da_1 = da_1.assign_coords(day=mydates)
        
        # Print out new NetCDF file
        dataDIR = 'NetCDF/cleaned_' + str(myyear) + mo + '.nc'
        da_1.to_netcdf(dataDIR)
        
        # Close file
        DS.close()
        da_1.close()
        
        # Delete hourly NetCDF file
        os.remove('NetCDF/'+str(myyear)+mo+'.nc')


