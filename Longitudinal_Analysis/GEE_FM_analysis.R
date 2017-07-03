##### Data import -----
setwd("/Directory_PATH/")

library(ggplot2) # plot
library(geepack) # fit GEE model
library(plyr) # ddply
library(BaylorEdPsych) # test MCAR
library(boot)


df <- read.table("./Data/DataforBIOS699.csv", header = TRUE, sep =",")  # https://www.r-bloggers.com/read-excel-files-from-r/
head(df)
str(df)

# check missing data 
M <- sapply(df, function(x) sum(is.na(x)))
M[M>0]


##### wide to long format -----
df1 <- subset(df, select = c(pid, condition, grpnbr, numsessions, therapysite, 
                             yearfmonset, yearfmdiagnosed, 
                             BPI_PainSeverity_V2, BPI_PainSeverity_V3, BPI_PainSeverity_V4,
                             CESD_TOT_V2, CESD_TOT_V3, CESD_TOT_V4, 
                             GAD7TOTAL_V2, GAD7TOTAL_V3, GAD7TOTAL_V4,
                             AGE, sex, ethnic, race, bmi, 
                             tptotal, acr_fmness, CMSI_Total, 
                             highesteduc, relationstatus, numberhousehold, numberchildren, 
                             currentemployment, hhincome, healthinsurance))

colnames(df1) <- c('PID', 'TRT', 'gp', 'session', 'site', 'onset','diagnosed', 
                   '2.pain', '3.pain', '4.pain', 
                   '2.dep', '3.dep', '4.dep', 
                   '2.anx', '3.anx', '4.anx', 
                   'age', 'gender', 'ethnic', 'race', 'bmi', 'tptotal', 'fmness', 'symptom',
                   'edu', 'relation', 'num_hh', 'numchild', 'empl', 'hh_income', 'health_ins')

df1$PID <- as.character(df1$PID)

# nominal factor 
cols <- c("gp", "session", "gender", "ethnic", "race",  "relation", "empl", "health_ins")
df1[cols] <- lapply(df1[cols], factor)

# ordered factor 
missing.edu <- sapply(df1$edu, function(x) sum(is.na(x)))
missing.edu[missing.edu>0]

# df1$edu
# table(df1$edu)
df1$edu <- factor(df1$edu, labels = c(11,12,13,14,16,18,20), ordered=TRUE) 

missing.hh_income <- sapply(df1$hh_income, function(x) sum(is.na(x)))
missing.hh_income[missing.hh_income>0]

# df1$hh_income
# table(df1$hh_income)
df1$hh_income <- factor(df1$hh_income, labels = c(1,2,3,4,5,6,7,8,9,10), ordered=TRUE) 

# change of pain severity index (outcome)
df1$pain_change_from_baseline_0 <- df1$`2.pain` - df1$`2.pain`
df1$pain_change_from_baseline_3 <- df1$`3.pain` - df1$`2.pain`
df1$pain_change_from_baseline_9 <- df1$`4.pain` - df1$`2.pain`


# http://stackoverflow.com/questions/23945350/reshaping-wide-to-long-with-multiple-values-columns
df2 <- reshape(df1, direction='long', 
               varying=c('2.anx', '2.dep', '2.pain', 'pain_change_from_baseline_0',
                         '3.anx', '3.dep', '3.pain', 'pain_change_from_baseline_3', 
                         '4.anx', '4.dep', '4.pain', 'pain_change_from_baseline_9'), 
               timevar='visitnum',
               times=c('2', '3', '4'),
               v.names=c('pain_change', 'pain', 'dep', 'anx'),
               idvar='PID')

df2 <- df2[order(df2$PID, df2$visitnum),]
rownames(df2) <- seq(length=nrow(df2)) 

# add Time column (0 = visitnum 2, 3 = visitnum 3, 9 = visitnum 4)
df2$Time <- sapply(df2$visitnum, function(x) ifelse(x == 2, 0, ifelse(x == 3, 3, 9)))

