# Week 9 in-class assignment. Run from the repository root.
# Rscript scripts/multiple_imputation.R
library(mice)
library(plm)

data <- read.csv("data/processed/final_data.csv", na.strings = c("", "NA"))
outcomes <- c("maternal_mortality", "under5_mortality",
              "infant_mortality", "neonatal_mortality")
outcome_labels <- c("Maternal mortality", "Under-five mortality",
                    "Infant mortality", "Neonatal mortality")
predictors <- c("armed_conflict", "loggdp", "oecd", "pop_dens", "urban",
                "age_dep", "male_edu", "temp", "rainfall_1000",
                "earthquake", "drought")
term_labels <- c("Armed conflict", "Log GDP per capita", "OECD membership",
                 "Population density", "Urban population", "Age dependency",
                 "Male education", "Temperature", "Rainfall",
                 "Earthquake", "Drought")
stopifnot(!anyDuplicated(data[c("iso", "year")]),
          all(data$gdp_1000[!is.na(data$gdp_1000)] > 0))
data$loggdp <- log(data$gdp_1000)

# Use log GDP as in the lecture's imputation run log.
mi_data <- data[c(
  "year", "maternal_mortality", "infant_mortality", "neonatal_mortality",
  "under5_mortality", "armed_conflict", "drought", "earthquake", "oecd",
  "pop_dens", "urban", "age_dep", "male_edu", "temp", "rainfall_1000", "loggdp"
)]
mi_data$iso_num <- as.integer(factor(data$iso))
imputed_variables <- c("urban", "male_edu", "temp", "rainfall_1000",
                       "loggdp", "pop_dens", outcomes)
stopifnot(setequal(names(mi_data)[colSums(is.na(mi_data)) > 0],
                   imputed_variables))

initial <- mice(mi_data, seed = 100, m = 5, maxit = 0, printFlag = FALSE)
method <- initial$method
method[imputed_variables] <- "2l.lmer"
predictor_matrix <- initial$predictorMatrix
predictor_matrix[imputed_variables, "iso_num"] <- -2
imputations <- mice(mi_data, seed = 100, m = 10, maxit = 20,
                    method = method, predictorMatrix = predictor_matrix)
stopifnot(imputations$m == 10L, imputations$iteration == 20L,
          all(vapply(complete(imputations, "all"), function(x) !anyNA(x),
                     logical(1))))

if (interactive()) print(plot(imputations))
if (!is.null(imputations$loggedEvents)) print(imputations$loggedEvents)

compare_models <- function(outcome) {
  cc <- plm(reformulate(predictors, outcome), data = data,
            index = c("iso", "year"), effect = "twoways", model = "within")
  cc_summary <- summary(cc)$coefficients
  cc_margin <- qt(0.975, df.residual(cc)) * cc_summary[predictors, "Std. Error"]
  mi_formula <- reformulate(c(predictors, "factor(iso_num)", "factor(year)"),
                            outcome, intercept = FALSE)
  mi <- with(imputations, {
    environment(mi_formula) <- environment()
    lm(mi_formula)
  })
  pooled <- summary(pool(mi), conf.int = TRUE, conf.level = 0.95)
  stopifnot(all(predictors %in% rownames(cc_summary)),
            all(predictors %in% pooled$term))
  mi_rows <- match(predictors, pooled$term)
  data.frame(
    outcome = outcome,
    term = predictors,
    cc_estimate = cc_summary[predictors, "Estimate"],
    cc_lower = cc_summary[predictors, "Estimate"] - cc_margin,
    cc_upper = cc_summary[predictors, "Estimate"] + cc_margin,
    mi_estimate = pooled$estimate[mi_rows],
    mi_lower = pooled[mi_rows, "2.5 %"],
    mi_upper = pooled[mi_rows, "97.5 %"],
    row.names = NULL
  )
}

results <- do.call(rbind, lapply(outcomes, compare_models))
stopifnot(nrow(results) == length(outcomes) * length(predictors),
          all(is.finite(as.matrix(results[3:8]))),
          all(results$cc_lower <= results$cc_estimate),
          all(results$cc_estimate <= results$cc_upper),
          all(results$mi_lower <= results$mi_estimate),
          all(results$mi_estimate <= results$mi_upper))

dir.create("output", showWarnings = FALSE)
format_ci <- function(estimate, lower, upper) {
  sprintf("%.3f [%.3f, %.3f]", estimate, lower, upper)
}
rows <- unlist(lapply(seq_along(outcomes), function(i) {
  x <- results[results$outcome == outcomes[i], ]
  c(sprintf('<tr class="group"><th colspan="3">%s</th></tr>', outcome_labels[i]),
    sprintf('<tr><th scope="row">%s</th><td>%s</td><td>%s</td></tr>',
            term_labels, format_ci(x$cc_estimate, x$cc_lower, x$cc_upper),
            format_ci(x$mi_estimate, x$mi_lower, x$mi_upper)))
}))
writeLines(c(
  '<!doctype html><html lang="en"><meta charset="utf-8">',
  '<meta name="viewport" content="width=device-width, initial-scale=1">',
  '<title>Week 9 | Complete cases and multiple imputation</title>',
  '<style>body{font:15px system-ui,sans-serif;color:#152637;margin:2rem auto;padding:0 1rem;max-width:850px}h1{font-size:1.5rem}table{border-collapse:collapse;width:100%;font-variant-numeric:tabular-nums}th,td{text-align:left;padding:.5rem;border-bottom:1px solid #dce3e9}thead{background:#17354d;color:white}.group{background:#eaf0f5}td{white-space:nowrap}p{line-height:1.45}@media print{body{margin:0}thead{color:#152637;background:white}tr{break-inside:avoid}}</style>',
  '<h1>Armed conflict and mortality</h1>',
  '<table aria-label="Comparison of regression estimates and 95% confidence intervals">',
  '<thead><tr><th scope="col">Predictor</th><th scope="col">Complete cases<br>Estimate [95% CI]</th><th scope="col">Multiple imputation<br>Estimate [95% CI]</th></tr></thead>',
  '<tbody>', rows, '</tbody></table>',
  '<p>Both analyses include country and year fixed effects. Multiple imputation used 10 imputed datasets and 20 iterations. MI estimates and confidence intervals were pooled using Rubin&#39;s rules.</p>',
  '</html>'
), "output/week9_cc_vs_mi.html")
print(results)
