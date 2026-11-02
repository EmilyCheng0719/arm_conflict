# Run from the week7_tables_figures project root. Base R only.
dir.create('output', showWarnings = FALSE)
raw <- 'data/raw'
read_raw <- function(f) read.csv(file.path(raw, f), stringsAsFactors = FALSE)
d <- read_raw('covariates.csv')
stopifnot(!anyDuplicated(d[c('iso','year')]))
for (v in c('maternal_mortality','under5_mortality','infant_mortality','neonatal_mortality')) {
  w <- read_raw(paste0(v,'.csv'))
  stopifnot(!anyDuplicated(w$iso))
  z <- do.call(rbind, lapply(2000:2019, function(y) {
    x <- data.frame(iso=w$iso, year=y, value=w[[paste0('X',y)]])
    names(x)[3] <- v
    x
  }))
  d <- merge(d, z, by=c('iso','year'), all.x=TRUE, sort=FALSE)
}
c <- read_raw('conflict.csv')
stopifnot(all(is.na(c$conflict_id) == is.na(c$best)))
# Verify source coverage before interpreting non-event placeholders as absence.
coverage <- unique(transform(c[c('iso','year')], year=year+1L))
stopifnot(all(paste(d$iso,d$year) %in% paste(coverage$iso,coverage$year)))
c <- c[!is.na(c$conflict_id), ]
s <- aggregate(best ~ iso+year+conflict_id, data=c, FUN=sum)
s <- aggregate(best ~ iso+year, data=s, FUN=function(x) as.integer(any(x>=25)))
names(s)[3] <- 'armed_conflict'
s$year <- s$year+1L
# Exposure refers to conflict in t-1, not t; threshold within conflict ID.
d <- merge(d,s,by=c('iso','year'),all.x=TRUE,sort=FALSE)
d$armed_conflict[is.na(d$armed_conflict)] <- 0L
e <- read.csv(file.path(raw,'disaster.csv'), fileEncoding='latin1', check.names=FALSE)
e <- e[e$Year %in% 2000:2019 & e[['Disaster Type']] %in% c('Earthquake','Drought'), ]
for (v in c('earthquake','drought')) {
  z <- unique(e[tolower(e[['Disaster Type']])==v,c('ISO','Year')])
  names(z) <- c('iso','year')
  z[[v]] <- 1L
  d <- merge(d,z,by=c('iso','year'),all.x=TRUE,sort=FALSE)
  d[[v]][is.na(d[[v]])] <- 0L
}
d <- d[order(d$iso,d$year), ]
stopifnot(nrow(d)==3720L, length(unique(d$iso))==186L,
          !anyDuplicated(d[c('iso','year')]), sum(d$armed_conflict)==691L)
write.csv(d,'output/analysis_data.csv',row.names=FALSE,na='')