# head(df2) # long format
# head(df1) # wide format


# # # test MCAR for fitting GEE ------
# colnames(df2)[2:23]
# 
# MCAR.test <- LittleMCAR(df2[, c(2:23)])
# MCAR.test$amount.missing  # less than 10% in each variables (included in model) -> ignore missing values


##### Exploratory Data Analysis -----
g <- ggplot(df2, aes(x=as.numeric(visitnum), y=pain_change)) +
  geom_line(aes(group = PID)) + 
  geom_smooth(method='loess') + 
  facet_grid(~TRT) + 
  labs(title = "Average Pain Score by Treatments", y = 'Average Pain Score') +
  scale_x_continuous('Times', breaks=seq(2,4,1),labels=c('Baseline', '3 months', '9 months')) + 
  theme_set(theme_grey(base_size = 13)) + 
  theme(axis.text.x = element_text(angle = 60, hjust = 1))
g 

df2.mean <- ddply(df2,~TRT,summarise,mean=mean(pain_change, na.rm=TRUE))

g1 <- ggplot(df2, aes(x=pain_change)) +
  geom_histogram(binwidth=.5, colour="black", fill="white") + 
  facet_grid(~TRT) + 
  ggtitle("Histogram for Average Pain Score by Treatment") + 
  ylab('Frequency') +
  geom_vline(data=df2.mean, aes(xintercept=mean), linetype="dashed", size=1, colour="red")
g1 


# 1) TRT-wise demographic &  information -----
## continuous : age, bmi, tptotal, fmness, symptom
## categorical : gender, ethnic, race, edu, relation, num_hh, numchild, empl, hh_income, health_ins
## primary outcome : pain (or pain change from baseline)
## secondary outcome : dep, anx

# 1.1 for conti : 
# - test normality, and compare means for each TRT gps
# - if normal, one-way ANOVA anova 
# - if not, Kruskal-Wallis test
# 1.2 for categorical : 
# - make a table and check sparsity, and compare proportions for each TRT gps
# - if not sparse, Chi-square test 
# - if sparse, fisher'x exact test

# Demographic Table -------
# total
table(df2[which(df2$visitnum == "2"), 'TRT'])
# age
ddply(df2[which(df2$visitnum == "2"), ], .(TRT), summarise, mean=mean(age, na.rm = TRUE), sd=sd(age, na.rm = TRUE))
# bmi
ddply(df2[which(df2$visitnum == "2"), ], .(TRT), summarise, mean=mean(bmi, na.rm = TRUE), sd=sd(bmi, na.rm = TRUE))
# gender 
tbl1 <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'gender'], exclude = NULL)
colnames(tbl1) <- c("Female", "Male", "Missing")
tbl1
# ethnic 
tbl2 <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'ethnic'], exclude = NULL)
colnames(tbl2) <- c("Hispanic or Latino", "Not Hispanic or Latino", "Missing")
tbl2
# race 
tbl3 <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'race'], exclude = NULL)
colnames(tbl3) <- c("American Indian or Alaskan Native", "Native Hawaiian or Other Pacific Islander", 
                    "Black or African American", "White", "Multi-Racial or Other", "Missing")
tbl3
# edu
tbl4 <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'edu'], exclude = NULL)
colnames(tbl4) <- c("11th grade", "High school graduate or GED", "Some college, no AA", "Technical degree or AA", "College degree (eg. BA/BS)", "Masters (MS, MA)", "Professional degree (eg. PhD, MD)", "Missing")
tbl4
# relation
tbl5 <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'relation'], exclude = NULL)
colnames(tbl5) <- c("Married", "Separated", "Divorced" , "Widowed" , "Never Married" , "Living with a partner in a committed relationship", "Missing")
tbl5
# num_hh 
ddply(df2[which(df2$visitnum == "2"), ], .(TRT), summarise, mean=mean(num_hh, na.rm = TRUE), sd=sd(num_hh, na.rm = TRUE))
table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'num_hh'], exclude = NULL)

