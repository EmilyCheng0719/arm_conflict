# Run from the project root: Rscript scripts/run_all.R
source('scripts/01_prepare_data.R')
source('scripts/02_table1.R')
source('scripts/03_maternal_trends.R')
capture.output(sessionInfo(),file='output/r_session_info.txt')
