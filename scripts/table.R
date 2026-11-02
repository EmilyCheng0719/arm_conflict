# Base R only. One script produces Table 1 and a machine-readable version.
d <- read.csv('output/analysis_data.csv')
vars <- c('maternal_mortality','under5_mortality','infant_mortality','neonatal_mortality',
          'gdp_1000','oecd','pop_dens','urban','age_dep','male_edu','temp','rainfall_1000','earthquake','drought')
labels <- c('Maternal mortality, per 100,000 live births','Under-5 mortality, per 1,000 live births',
'Infant mortality, per 1,000 live births','Neonatal mortality, per 1,000 live births',
'GDP per capita, US$1,000','OECD member, yes','Population density (source scale)',
'Urban residence, %','Age dependency ratio','Male education, years',
'Temperature (source scale)','Rainfall (source variable /1,000)','Earthquake in outcome year, yes','Drought in outcome year, yes')
groups <- list(d,d[d$armed_conflict==0,],d[d$armed_conflict==1,])
summary_value <- function(x,binary=FALSE) {
 x <- x[!is.na(x)]
 if (!length(x)) return('NA')
 if(binary) sprintf('%d (%.1f%%)',sum(x==1),100*mean(x==1)) else sprintf('%.1f (%.1f)',mean(x),sd(x))
}
tab <- data.frame(Characteristic=labels,check.names=FALSE)
for (j in seq_along(groups)) {
 g <- groups[[j]]
 tab[[paste0('Summary_',j)]] <- sapply(vars,function(v) summary_value(g[[v]],v %in% c('oecd','earthquake','drought')))
 tab[[paste0('Missing_',j)]] <- sapply(vars,function(v) sum(is.na(g[[v]])))
}
write.csv(tab,'output/table1_values.csv',row.names=FALSE)
pdf('output/table1.pdf',width=11.69,height=8.27,family='Helvetica')
par(mar=c(0,0,0,0)); plot.new(); plot.window(xlim=c(0,1),ylim=c(0,1))
text(.035,.95,'Table 1. Characteristics of the supplied country-year panel',adj=0,cex=1.2,font=2,col='#17324d')
text(.035,.912,'2000-2019 | Grouped by armed conflict in the previous year',adj=0,cex=.9,col='#506277')
xs <- c(.035,.435,.535,.615,.715,.795,.895)
heads <- c('Characteristic','Overall','Missing n','No conflict','Missing n','Conflict','Missing n')
rect(.03,.81,.97,.88,col='#17324d',border=NA)
for(j in 1:7) text(xs[j],.855,heads[j],adj=0,cex=.76,font=2,col='white')
for(j in 1:3) text(xs[2*j],.83,paste0('N = ',format(nrow(groups[[j]]),big.mark=',')),adj=0,cex=.76,col='white')
ys <- seq(.78,.29,length.out=16)
rows <- rbind(c('Country-year observations',3720,'-',3029,'-',691,'-'),
 c('Distinct countries',sapply(groups,function(g) length(unique(g$iso)))[1],'-',
 length(unique(groups[[2]]$iso)),'-',length(unique(groups[[3]]$iso)),'-'),as.matrix(tab))
for(i in seq_len(nrow(rows))) {
 if(i%%2==0) rect(.03,ys[i]-.015,.97,ys[i]+.015,col='#f0f4f8',border=NA)
 for(j in 1:7) text(xs[j],ys[i],rows[i,j],adj=0,cex=.74)
}
notes <- c('Values are mean (SD) or n (%); percentages use non-missing observations. Missing n is shown separately for each group.',
'Observations are country-years, not independent people. A country may appear in both conflict groups in different years.',
'Conflict = at least one conflict ID with >=25 deaths in year t-1. Disasters and other characteristics refer to outcome year t.',
'Maternal mortality is unavailable in 2018-2019 (372 panel rows); the remaining 54 missing values occur in 2000-2017.',
'The supplied 186-country panel is retained; published-paper sample counts are not imposed. No values are imputed.',
'Source: supplied raw course files; exposure definition adapted from Jawad et al. (2021), doi:10.1371/journal.pmed.1003810.')
for(i in seq_along(notes)) text(.035,.22-(i-1)*.026,notes[i],adj=0,cex=.69,col='#506277')
dev.off()