# numchild 
ddply(df2[which(df2$visitnum == "2"), ], .(TRT), summarise, mean=mean(numchild, na.rm = TRUE), sd=sd(numchild, na.rm = TRUE))
table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'numchild'], exclude = NULL)

# empl 
tbl8 <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'empl'], exclude = NULL)
colnames(tbl8) <- c("Homemaker", "Unemployed", "Retired", "On disability", "On leave of absence", "Full-time employed", "Part-time employed", "Full-time student only", "Missing")
tbl8

# hh_income 
tbl9 <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'hh_income'], exclude = NULL)
colnames(tbl9) <- c("< $10,000", "$10,000 to $14,999", "$15,000 to $24,999", "$25,000 to $34,999", "$35,000 to $49,999", 
                    "$50,000 to $74,999", "$75,000 to $99,999", "$100,000 to $149,999", "$150,000 to $1999,999", "> $200,000", "Missing")
tbl9
t(tbl9)
# health_ins 
tbl10 <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'health_ins'], exclude = NULL)
colnames(tbl10) <- c("Yes", "No", "Missing")
t(tbl10)
# tptotal
ddply(df2[which(df2$visitnum == "2"), ], .(TRT), summarise, mean=mean(tptotal, na.rm = TRUE), sd=sd(tptotal, na.rm = TRUE))
# fmness
ddply(df2[which(df2$visitnum == "2"), ], .(TRT), summarise, mean=mean(fmness, na.rm = TRUE), sd=sd(fmness, na.rm = TRUE))
# symptom 
ddply(df2[which(df2$visitnum == "2"), ], .(TRT), summarise, mean=mean(symptom, na.rm = TRUE), sd=sd(symptom, na.rm = TRUE))


# normality check for continuous variables (H0 : samples are from normal dist'n) -----
# age : follows normal
with(df2[which(df2$visitnum == 2),],tapply(age,list(TRT),function(x) if (length(unique(x))==1) NA else shapiro.test(x))) 
# bmi : not follow normal 
with(df2[which(df2$visitnum == 2),],tapply(bmi,list(TRT),function(x) if (length(unique(x))==1) NA else shapiro.test(x))) 
# # dep : not follow normal
# with(df2[which(df2$visitnum == 2),],tapply(dep,list(TRT),function(x) if (length(unique(x))==1) NA else shapiro.test(x)))
# # anx : not follow normal
# with(df2[which(df2$visitnum == 2),],tapply(anx,list(TRT),function(x) if (length(unique(x))==1) NA else shapiro.test(x)))
# tptotal : not follow normal
with(df2[which(df2$visitnum == 2),],tapply(tptotal,list(TRT),function(x) if (length(unique(x))==1) NA else shapiro.test(x))) 
# fmness : not follow normal
with(df2[which(df2$visitnum == 2),],tapply(fmness,list(TRT),function(x) if (length(unique(x))==1) NA else shapiro.test(x))) 
# symptom : follow normal
with(df2[which(df2$visitnum == 2),],tapply(symptom,list(TRT),function(x) if (length(unique(x))==1) NA else shapiro.test(x))) 

# anova test for age : no difference
g.age <- ggplot(df2[which(df2$visitnum == 2),], aes(x=TRT, y=age)) + 
  geom_boxplot(aes(fill=TRT)) + 
  labs(x="") + 
  theme_bw() + 
  theme(strip.background=element_rect(fill="black")) + 
  theme(strip.text=element_text(color="white", face="bold")) +
  ggtitle("Age at Baseline for each Treatment") 
g.age

g<-lm(df2[which(df2$visitnum == 2),'age']~df2[which(df2$visitnum == 2),'TRT'])
anova(g) # H0 : same means across gps

