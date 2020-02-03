###############################################################################
# This script converts ERA5 reanalysis data from a NetCDF file to .RDS files  #
# for later use.  The NetCDF file is quite large, so extracting each variable #
# and storing it as an individual .RDS file will speed up future analysis.    #
###############################################################################


library(ncdf4)
library(reshape2)
library(dplyr)

# Open the NetCDF data set which contains several variables
nc_tmp <- nc_open('ERA5/Jan1979toFeb2019.nc')

# Store available variables as ncnames
ncnames <- attributes(nc_tmp$var)$names

# Now loop through each variable, extract from the NetCDF file, and save as 
# a .RDS file for future use
for(i in 1:length(ncnames)){
  # Get the variable
  ncvar <- ncvar_get(nc_tmp, attributes(nc_tmp$var)$names[14])
  
  # Then get the latitude and longitude
  nc_lon <- ncvar_get(nc_tmp, attributes(nc_tmp$dim)$names[1])
  nc_lat <- ncvar_get(nc_tmp, attributes(nc_tmp$dim)$names[2])
  
  # Then get the date, which is stored as hours since 1900-01-01 00:00:00.0,
  # so we need to transform these values to work properly in POSIXct
  nc_date <- as.POSIXct(ncvar_get(nc_tmp, 
                                  attributes(nc_tmp$dim)$names[3])*3600,
                        origin='1900-01-01 00:00',tz='GMT')
  
  # Close the file connection
  nc_close(nc_tmp)
  
  # Then we'll store the variable as a 3-dimensional array with dimensions
  # corresponding to latitude, longitude, and date
  dimnames(ncvar)[[1]] <- nc_lon
  dimnames(ncvar)[[2]] <- nc_lat
  dimnames(ncvar)[[3]] <- as.character(nc_date) #We want to change the POSIXct
  # value to a character
  
  # Finally, we save the array as a. RDS file for later use
  saveRDS(ncvar,paste0('ERA5/',ncnames[i],'.RDS'))
}




