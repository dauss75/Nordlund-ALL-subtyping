#!/opt/apps/R/3.0.1/bin/Rscript

#===============================================================================
#   Supplementary figure 3
#-------------------------------------------------------------------------------

load("results/tuning.Rdata")

qfun <- function(x) tryCatch(quantile(x, c(.1, .9)), error=function(...) c(NA, NA))
error.mean <- sapply(error, apply, 2, mean)
error.mean.min <- min(error.mean, na.rm=TRUE)
error.quantile <- lapply(error, apply, 2, qfun)
ppv.mean <- lapply(ppv, apply, c(1,3), mean, na.rm=TRUE)
npv.mean <- lapply(npv, apply, c(1,3), mean, na.rm=TRUE)
ppv.lim <- range(c(unlist(ppv.mean), unlist(npv.mean)))
class.labels <- sub("^ref", "Ref", sub("^sex", "Sex",
        colnames(probs$separate[[1]][[1]])))


pdf("results/S3_tuning.pdf", 14/cm(1), 12/cm(1))
pars <- list(ps=8, tcl=-.3, mar=c(3,3,m,m), cex=1)
pal <- c("blue", "red")
xd <- .75
xf <- cumsum(c(0, 1.5, 1,1,1,1)); xf <- xf/tail(xf, 1)
yf <- cumsum(c(0, 1.5, 1)); yf <- c(yf/tail(yf, 1)/2, 1)
m <- .5
screens <- split.screen(cbind(
     left = c(0, xd, xf[c(1:5,1:5)]),
     right = c(xd, 1, xf[c(2:6,2:6)]),
     bottom = rep(yf[3:1], c(2,5,5)),
     top = rep(yf[4:2], c(2,5,5))))

screen(screens[1])
do.call(par, pars)
plot(c(0, 100), rep(error.mean.min, 2), type="l", col="#e6e6e6", axes=FALSE, ann=FALSE, bty="n",
     xlim=c(1,25), ylim=range(c(unlist(error.mean), unlist(error.quantile)), na.rm=TRUE))
matplot(error.mean, type="l", lty=1, col=pal, add=TRUE)
for(i in 1:2) matplot(t(error.quantile[[i]]), type="l", lty=2, col=pal[i], add=TRUE)
nice.axis(1, at=c(1,1:5*5), mgp=c(2,.4,0))
nice.axis(2, mgp=c(2,.6,0))
nice.box()
mtext("F", 1, 1.5)
mtext("Error rate", 2, 2.2)

screen(screens[2])
par(mar=c(m,m,m,m))
blank.plot()
legend("top", c("Separate", "Combined", "", "Upper:", "80% CI", "", "Lower:", "PPV", "NPV"),
    lty=c(1,1,NA,NA,2,NA,NA,1:2), col=c(pal,NA,NA,"black",NA,NA,"black", "black"),
    xpd=TRUE, bty="n")

pars$mar[3] <- 1
for(i in 1:10){
    screen(screens[i+2])
    pars$mar[1] <- if(i < 6) m else 2.5
    pars$mar[2] <- if(i %% 5 == 1) 3 else m
    do.call(par, pars)
    blank.plot(c(1,25), c(0,0), ylim=ppv.lim)
    hlines(ceiling(ppv.lim[1]*10):10/10, col="#e6e6e6")
    matplot(sapply(ppv.mean, "[", i, T), type="l", col=pal, lty=1, add=TRUE)
    matplot(sapply(npv.mean, "[", i, T), type="l", col=pal, lty=2, add=TRUE)
    if(i > 5){
        nice.axis(1, at=c(1, 1:5*5), mgp=c(2,.4,0))
        mtext("F", 1, 1.5)
    }
    if((i-1) %% 5 == 0){
        nice.axis(2, mgp=c(2,.6,0))
        mtext("PPV / NPV", 2, 2.2)
    }
    nice.box()
    mtext(class.labels[i], 3, .1)
}
close.screen(all=TRUE)
dev.off()



#===============================================================================
#   Plot validation set classifications
#-------------------------------------------------------------------------------

library(lattice)
library(gtools)
load("results/pred.Rdata")

pal <- rev(c(Reference="black", `T-ALL`="#d70000", HeH="#00ad23",
             `t(12;21)`="#0073ff", `11q23/MLL`="#85624f", `t(1;19)`="#52e0e0",
             `dic(9;20)`="#ff7182", `t(9;22)`="#003aae", iAMP21="#810086"))
plot.data <- data.frame(
    Sample=factor(val.pred$ID, levels=mixedsort(val.pred$ID)),
    stack(val.pred[9:18]))
names(plot.data)[2:3] <- c("Probability", "Class")
plot.data$Class <- factor(as.character(plot.data$Class), levels=rev(names(y)),
                        labels=c("Sex", names(pal)))
plot.data <- plot.data[order(plot.data$Sample),]                    
sexes <- with(plot.data, Probability[Class == "Sex"])
sexes <- sprintf("%s %3.0f%%", ifelse(sexes > .5, "Female", "Male"),
                 100*ifelse(sexes > .5, sexes, 1 - sexes))

pdf("results/validation.pdf", 8, 9)
trellis.par.set(list(fontsize = list(text = 8)))
counter <- 0
print(barchart(Class ~ Probability | Sample, plot.data, subset = Class != "Sex",
    col=rev(pal), as.table=TRUE, scales=list(tck=.5),
    panel=function(...){
        counter <<- counter + 1
        panel.segments(.5, -100, .5, 1000, col="#aaaaaa")
        panel.barchart(...)
        panel.text(1.04, 1, sexes[counter], adj=c(1,.5))
    }))
dev.off()