# Kruskal-Wallis test for bmi : no difference
g.bmi <- ggplot(df2[which(df2$visitnum == 2),], aes(x=TRT, y=bmi)) + 
  geom_boxplot(aes(fill=TRT)) + 
  labs(x="") + 
  theme_bw() + 
  theme(strip.background=element_rect(fill="black")) + 
  theme(strip.text=element_text(color="white", face="bold")) +
  ggtitle("BMI at Baseline for each Treatment") 
g.bmi
kruskal.test(df2[which(df2$visitnum == 2),'bmi']~df2[which(df2$visitnum == 2),'TRT']) # H0 : same means across gps

# # Kruskal-Wallis test for dep : difference
# g.dep <- ggplot(df2[which(df2$visitnum == 2),], aes(x=TRT, y=dep)) +
#   geom_boxplot(aes(fill=TRT)) +
#   labs(x="") +
#   theme_bw() +
#   theme(strip.background=element_rect(fill="black")) +
#   theme(strip.text=element_text(color="white", face="bold")) +
#   ggtitle("Depression at Baseline for each Treatment")
# g.dep
# kruskal.test(df2[which(df2$visitnum == 2),'dep']~df2[which(df2$visitnum == 2),'TRT']) # H0 : same means across gps
# 
# # Kruskal-Wallis test for anx : difference
# g.anx <- ggplot(df2[which(df2$visitnum == 2),], aes(x=TRT, y=anx)) +
#   geom_boxplot(aes(fill=TRT)) +
#   labs(x="") +
#   theme_bw() +
#   theme(strip.background=element_rect(fill="black")) +
#   theme(strip.text=element_text(color="white", face="bold")) +
#   ggtitle("Anxiety at Baseline for each Treatment")
# g.anx
# kruskal.test(df2[which(df2$visitnum == 2),'anx']~df2[which(df2$visitnum == 2),'TRT']) # H0 : same means across gps

# Kruskal-Wallis test for tptotal : no difference
g.tptotal <- ggplot(df2[which(df2$visitnum == 2),], aes(x=TRT, y=tptotal)) + 
  geom_boxplot(aes(fill=TRT)) + 
  labs(x="") + 
  theme_bw() + 
  theme(strip.background=element_rect(fill="black")) + 
  theme(strip.text=element_text(color="white", face="bold")) +
  ggtitle("Total Tender Points at Baseline for each Treatment") 
g.tptotal
kruskal.test(df2[which(df2$visitnum == 2),'tptotal']~df2[which(df2$visitnum == 2),'TRT']) # H0 : same means across gps

# Kruskal-Wallis test for fmness : no difference
g.fmness <- ggplot(df2[which(df2$visitnum == 2),], aes(x=TRT, y=fmness)) + 
  geom_boxplot(aes(fill=TRT)) + 
  labs(x="") + 
  theme_bw() + 
  theme(strip.background=element_rect(fill="black")) + 
  theme(strip.text=element_text(color="white", face="bold")) +
  ggtitle("fmness Tender Points at Baseline for each Treatment") 
g.fmness
kruskal.test(df2[which(df2$visitnum == 2),'fmness']~df2[which(df2$visitnum == 2),'TRT']) # H0 : same means across gps

# Kruskal-Wallis test for symptom : no difference (boundary)
g.symptom <- ggplot(df2[which(df2$visitnum == 2),], aes(x=TRT, y=symptom)) + 
  geom_boxplot(aes(fill=TRT)) + 
  labs(x="") + 
  theme_bw() + 
  theme(strip.background=element_rect(fill="black")) + 
  theme(strip.text=element_text(color="white", face="bold")) +
  ggtitle("symptom Tender Points at Baseline for each Treatment") 
g.symptom
kruskal.test(df2[which(df2$visitnum == 2),'symptom']~df2[which(df2$visitnum == 2),'TRT']) # H0 : same means across gps

g1<-lm(df2[which(df2$visitnum == 2),'symptom']~df2[which(df2$visitnum == 2),'TRT'])
anova(g1) # H0 : same means across gps

