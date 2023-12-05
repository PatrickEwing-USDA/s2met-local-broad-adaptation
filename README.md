# Local adaptation and broad performance are synergistic to productivity in modern barley
Data and analysis for Ewing et al., *in review*.

**Files**

1. ./Data
  1. S2MET.csv - data downloaded from www.triticaceaetoolbox.org
  2. S2MET Meta.csv - description of columns in S2MET.csv
  3. s2met_daymet_rawDailyWeather.csv - weather data for accompanying sites, from Jeff Neyhart.
2. ./R
  1. R HFA - folder with functions for home field advantage analysis, modified from [MacQueen et al, 2021](https://doi.org/10.1002/csc2.20694)
  2. process_s2met.R - BLUP yields
  3. S2MET HFA.Rmd - main analysis code, including Figures 2 and 3.
  4. summarize_weather.Rmd - processing weather data, including Figure 1.
3. ./Results - output from S2MET HFA.Rmd and summarize_weather.Rmd

**Usage**

1. Download and install R, RStudio, and RTools
2. Ensure all dependencies are loaded, including Matrix and Permute (others should install automatically)
3. Open HFA vs BLUP Analysis.Rproj
4. Run process_s2met.R
5. Run summarize_weather.Rmd
6. run S2MET HFA.Rmd

Questions? Issues? Email patrick.ewing@usda.gov
