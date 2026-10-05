# armed_conflict
This repository reproduces part of the data preparation and descriptive analysis for the armed conflict project.

## What was done
- Imported regional and sub-regional information from `regions.txt`
- Matched the two data sets using three-digit ISO country codes
- Restricted the regional data to countries included in the study
- Summarized the number of countries by region and sub-region
- Created a bar chart showing the number of countries in each sub-region, coloured by region

## Main results
- countries.txt contains 186 countries
- regions.txt contains 249 countries and areas
- All 186 study countries were successfully matched using ISO country codes
- The final matched data set contains 186 countries
  
Countries by region:

Region	Count
Africa	54
Americas	35
Asia	46
Europe	40
Oceania	11
The largest sub-region is Sub-Saharan Africa, with 48 countries.

Repository structure
armed_conflict/
├── README.md
├── data/
│   └── raw/
│       ├── countries.txt
│       └── regions.txt
└── reports/
    ├── quarto_inclass.qmd
    └── quarto_inclass.pdf  
Reproducibility

The PDF report was generated from reports/quarto_inclass.qmd.


## Preparing the analysis dataset

- Converted four mortality datasets from wide to long format using a reusable R function.
- Created annual earthquake and drought indicators for 2000–2019.
- Defined armed conflict using a threshold of at least 25 battle-related deaths within a conflict-year and applied a one-year lag.
- Joined mortality, disaster, conflict and covariate data by ISO code and year.
- Compared the main and alternative scripts. Both produced identical output tables.

The final dataset contains 3,720 country-year observations, 186 countries and 17 columns.

### Files

- `scripts/create_final_data.R`: main preparation script.
- `scripts/create_final_data_agent.R`: alternative preparation script.
- `scripts/compare_data.R`: output comparison.
- `data/processed/final_data.csv`: final analysis dataset.
- `data/processed/final_data_agent.csv`: comparison dataset.
- `reports/data_preparation.qmd`: methods, validation and efficiency comparison.

### Run

From the repository root, with tidyverse and janitor installed:

```r
source("scripts/create_final_data.R")
source("scripts/create_final_data_agent.R")
source("scripts/compare_data.R")
```