# num_hh : no difference
kruskal.test(df2[which(df2$visitnum == 2),'num_hh']~df2[which(df2$visitnum == 2),'TRT']) # H0 : same means across gps

tbl.num_hh <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'num_hh'])
fisher.test(tbl.num_hh, workspace=2e9)

# numchild : no difference
kruskal.test(df2[which(df2$visitnum == 2),'numchild']~df2[which(df2$visitnum == 2),'TRT']) # H0 : same means across gps

tbl.numchild <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'numchild'])
fisher.test(tbl.numchild)


# same proportionality check for categorical variables (H0 : same proportions) -----
# gender : no difference
tbl.gender <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'gender'])
fisher.test(tbl.gender)

# ethnic : no difference
tbl.ethnic <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'ethnic'])
fisher.test(tbl.ethnic)

# race : no difference
tbl.race <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'race'])
fisher.test(tbl.race)

# edu : no difference
tbl.edu <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'edu'])
fisher.test(tbl.edu, workspace=2e9)

# relation : no difference
tbl.relation <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'relation'])
fisher.test(tbl.relation)

# empl : no difference
tbl.empl <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'empl'])
fisher.test(tbl.empl, workspace=2e9)

# hh_income : no difference
tbl.hh_income <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'hh_income'])
fisher.test(tbl.hh_income, workspace=2e9)

# health_ins : no difference
tbl.health_ins <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'health_ins'])
fisher.test(tbl.health_ins)

#####  check the site effect -----
# site effect check -> no difference
tbl.site <- table(df2[which(df2$visitnum == 2),'TRT'], df2[which(df2$visitnum == 2),'site'])
tbl.site
fisher.test(tbl.site)



################################################################################################################
##### GEE fitting -----
# ref : https://stats.stackexchange.com/questions/86309/marginal-model-versus-random-effects-model-how-to-choose-between-them-an-advi
# for linear model (continuous response), the estimates of marginal and conditional (random-effects) models coincide. 
# In this study, since the main goal is to compare the efficacies of treatments in the marginal level, 
# GEE model is preferred than LMM.

# TRT : EET (control), CBT & EDU (TRT)
cor(df1[,c('2.pain', '3.pain', '4.pain')], use = "complete.obs")  # exchangeable covariance structure (compound symmetry)
cor(cbind(df2[df2$visitnum == 3, 'pain_change'], df2[df2$visitnum == 4, 'pain_change']), use = "complete.obs")   # exchangeable covariance structure (compound symmetry)

df3$TRTn <- sapply(df3$TRT, function(x) ifelse(x == 'EET' , 1, ifelse(x == 'CBT', 2, 3))) # 1 = EET, 2 = CBT, 3 = EDU
df3$Time.CBT <- df3$Time*(df3$TRTn == 2)
df3$Time.EDU <- df3$Time*(df3$TRTn == 3)
df3$Time.CBT.EDU <- df3$Time*I(df3$TRTn != 1)

df3$Time.knot3 <- sapply(df3$Time, function(x) ifelse(x > 1 , x, 0))
df3$Time.CBT.knot3 <- df3$Time.knot3*(df3$TRTn == 2)
df3$Time.EDU.knot3 <- df3$Time.knot3*(df3$TRTn == 3)


head(df3[, c('TRT', 'TRTn', 'Time', 'Time.knot3', 'Time.CBT', 'Time.CBT.knot3', 'Time.EDU', 'Time.EDU.knot3')], 20)

# spline GEE ------
m.spline <- geeglm(pain_change ~ -1 + Time + Time.knot3 + Time.CBT + Time.CBT.knot3 + Time.EDU + Time.EDU.knot3, family = gaussian, data = df3, id = PID, corstr = "exch", std.err = "san.se")
summary(m.spline)

