library(tidyverse)
library(janitor)

# Independent alternative; does not read or overwrite final_data.csv.
reshape_wb <- function(file, outcome) {
  read.csv(file) |>
    pivot_longer(starts_with("X"), names_to = "year",
                 names_prefix = "X", values_to = outcome) |>
    mutate(year = as.integer(year)) |>
    select(iso, year, all_of(outcome))
}

outcomes <- c("maternal_mortality", "infant_mortality",
              "neonatal_mortality", "under5_mortality")
wb <- map(outcomes, function(x) reshape_wb(paste0("data/raw/", x, ".csv"), x)) |>
  reduce(full_join, by = c("iso", "year"))

disasters <- read.csv("data/raw/disaster.csv", fileEncoding = "latin1") |>
  clean_names() |>
  filter(between(year, 2000, 2019), disaster_type %in% c("Earthquake", "Drought")) |>
  transmute(iso, year, disaster_type = tolower(disaster_type), present = 1L) |>
  distinct() |>
  pivot_wider(names_from = disaster_type, values_from = present, values_fill = 0L)

conflicts <- read.csv("data/raw/conflict.csv")
stopifnot(all(is.na(conflicts$conflict_id) == is.na(conflicts$best)))
conflicts <- filter(conflicts, !is.na(conflict_id))
conflicts <- conflicts |>
  group_by(iso, year, conflict_id) |>
  summarise(deaths = sum(best), .groups = "drop") |>
  filter(deaths >= 25) |>
  distinct(iso, year) |>
  mutate(year = year + 1L, armed_conflict = 1L)

final_agent <- read.csv("data/raw/covariates.csv") |>
  left_join(wb, by = c("iso", "year")) |>
  left_join(disasters, by = c("iso", "year")) |>
  left_join(conflicts, by = c("iso", "year")) |>
  mutate(across(c(earthquake, drought, armed_conflict), ~ replace_na(.x, 0L))) |>
  select(iso, year, gdp_1000, oecd, pop_dens, urban, age_dep, male_edu,
         temp, rainfall_1000, all_of(outcomes), earthquake, drought, armed_conflict) |>
  arrange(iso, year)

stopifnot(nrow(final_agent) == 3720L,
          anyDuplicated(final_agent[c("iso", "year")]) == 0L)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
write.csv(final_agent, "data/processed/final_data_agent.csv", row.names = FALSE, na = "")
