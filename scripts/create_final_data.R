library(tidyverse)
library(janitor)

# Run from the project root.
prepare_mortality <- function(data, outcome) {
  data |>
    pivot_longer(starts_with("X"), names_to = "year",
                 names_prefix = "X", values_to = outcome) |>
    mutate(year = as.integer(year)) |>
    select(iso, year, all_of(outcome))
}

maternal <- prepare_mortality(read.csv("data/raw/maternal_mortality.csv"), "maternal_mortality")
infant <- prepare_mortality(read.csv("data/raw/infant_mortality.csv"), "infant_mortality")
neonatal <- prepare_mortality(read.csv("data/raw/neonatal_mortality.csv"), "neonatal_mortality")
under5 <- prepare_mortality(read.csv("data/raw/under5_mortality.csv"), "under5_mortality")

# Multiple disasters in a year still count as one indicator.
disaster <- read.csv("data/raw/disaster.csv", fileEncoding = "latin1") |>
  clean_names() |>
  filter(between(year, 2000, 2019),
         disaster_type %in% c("Earthquake", "Drought")) |>
  select(year, iso, disaster_type) |>
  group_by(iso, year) |>
  summarise(earthquake = as.integer(any(disaster_type == "Earthquake")),
            drought = as.integer(any(disaster_type == "Drought")),
            .groups = "drop")

# Sum event deaths within each conflict, then identify country-years.
conflict <- read.csv("data/raw/conflict.csv")
# Rows with no conflict ID and no death count are non-event placeholders.
stopifnot(all(is.na(conflict$conflict_id) == is.na(conflict$best)))
conflict <- filter(conflict, !is.na(conflict_id))
conflict <- conflict |>
  group_by(iso, year, conflict_id) |>
  summarise(deaths = sum(best), .groups = "drop") |>
  group_by(iso, year) |>
  summarise(armed_conflict = as.integer(any(deaths >= 25)), .groups = "drop") |>
  mutate(year = year + 1L)

# Covariates provide the complete country-year panel.
final_data <- read.csv("data/raw/covariates.csv") |>
  left_join(maternal, by = c("iso", "year")) |>
  left_join(infant, by = c("iso", "year")) |>
  left_join(neonatal, by = c("iso", "year")) |>
  left_join(under5, by = c("iso", "year")) |>
  left_join(disaster, by = c("iso", "year")) |>
  left_join(conflict, by = c("iso", "year")) |>
  mutate(across(c(earthquake, drought, armed_conflict), ~ replace_na(.x, 0L))) |>
  arrange(iso, year)

stopifnot(nrow(final_data) == 3720L,
          anyDuplicated(final_data[c("iso", "year")]) == 0L,
          all(final_data$year %in% 2000:2019))
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
write.csv(final_data, "data/processed/final_data.csv", row.names = FALSE, na = "")