m.spline.EET <- geeglm(pain_change ~ -1 + Time + Time.knot3, family = gaussian, data = df3, id = PID, corstr = "exch", std.err = "san.se")
summary(m.spline.EET)  # test for H0 : EET effect = CBT = EDU = 0 ; reject H0

m.spline.CBT <- geeglm(pain_change ~ -1 + Time + Time.knot3 + Time.CBT + Time.CBT.knot3, family = gaussian, data = df3, id = PID, corstr = "exch", std.err = "san.se")
summary(m.spline.CBT)

m.spline.EDU <- geeglm(pain_change ~ -1 + Time + Time.knot3 + Time.EDU + Time.EDU.knot3, family = gaussian, data = df3, id = PID, corstr = "exch", std.err = "san.se")
summary(m.spline.EDU)

anova(m.spline.EET, m.spline) 
anova(m.spline.EET, m.spline.CBT)  # CBT = EET 
anova(m.spline.EET, m.spline.EDU)  # EDU =/= EET 



##### diagnostic -----
# transformed residual vs. fitted values
non.missing.idx <- as.numeric(rownames(as.data.frame(m$residuals)))
non.missing.TRT <- df3[as.numeric(rownames(df3)) %in% non.missing.idx, 'TRT']
non.missing.Time <- df3[as.numeric(rownames(df3)) %in% non.missing.idx, 'Time']

df4 <- as.data.frame(cbind(non.missing.TRT, non.missing.Time, m$residuals, m$fitted.values))
colnames(df4) <- c("TRT", "Time", "resids", "fitted")

ggplot(data = df4[which(df4$Time == 9),], aes(x=fitted, y=resids, colors = TRT)) +
  geom_point() +
  geom_hline(aes(yintercept=0, colour = "red")) +
  labs(title = "Residual vs. Fitted Values of Average Pain Score Change from Baseline") +
  xlab("Fitted values of Average Pain Score Change from Baseline") +
  ylab("Residuals") +
  theme(legend.position="none")

# q-q plot
# reg : http://stackoverflow.com/questions/4357031/qqnorm-and-qqline-in-ggplot2
qqplot.data <- function (vec, timeline){
  # following four lines from base R's qqline()
  y <- quantile(vec[!is.na(vec)], c(0.25, 0.75))
  x <- qnorm(c(0.25, 0.75))
  slope <- diff(y)/diff(x)
  int <- y[1L] - slope * x[1L]
  
  d <- data.frame(resids = vec)
  
  ggplot(d, aes(sample = resids)) + stat_qq() +
    geom_abline(slope = slope, intercept = int) +
    labs(title = paste("Q-Q plot (at ", timeline, ")", sep='')) +
    xlab("Theoretical Quantiles from Normal Distribution") +
    ylab("Observed Quantiles from Model")
}

time.char <- c("Baseline", "3 months follow-up", "6 months follow-up")
# qqplot.data(df4[which(df4$Time == 0),'resids'], time.char[1])
qqplot.data(df4[which(df4$Time == 3),'resids'], time.char[2])
qqplot.data(df4[which(df4$Time == 9),'resids'], time.char[3])



##### plots for presentation ------
# For each measurement, if they follow normal distribution, 
# calculate mean and sd, and plot overall mean trend plot with CI by groups

# df3.2 <- df3[which(df3$visitnum == "2"), c('pain_change', 'TRT')]
df3.3 <- df3[which(df3$visitnum == "3"), c('pain_change', 'TRT')]
df3.4 <- df3[which(df3$visitnum == "4"), c('pain_change', 'TRT')]

# summary.stat.2 <- ddply(df3[which(df3$visitnum == "2"), ], .(TRT), summarise, mean=mean(pain_change, na.rm = TRUE), sd=sd(pain_change, na.rm = TRUE))
summary.stat.3 <- ddply(df3[which(df3$visitnum == "3"), ], .(TRT), summarise, mean=mean(pain_change, na.rm = TRUE), sd=sd(pain_change, na.rm = TRUE))
summary.stat.4 <- ddply(df3[which(df3$visitnum == "4"), ], .(TRT), summarise, mean=mean(pain_change, na.rm = TRUE), sd=sd(pain_change, na.rm = TRUE))

