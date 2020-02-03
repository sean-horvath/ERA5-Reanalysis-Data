###############################################################################
# This script converts daily ERA5 reanalysis data from a NetCDF file to .RDS  #
# files for later use.  This will speed up future analysis.                   #
###############################################################################


library(ncdf4)
library(reshape2)
library(dplyr)

# List all the NetCDF files
flist <- list.files('ERA5/NetCDF/')

# This is an index to print out during the for loops so we can see the progress
ind <- seq(10,200,by=10)

# Names of all the variables stored in the NetCDF files.  These are the default
# names provided by ECMWF and correspont to
# lcc:low cloud cover
# msdwlwrf:mean surface downward longwave radiation flux
# msl:mean sea level pressure
# p69.162:eastward heat flux
# p70.162:northward heat flux
# p71.162:eastward water vapor flux
# p72.162:northward water vapor flux
vars <- c('lcc','msdwlwrf','msl','p69.162','p70.162','p71.162','p72.162')

gc()
begin <- Sys.time()
# First loop through the variables
for(k in 1:length(vars)){
  # Loop through the 200 NetCDF files
  for(i in 1:200){
    nc <- nc_open(paste0('C:/Users/seanm/Documents/Research/ERA5/NetCDF/all/',
                         flist[i]))
    nc_var <- ncvar_get(nc, vars[k])
    nc_lon <- ncvar_get(nc, "longitude")
    nc_lat <- ncvar_get(nc, "latitude")
    nc_dates <- ncvar_get(nc, "day")
    nc_close(nc)
    rm(nc)
    
    # We want to divide sea level pressure by 1000 to get kPa
    if(vars[k]=='msl'){
      nc_var <- nc_var/1000
    }
    
    # Loop through days
    for(j in 1:dim(slp)[3]){
      rm(slp1)
      slp1 <- slp[,,j]
      slp1 <- as.data.frame(cbind(nc_lon,slp1))
      colnames(slp1) <- c('lon',nc_lat)
      
      # We store the daily values as a data.frame with the first two columns 
      # being latitude and longitude
      slp1 <- melt(slp1,id.vars='lon',
                   variable.name='lat',
                   value.name=nc_dates[j])
      
      # We need to convert longitude from a 0-360 scale to a -180-180 scale
      slp1$lon[which(slp1$lon>180)] <- (360-slp1$lon[which(slp1$lon>180)])*(-1)
      slp1$lat <- as.numeric(as.character(slp1$lat))
      
      # Then join each day with data.frame by latitude and longitude
      if(exists('myvar')){
        myvar <- left_join(myvar,slp1,by=c('lon','lat'))
      } else{
        myvar <- slp1
      }
    }
    
    # Prints out our progress
    if(i %in% ind){print(i)}
  }
  
  # Save our file as .RDS
  saveRDS(myvar,paste0('ERA5/',vars[k],'_daily.RDS'))
  
  # These files are quite large, so we clear out most of the environment before
  # starting the next loop
  rm(list=setdiff(ls(), c('flist','vars','ind')))
}

# Finally, print out how long this all took...
print(Sys.time()-begin)


