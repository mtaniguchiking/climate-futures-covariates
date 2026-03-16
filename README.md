# climate-futures-covariates

This repo is a collection of four notebooks that combine observed and projected climate data for a given NPS park unit and package it into CSVs to be used in the [M4MD forecasting pipeline](https://lzachmann.github.io/models-for-missing-data/). The main outputs are a **historical covariate CSV** (site-level climate data for model fitting) and a **future scenarios CSV** (future climate scenario data for forecasting).

These notebooks are intended as an early support tool for M4MD users who want to test the pipeline's developing forecast features. Depending on feedback, this can later be formalized into a more proper pipeline. Don't hesitate to share feedback/issues you come across 🙏

> Default configuration values are set for Canyonlands National Park (CANY), which serves as the example if you want something to reference.

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
2. Run the notebook. If you're using RStudio, this can be done by either clicking `Render` or interactively running each code cell.
3. Once the notebook has been rendered/ran, scroll through and inspect the outputs.

**You can find a short set of instructions at the beginning of each notebook for reference!**

```
00-get-prism-loca2.qmd
  └─> downloads + crops PRISM & LOCA2 data for your park
        │
        ▼
01-get-climate-futures.qmd
  └─> classifies LOCA2 model runs into climate futures (warm-wet, hot-dry, etc.)
        │
        ▼
02-plot-prism-loca2.qmd   [optional]
  └─> plots time series and spatial summaries of the climate data
        │
        ▼
03-prep-climate-covariates.qmd
  └─> extracts climate values at your M4MD site locations
      writes the two CSVs used by the M4MD pipeline
```

`02` is optional - it's just for understanding your data and doesn't produce any outputs that are used later.

---

## Installation & Setup

1. Clone the repo and open `climate-futures-covariates.Rproj` in RStudio.

2. Restore the R package environment:
   ```r
   renv::restore()
   ```

3. Run the notebooks in order, customizing the `User Config` block at the top of each one.

**R packages used:** `terra`, `sf`, `ggplot2`, `prism`, `httr`, `tidyr`, `patchwork`, `tidyterra`

---

## Notebook Reference

### `00-get-prism-loca2.qmd`

Downloads raw climate data, crops and masks everything to a specified park boundary, and writes NetCDF files used by the remaining notebooks.

- **PRISM** - 4 km annual observed data (ppt in mm/yr, tmax in °C), 1950–2024, downloaded via the `prism` R package
- **LOCA2** - 6 km CMIP6 downscaled projections (ppt and tasmax), 1950–2065, pulled directly from the UCSD server. Covers 20 models × 2 scenarios (SSP2-4.5 and SSP5-8.5).

**User config:** `park_code`

**Outputs:**
- `data/<park_code>/processed/prism_pr.nc`
- `data/<park_code>/processed/prism_tasmax.nc`
- `data/<park_code>/processed/loca2/<model>_<scenario>_pr.nc` (one per model/scenario)
- `data/<park_code>/processed/loca2/<model>_<scenario>_tasmax.nc`

> Note: this notebook downloads a good amount of data and can take several minutes for a single park.

---

### `01-get-climate-futures.qmd`

Takes the processed NetCDFs and classifies each of the 40 model/scenario runs into a **climate future** quadrant (warm-wet, warm-dry, hot-dry, hot-wet, or central) based on mid-century temperature and precipitation anomalies relative to a PRISM observed baseline. Based on the [NPS CCRP Climate Futures framework](https://irma.nps.gov/DataStore/FileSource/Get?id=2302720&filename=2302720.html).

You pick which futures you want to carry forward (e.g. "warm-wet" and "hot-dry"). Park-specific recommended futures can be found in the [NPS Climate Futures Summaries](https://www.nps.gov/subjects/climatechange/climatefutures.htm).

**User config:** `park_code`, `selected_futures`, `baseline_start/end`, `midcent_start/end`

**Outputs:**
- `data/<park_code>/climate-futures-models.csv` - the selected model/scenario members per future label

| column | description |
|---|---|
| `label` | climate future name (e.g. `Hot-dry`) |
| `model` | CMIP6 model name |
| `scenario` | SSP scenario (`ssp245` or `ssp585`) |

---

### `02-plot-prism-loca2.qmd` *(optional)*

Some quick exploratory plots. Produces:
- A boundary alignment check (PRISM raster overlaid with the park boundary)
- Time-series plots of ppt and tmax for PRISM (historical) and LOCA2 (projected)
- Spatial mean maps per selected climate future

**User config:** `park_code`, `hist_start/end`, `future_start/end`

---

### `03-prep-climate-covariates.qmd`

The main output-generating notebook. Takes the processed climate data and your M4MD plot locations, extracts the climate variable(s) at each site, and writes two CSVs ready for the M4MD pipeline.

**User config:** `park_code`, `response_csv`, `site_locations_csv`, column name mappings, `site_crs`, `output_csv`, `forecast_output_csv`, `extract_ppt`, `extract_tmax`, `future_start/end`

**Outputs:**

`output/<park_code>-climate-covariates.csv` - historical site-level climate, for M4MD model fitting:

| column | description |
|---|---|
| `Unit_Code` | NPS unit code |
| `Master_Stratification` | stratum label |
| `Plot_ID` | site identifier |
| `Visit_Year` | year |
| `ppt` | annual precip at site (mm/yr), if extracted |
| `tmax` | annual max temp at site (°C), if extracted |

`output/<park_code>-climate-scenarios.csv` - projected site-level climate per future, for M4MD forecasting:

| column | description |
|---|---|
| `scenario_id` | integer ID for the climate future |
| `scenario_name` | climate future label (e.g. `Hot-dry`) |
| `model_run_id` | integer ID for the model member |
| `model_run_name` | model + scenario string (e.g. `CNRM-CM6-1 ssp585`) |
| `Unit_Code` | NPS unit code |
| `Plot_ID` | site identifier |
| `Master_Stratification` | stratum label |
| `cal_year` | year |
| `ppt` / `tmax` | projected climate value at site |

---

## Using the Outputs in M4MD

The two output CSVs from notebook `03` are formatted directly for the M4MD pipeline.

- **`<park_code>-climate-covariates.csv`** - use this as the climate covariate input when fitting your M4MD model. [_TODO: add specific field/config reference in the M4MD pipeline_]

- **`<park_code>-climate-scenarios.csv`** - use this as the forecast driver input. The `scenario_name` and `model_run_name` columns correspond to the climate future and individual model run, respectively. [_TODO: add specific field/config reference in the M4MD pipeline_]

> The column name for the climate variable (e.g. `ppt` or `tmax`) in the scenarios CSV needs to match the `driver covariate` field in your M4MD forecast YAML config.

---

## Data & Limitations

### Data sources

- **PRISM** - [PRISM Climate Group](https://prism.oregonstate.edu/), Oregon State University. Annual 4 km gridded climate data, 1950–2024.
- **LOCA2** - [Pierce et al., UCSD](https://loca.ucsd.edu/loca-version-2-for-north-america-ca-jan-2023/). CMIP6 statistically downscaled to ~6 km. Historical: 1950–2014; projections: 2015–2065 under SSP2-4.5 and SSP5-8.5.
- **NPS boundaries** - [National Parks boundaries](https://geodata.bts.gov/datasets/national-parks/explore) via the Bureau of Transportation Statistics.

### Limitations / Notes on the data we're using

- **Park bounday data** - The NPS boundary shapefile is already included in the repo at nps_boundaries — no download needed.
- **PRISM <> LOCA2** - LOCA2 bias correction is not performed using PRISM. This means there may be some small inconsistencies between the historical and future projection data. However, in the context of simply testing forecasting features, PRISM was selected for its accurancy and easy of use.
- **Single covariate for forecasting** - the M4MD forecasting pipeline currently handles only one future scenario covariate. Covariates should be consistent between model fitting and model forecasting. Thus, for the purposes of testing the forecasting features, you should fit your model with only one covariate (either temp OR precip) and then forecast with this same covariate. The forecasting pipeline will accept more than one covariate in the future.
- **PRISM rate limiting** - the PRISM download server will throttle requests. If you hit the rate limit, you will have to wait 24 hours before re-running notebook `00`.
- **One ensemble member per model** - only one ensemble member is used per CMIP6 model (see the `LOCA2_ENSEMBLES` list in notebook `00` for the specific members). This keeps the download manageable but means within-model variability isn't captured.