summary.plot <- function(stat, data, timeline){
  ggplot(data, aes(x=pain_change)) +
    geom_histogram(aes(y=..density.., fill = TRT), position="identity", binwidth=.5, alpha=0.5) + 
    facet_wrap(~TRT) +
    with(stat[stat$TRT=="EET",], stat_function(data = data[data$TRT=="EET",], fun = dnorm, color="blue", args=list(mean=mean, sd=sd))) +
    with(stat[stat$TRT=="CBT",], stat_function(data = data[data$TRT=="CBT",], fun = dnorm, color="red", args=list(mean=mean, sd=sd))) +
    with(stat[stat$TRT=="EDU",], stat_function(data = data[data$TRT=="EDU",], fun = dnorm, color="green", args=list(mean=mean, sd=sd))) +
    theme_bw() +
    labs(title = paste("Histogram of Pain Score Change from Baseline at ", timeline, sep=''), x = "Pain Score Change from Baseline", y = "Frequency")
}

# summary.plot(summary.stat.2, df3.2, time.char[1])
summary.plot(summary.stat.3, df3.3, time.char[2])
summary.plot(summary.stat.4, df3.4, time.char[3])



##### -----
stats <- rbind(cbind(summary.stat.2, visitnum = rep(2,3)), cbind(summary.stat.3, visitnum = rep(3,3)), cbind(summary.stat.4, visitnum = rep(4,3)))

# with CI 
ggplot(stats,aes(x=visitnum,y=mean,color=TRT)) +
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.1) +
  geom_line() + 
  geom_point() + 
  scale_x_continuous(breaks=c(2,3,4), labels=c("0 month", "3 months", "9 months")) + 
  labs(title = "Mean of Pain Score Change from Baseline", x = "Time from Baseline", y = "Mean of Pain Score Change") +
  theme(plot.title = element_text(face="bold", color="black", size=rel(1.5))) + 
  theme(axis.text.x = element_text(size=15), axis.text.y = element_text(size=15)) +
  theme(axis.title.x = element_text(size = rel(1.5))) + 
  theme(axis.title.y = element_text(size = rel(1.5)))


# w/o CI 
ggplot(stats,aes(x=visitnum,y=mean,color=TRT)) +
  geom_line() + 
  geom_point() + 
  scale_x_continuous(breaks=c(2,3,4), labels=c("0 month", "3 months", "9 months")) + 
  labs(title = "Mean of Pain Score Change from Baseline", x = "Time from Baseline", y = "Mean of Pain Score Change") +
  theme(plot.title = element_text(face="bold", color="black", size=rel(1.5))) + 
  theme(axis.text.x = element_text(size=15), axis.text.y = element_text(size=15)) +
  theme(axis.title.x = element_text(size = rel(1.5))) + 
  theme(axis.title.y = element_text(size = rel(1.5)))



# in paper, 
fX <- 1.3
ggplot(stats,aes(x=visitnum,y=mean,color=TRT)) +
  geom_line() + 
  geom_point() + 
  scale_x_continuous(breaks=c(2,3,4), labels=c("0 month", "3 months", "9 months")) + 
  labs(title = "Mean of Change in Pain Score From Baseline", x = "Time from Baseline", y = "Mean of Pain Score Change") +
  theme(plot.title = element_text(color="black", size=rel(fX))) + 
  theme(axis.text.x = element_text(size=rel(fX*1.1)), axis.text.y = element_text(size=rel(fX*1.1))) +
  theme(axis.title.x = element_text(size = rel(fX)), axis.title.y = element_text(size = rel(fX))) + 
  theme(legend.title=element_text(size=rel(fX)), legend.text=element_text(size=rel(fX)))




