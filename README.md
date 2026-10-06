# climate-futures-covariates

This repo is a collection of four notebooks that combine historical and projected climate data for a given NPS park unit and package it into CSVs to be used in the [M4MD forecasting pipeline](https://lzachmann.github.io/models-for-missing-data/). The main outputs are a **historical covariate CSV** (site-level climate data for model fitting) and a **future scenarios CSV** (future climate scenario data for forecasting).

These notebooks are intended as an early support tool for M4MD users who want to test the pipeline's developing forecast features. Depending on feedback, this can later be formalized into a more proper pipeline. Don't hesitate to share feedback/issues you come across them 🙏

> Default configuration values are set for Canyonlands National Park (CANY), which serve as an example if you want something to reference.

---

## Table of Contents

1. [How It Works](#how-it-works)
2. [Installation & Setup](#installation--setup)
3. [Notebook Reference](#notebook-reference)
4. [Using the Outputs in M4MD](#using-the-outputs-in-m4md)
5. [Data & Limitations](#data--limitations)

---

## How It Works

Please run the four notebooks in order. Each one depends on outputs from the previous.
The general approach for each notebook is:
1. Customize the `User config` code block located at the beginning of the notebook. This is the only code block you need to change, although feel free to mess around with the rest of the code or add additional analysis if you're interested.
2. Run the notebook. If you're using RStudio, this can be done by either clicking `Render` or interactively running each code cell. For running cells one by one, I prefer the `Visual` view over the `Source` view (toggleable on the top left of RStudio).
3. Once the notebook has been rendered/ran, scroll through and inspect the outputs.

**You can find a short set of instructions at the beginning of each notebook for reference!**

```
00-get-livneh-loca2.qmd
  └─> crops Livneh data & downloads + crops LOCA2 data for your park
        │
        ▼
01-get-climate-futures.qmd
  └─> classifies LOCA2 model runs into climate futures (warm-wet, hot-dry, etc.)
        │
        ▼
02-plot-livneh-loca2.qmd [optional]
  └─> plots time series and spatial summaries of the climate data
        │
        ▼
03-prep-climate-covariates.qmd
  └─> extracts climate values at your M4MD site locations +
      writes the two CSVs used by the M4MD pipeline
```

---

## Installation & Setup

1. Get this repository locally. If you're familiar with git, you can clone it. Otherwise, download it as a ZIP from GitHub (green "Code" button → "Download ZIP").

2. Open `climate-futures-covariates.Rproj` in RStudio.

3. Restore the R package environment by running the following in the RStudio console. This installs all required packages (you only need to do this once).
   ```r
   renv::restore()
   ```

---

## Notebook Reference

### `00-get-livneh-loca2.qmd`

Crops the revised, historical Livneh data and downloads + crops the LOCA2 projections to a specified park boundary, and writes NetCDF files used by the remaining notebooks.

- **Livneh** - 6 km historical data (ppt and tmax), 1950-2018. It's a revised version of the Livneh et al. observed data that has already been downloaded + processed by `build-livneh-regions.R` into one file per LOCA2 climate region This data can be found in `data/livneh/`.
- **LOCA2** - 6 km CMIP6 downscaled projections (ppt and tasmax), 1950–2065. It is downloaded from a UCSD server. Covers 20 models × 2 scenarios (SSP2-4.5 and SSP5-8.5).

**User config:** `park_code`, `keep_raw_downloads`

**Outputs:**
- `data/<park_code>/processed/livneh/livneh_pr.nc`
- `data/<park_code>/processed/livneh/livneh_tasmax.nc`
- `data/<park_code>/processed/loca2/<model>_<scenario>_pr.nc` (one per model/scenario)
- `data/<park_code>/processed/loca2/<model>_<scenario>_tasmax.nc`

> Note: this notebook downloads a fair amount of data and can take several minutes to complete.

---

### `01-get-climate-futures.qmd`

Takes the processed NetCDFs and classifies each of the 40 model/scenario runs into a **climate future** quadrant (warm-wet, warm-dry, hot-dry, hot-wet, or central) based on mid-century temperature and precipitation anomalies relative to a Livneh observed baseline. Based on the [NPS CCRP Climate Futures framework](https://irma.nps.gov/DataStore/FileSource/Get?id=2302720&filename=2302720.html).

You pick which futures you want to carry forward (e.g. "warm-wet" and "hot-dry"). Park-specific recommended futures can be found in the [NPS Climate Futures Summaries](https://www.nps.gov/subjects/climatechange/climatefutures.htm).

**User config:** `park_code`, `selected_futures`, `single_model_per_future`, `baseline_start/end`, `midcent_start/end`

**Outputs:**
- `data/<park_code>/climate-futures-models.csv` - the selected model/scenario members per future label

| column | description |
|---|---|
| `label` | climate future name (e.g. `Hot-dry`) |
| `model` | CMIP6 model name |
| `scenario` | SSP scenario (`ssp245` or `ssp585`) |

---

### `02-plot-livneh-loca2.qmd` *(optional)*

Some quick exploratory plots. Produces:
- Time-series plots of ppt and tmax for Livneh (historical) and LOCA2 (projected)
- Spatial mean maps per selected climate future

**User config:** `park_code`, `hist_start/end`, `future_start/end`

---

### `03-prep-climate-covariates.qmd`

The main output-generating notebook. Takes the processed climate data and your M4MD plot locations, extracts the climate variable(s) at each site, and writes two CSVs ready for the M4MD pipeline.

**User config:** `park_code`, `response_csv`, `site_locations_csv`, column name mappings, `site_crs`, `output_csv`, `forecast_output_csv`, `extract_ppt`, `extract_tmax`, `future_start/end`

**Outputs:**

`output/<fit_output_csv>.csv` - historical site-level climate, for M4MD model fitting:

| column | description |
|---|---|
| `<unit_code_col>` | NPS unit code |
| `<stratum_col>` | stratum label |
| `<site_id_col>` | site identifier |
| `<year_col>` | year |
| `ppt` | annual precip at site (mm/yr), if extracted |
| `tmax` | annual max temp at site (°C), if extracted |

`output/<forecast_output_csv>.csv` - projected site-level climate per future, for M4MD forecasting:

| column | description |
|---|---|
| `<unit_code_col>` | NPS unit code |
| `scenario` | climate future label (e.g. `Hot-dry`) |
| `model_run` | model + scenario string (e.g. `CNRM-CM6-1 ssp585`) |
| `<site_id_col>` | site identifier |
| `<stratum_col>` | stratum label |
| `<year_col>` | year |
| `ppt` | annual precip at site (mm/yr), if extracted |
| `tmax` | annual max temp at site (°C), if extracted |

---

## Using the Outputs in M4MD

The two output CSVs from notebook `03` (found in the `output` folder) are formatted be to inputs for the M4MD pipeline. As a reminder, the idea here is to take an existing M4MD model that includes a prepared response variable CSV, site locations CSV, etc and provide a covariates CSV for model fitting and future covariates CSV for model forecasting.

Below are a few suggestions. More documentation can be found in this forecasting [developer's guide](https://mtaniguchiking.github.io/M4MD-forecast-docs-dev/docs/5-forecasting/).

- **`fit_output_csv`** - use this as the covariate input when fitting your M4MD model. I recommend copying/moving this file into your M4MD repo `assets/_data/`. Then, the covariate sections of your config YAML could look something like (customize the `\<blanks\>`):

```
covariate info:
  file: assets/_data/<fit_output_csv>.csv
  event date info:
    date-time column: <year_col>
    date-time format: Y!
  covariate columns:
    - <climate_var> # ppt and/or tmax

# ... other configs not shown ...

additional covariates:
  - "<climate_var>, <climate_var>*<stratum_col>" # use this if you're only using ppt OR tmax
#  -  "ppt, tmax, ppt*<stratum_col>, tmax*<stratum_col>" # use this if you're using both ppt AND tmax

time effect: disabled # recommended for forecasting
```

- **`forecast_output_csv`** - use this as the forecast driver input. The `scenario` and `model_run` columns correspond to the climate future and individual model run. I also recommend copying/moving this file into your M4MD repo `assets/_data/`. Then, you can update the following key-value pairs in your forecast config YAML in `M4MD/forecasting/forecast`: 

```
scenarios_file: assets/_data/<forecast_output_csv>.csv

# ... other configs not shown ...

covariates:
  <climate_var>:
    source: provided
#  <climate_var>: # include a second climate variable if you have two
#    source: provided
```

---

## Data & Limitations

### Sources

- **Historical data** - This project uses the Extreme-Preserving Long-Term Gridded Daily Precipitation Dataset for the Conterminous United States developed by Pierce et al. (2021).
  - Pierce, D. W., Su, L., Cayan, D. R., Risser, M. D., Livneh, B., & Lettenmaier, D. P. (2021). An extreme-preserving long-term gridded daily precipitation data set for the conterminous United States. Journal of Hydrometeorology, 22, 1883–1898. https://doi.org/10.1175/JHM-D-20-0212.1
  - Data was accessed via https://cirrus.ucsd.edu/~pierce/nonsplit_precip/. See `build-livneh-regions.R`.
- **Future projection data** - This project uses the LOCA version 2 at 6 km for the North American domain dataset developed by Pierce et al. (2023).
  - Pierce, D. W., D. R. Cayan, D. R. Feldman, and M. D. Risser, 2023: Future Increases in North American Extreme Precipitation in CMIP6 downscaled with LOCA. J. Hydrometeor., https://doi.org/10.1175/JHM-D-22-0194.1, in press.
  - Data was accessed via https://cirrus.ucsd.edu/~pierce/LOCA2/. See `00-get-livneh-loca2.qmd`.
- **NPS boundaries** - This project uses the National Parks boundaries dataset from Bureau of Transportation Statistics. It was downloaded via https://geodata.bts.gov/datasets/national-parks/explore.
- **CCRP Climate Futures** - This project follows the climate futures methodology as described in Methods for assessing climate change exposure for national park planning by Runyon et al. (2024).
  - Runyon, A. N., J. E. Gross, G. W. Schuurman, D. J. Lawrence, and J. H. Reynolds. 2024. Methods for assessing climate change exposure for national park planning. Park Resource Report PRR—2024/02. National Park Service, Fort Collins, Colorado. https://doi.org/10.36967/2302720

### Limitations / Notes on the data we're using

- **Historical data range** - the Livneh-based covariates can range from 1950–2018. M4MD expects a covariate value for every response year, so response data must be limited to 2018 or earlier. Also note that years between 2018 and your `future_start` are not covered by either output CSV. It's possible to address with by filling years 2019-2025 via other datasets, such as GridMET. I've explored the implementation of GridMET for these years and it seems somewhat defensible, but I haven't completed this for the time being (see the "formalizing" point at the top of the readme).
- **Limited covariates for fitting + forecasting** - Covariates should be consistent between model fitting and model forecasting. Thus, for the purposes of testing the forecasting features, you should fit your model with only temp and/or precip (configurable in 03) and then forecast with these same covariate(s). This small menu of covariates constrains an M4MD model to explain response variable variation only in terms of precipitation, maximum temperature, and/or time.
- **Fixed sources of data** - In addition to the covariates used, there are limitations with using a single source of data across varying landscapes. For example, there may be more accurate precipitation datasets, finer-resolution datasets, etc depending on your specific region.
- **One ensemble member per model** - only one ensemble member is used per CMIP6 model (see the `LOCA2_ENSEMBLES` list in notebook `00` for the specific members). This keeps the download manageable but means within-model variability isn't captured.
- **Editing this notebook** - if you feel comfortable doing so, you are encouraged to add to this repo for your specific region. This could mean replacing a dataset, adding more covariates, visualizing additional plots, etc!
