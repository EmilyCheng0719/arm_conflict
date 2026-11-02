# Base R only. Select on the actual 2000 and 2017 endpoints, not first available year.
d <- read.csv('output/analysis_data.csv')
n <- read.table('data/raw/countries.txt',header=TRUE,stringsAsFactors=FALSE,fileEncoding='latin1')
a <- d[d$year==2000,c('iso','maternal_mortality')]; names(a)[2] <- 'mmr_2000'
b <- d[d$year==2017,c('iso','maternal_mortality')]; names(b)[2] <- 'mmr_2017'
e <- merge(a,b,by='iso')
e <- e[complete.cases(e) & e$mmr_2017>e$mmr_2000, ]
e <- merge(e,n,by.x='iso',by.y='ISO',all.x=TRUE)
e$increase <- e$mmr_2017-e$mmr_2000
e <- e[order(e$country_name), ]
stopifnot(nrow(e)==13L, !anyNA(e$country_name))
write.csv(e,'output/increasing_countries.csv',row.names=FALSE)
p <- d[d$year %in% 2000:2017 & d$iso %in% e$iso, ]
stopifnot(nrow(p)==13L*18L, !anyNA(p$maternal_mortality))
write.csv(p,'output/figure_data.csv',row.names=FALSE)
colors <- c('#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d',
            '#1f78b4','#b15928','#6a3d9a','#00838f','#c62828','#455a64')
png('output/maternal_mortality_trends.png',width=3600,height=2700,res=300)
layout(matrix(c(1,2,3),3,1),heights=c(1,1,.28))
par(mar=c(3,5,4,2),family='sans')
for(k in 1:2) {
 ymax <- if(k==1) 520 else 160
 plot(NA,xlim=c(2000,2017),ylim=c(0,ymax),xlab='Year',ylab='Maternal deaths per 100,000 live births',
      main=if(k==1) 'Maternal mortality increased in 13 countries, 2000-2017' else 'Detail: the 12 countries other than Haiti',
      bty='l',las=1,xaxt='n')
 axis(1,at=c(2000,2005,2010,2015,2017))
 abline(h=pretty(c(0,ymax)),col='#e5eaf0',lwd=.7)
 for(j in seq_len(nrow(e))) {
  if(k==2 && e$iso[j]=='HTI') next
  z <- p[p$iso==e$iso[j], ]; z <- z[order(z$year), ]
  lines(z$year,z$maternal_mortality,col=colors[j],lwd=2,lty=1+(j-1)%%3)
  points(z$year[z$year %in% c(2000,2017)],z$maternal_mortality[z$year %in% c(2000,2017)],pch=16,col=colors[j],cex=.65)
 }
}
par(mar=c(0,0,0,0)); plot.new()
legend('center',legend=e$country_name,col=colors,lty=1+(seq_len(nrow(e))-1)%%3,lwd=2,ncol=5,bty='n',cex=.8)
mtext('Selection: MMR in 2017 > MMR in 2000. Source: supplied maternal_mortality.csv. Lines show observed annual estimates.',side=1,line=-.7,cex=.65)
dev.off()
