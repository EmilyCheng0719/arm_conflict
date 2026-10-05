# Run after both preparation scripts.
a <- read.csv("data/processed/final_data.csv")
b <- read.csv("data/processed/final_data_agent.csv")
a <- a[order(a$iso, a$year), ]
b <- b[order(b$iso, b$year), names(a)]
rownames(a) <- rownames(b) <- NULL
print(all.equal(a, b, check.attributes = FALSE))
stopifnot(isTRUE(all.equal(a, b, check.attributes = FALSE)))
