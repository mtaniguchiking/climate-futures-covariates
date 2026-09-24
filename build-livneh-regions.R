# A data pre-processing script (not part of the notebook pipeline) to
# download a revised version of the Livneh et al. precipitation and
# maximum temperature data from 1950-2018. It reduces each year to
# a single annual value per variable, and rops the result into the
# 9 LOCA2 climate regions.
#
# Outputs: data/livneh/<region>_pr.nc, data/livneh/<region>_tasmax.nc

library(terra)
library(curl)
library(ncdf4)

terraOptions(progress = 0)

LIVNEH_YEARS <- 1950:2018
LIVNEH_REGIONS <- c("cent", "e_n_cent", "n_east", "n_west",
                     "s_east", "s_west", "south", "w_n_cent", "west")

livneh_precip_url <- function(year) paste0(
  "https://cirrus.ucsd.edu/~pierce/nonsplit_precip/precip/",
  "livneh_unsplit_precip.2021-05-02.", year, ".nc"
)

livneh_temp_url <- function(year) paste0(
  "https://cirrus.ucsd.edu/~pierce/nonsplit_precip/temp_and_wind/",
  "livneh_lusu_2020_temp_and_wind.2021-05-02.", year, ".nc"
)

# one LOCA2 file per region, used to copy each region's boundary
region_template_url <- function(region) paste0(
  "https://cirrus.ucsd.edu/~pierce/LOCA2/CONUS_regions_split/ACCESS-CM2/",
  region, "/0p0625deg/r1i1p1f1/ssp245/pr/",
  "pr.ACCESS-CM2.ssp245.r1i1p1f1.2015-2044.LOCA_16thdeg_v20240915.",
  region, ".yearly.nc"
)

out_dir <- file.path("data", "livneh")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

crop_to_region <- function(r, template) {
  r <- resample(crop(r, template), template, method = "near")
  mask(r, template)
}

# ---- region mask templates -------------------------------------------------
message("Downloading region boundary templates...")
region_templates <- lapply(LIVNEH_REGIONS, function(region) {
  dest <- tempfile(fileext = ".nc")
  curl_download(region_template_url(region), dest, quiet = TRUE)
  # LOCA2 uses 0-360 longitude; Livneh uses -180/+180, so rotate to match
  template <- toMemory(rotate(rast(dest)[[1]]))
  file.remove(dest)
  template
})
names(region_templates) <- LIVNEH_REGIONS

# ---- per-year download + annual aggregation --------------------------------
region_pr     <- setNames(vector("list", length(LIVNEH_REGIONS)), LIVNEH_REGIONS)
region_tasmax <- setNames(vector("list", length(LIVNEH_REGIONS)), LIVNEH_REGIONS)

for (year in LIVNEH_YEARS) {
  message("Processing ", year, " ...")

  precip_file <- tempfile(fileext = ".nc")
  temp_file   <- tempfile(fileext = ".nc")
  curl_download(livneh_precip_url(year), precip_file, quiet = TRUE)
  curl_download(livneh_temp_url(year), temp_file, quiet = TRUE)

  # precip is daily mm; the annual value is the yearly total.
  annual_pr <- toMemory(sum(rast(precip_file)))

  # The annual value is the yearly mean of the daily maxima.
  temp_r <- rast(temp_file)
  annual_tasmax <- toMemory(mean(temp_r[[grepl("^Tmax", names(temp_r))]]))

  file.remove(precip_file, temp_file)

  for (region in LIVNEH_REGIONS) {
    template <- region_templates[[region]]
    region_pr[[region]][[as.character(year)]]     <- crop_to_region(annual_pr, template)
    region_tasmax[[region]][[as.character(year)]] <- crop_to_region(annual_tasmax, template)
  }
}

# ---- write one file per region per variable --------------------------------
message("Writing regional output files...")
for (region in LIVNEH_REGIONS) {
  pr_stack     <- rast(region_pr[[region]])
  tasmax_stack <- rast(region_tasmax[[region]])
  time(pr_stack)     <- as.Date(paste0(LIVNEH_YEARS, "-07-01"))
  time(tasmax_stack) <- as.Date(paste0(LIVNEH_YEARS, "-07-01"))

  writeCDF(pr_stack, file.path(out_dir, paste0(region, "_pr.nc")),
           overwrite = TRUE, varname = "pr", unit = "mm",
           longname = "annual total precipitation")
  writeCDF(tasmax_stack, file.path(out_dir, paste0(region, "_tasmax.nc")),
           overwrite = TRUE, varname = "tasmax", unit = "degC",
           longname = "annual mean daily maximum temperature")
}

message("Finished! Wrote ", length(LIVNEH_REGIONS), " regions x 2 variables to ", out_dir)
