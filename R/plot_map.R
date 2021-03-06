#'@title Plot Map
#'
#'@description Displays the map in the current device.
#'
#'@param hillshade Hillshade to be plotted.
#'@param rotate Default `0`. Rotates the output. Possible values: `0`, `90`, `180`, `270`.
#'@param asp Default `1`. Aspect ratio of the resulting plot. Use `asp = 1/cospi(mean_latitude/180)` to rescale
#'lat/long at higher latitudes to the correct the aspect ratio.
#'@param keep_user_par Default `TRUE`. Whether to keep the user's `par()` settings. Set to `FALSE` if you 
#'want to set up a multi-pane plot (e.g. set `par(mfrow)`).
#'@param ... Additional arguments to pass to the `raster::plotRGB` function that displays the map.
#'@export
#'@examples
#'#Plotting the Monterey Bay dataset with bathymetry data
#'\donttest{
#'water_palette = colorRampPalette(c("darkblue", "dodgerblue", "lightblue"))(200)
#'bathy_hs = height_shade(montereybay, texture = water_palette)
#'
#'#Set everything below 0m to water palette
#'montereybay %>%
#'  sphere_shade(zscale=10) %>%
#'  add_overlay(generate_altitude_overlay(bathy_hs, montereybay, 0, 0))  %>%
#'  add_shadow(ray_shade(montereybay,zscale=50),0.3) %>%
#'  plot_map()
#'
#'#Correcting the aspect ratio for the latitude of Monterey Bay
#'
#'extent_mb = attr(montereybay,"extent")
#'mean_latitude = mean(c(extent_mb@ymax,extent_mb@ymin))
#'
#'montereybay %>%
#'  sphere_shade(zscale=10) %>%
#'  add_overlay(generate_altitude_overlay(bathy_hs, montereybay, 0, 0))  %>%
#'  add_shadow(ray_shade(montereybay,zscale=50),0.3) %>%
#'  plot_map(asp = 1/cospi(mean_latitude/180))
#'}
plot_map = function(hillshade, rotate=0, asp = 1, keep_user_par = FALSE, ...) {
  if(keep_user_par) {
    old.par = graphics::par(no.readonly = TRUE)
    on.exit(graphics::par(old.par))
  }
  rotatef = function(x) t(apply(x, 2, rev))
  if(!(rotate %in% c(0,90,180,270))) {
    if(length(rotate) == 1) {
      warning(paste0("Rotation value ",rotate," not in c(0,90,180,270). Ignoring"))
    } else {
      warning(paste0("Rotation argument `rotate` not in c(0,90,180,270). Ignoring"))
    }
    number_of_rots = 0
  } else {
    number_of_rots = rotate/90
  }
  if(length(dim(hillshade)) == 3) {
    if(number_of_rots != 0) {
      newarray = hillshade
      newarrayt = array(0,dim=c(ncol(hillshade),nrow(hillshade),3))
      for(i in 1:number_of_rots) {
        for(j in 1:3) {
          if(i == 2) {
            newarray[,,j] = rotatef(newarrayt[,,j])
          } else {
            newarrayt[,,j] = rotatef(newarray[,,j])
          }
        }
      }
      if(number_of_rots == 2) {
        hillshade = newarray
      } else {
        hillshade = newarrayt
      }
    }
    suppressWarnings(raster::plotRGB(raster::brick(hillshade, xmn = 0.5, xmx = dim(hillshade)[2]+ 0.5,
                                                   ymn = 0.5, ymx = dim(hillshade)[1] + 0.5, ...),scale=1, 
                                     asp = asp,
                                     maxpixels=nrow(hillshade)*ncol(hillshade),...))
  } else if(length(dim(hillshade)) == 2) {
    if(number_of_rots != 0) {
      for(j in 1:number_of_rots) {
        hillshade = rotatef(hillshade)
      }
    }
    array_from_mat = array(fliplr(t(hillshade)),dim=c(ncol(hillshade),nrow(hillshade),3))
    suppressWarnings(raster::plotRGB(raster::brick(array_from_mat, xmn = 0.5, xmx = dim(array_from_mat)[2] + 0.5,ymn =  0.5, 
                                                   ymx = dim(array_from_mat)[1] +  0.5, ...),
                                     asp = asp,
                                     scale=1, maxpixels=nrow(hillshade)*ncol(hillshade), ...))
  } else {
    stop("`hillshade` is neither array nor matrix--convert to either to plot.")
  }
}