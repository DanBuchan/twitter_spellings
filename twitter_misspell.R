#
# Short R script to 
#
freqs <- read.csv(file="misspell_freqs.csv",head=TRUE,sep=",")
london<-subset(freqs, c(freqs$location)==2)
exeter<-subset(freqs, c(freqs$location)==1)
mean(c(london$misspell_freq))
# London mean = 0.2268672
mean(c(exeter$misspell_freq))
# Exeter mean = 0.1775895

png("histogram.png")
h1 <- hist(c(london$misspell_freq),breaks=30)
h2 <- hist(c(exeter$misspell_freq),breaks=30)
plot( h1, col=rgb(0,0,1,1/4))
plot( h2, col=rgb(0,0,1,1/4), add=T)
dev.off()