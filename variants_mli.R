library('tidyverse')

# Mostly stolen from Mike Li
# https://github.com/wzmli/COVID19-Canada/blob/master/clean.R
##################################################################################
ddconfirmation <- read_csv("http://www.bccdc.ca/Health-Info-Site/Documents/BCCDC_COVID19_Dashboard_Case_Details.csv")

ddtest <- read_csv("http://www.bccdc.ca/Health-Info-Site/Documents/BCCDC_COVID19_Dashboard_Lab_Information.csv")

ddconfirm <- (ddconfirmation
              %>% mutate(Date = Reported_Date + 1) ## hack to make update time match up
              %>% group_by(Date)
              %>% summarise(SourceNewConfirmations = n())
              %>% ungroup()
              %>% mutate(Province = "BC"
                         , SourceNewConfirmations = ifelse(is.na(SourceNewConfirmations), 0, SourceNewConfirmations)
                         , SourceCumConfirmations = cumsum(SourceNewConfirmations)
              )
)

ddtest <- (ddtest
           %>% filter(Region == "BC")
           %>% mutate(Date = Date + 1)
           %>% select(Date, Province = Region, SourceNewTests = New_Tests, SourceTotalTests = Total_Tests) 
)


BCdat <- left_join(ddtest,ddconfirm)

###################################################################################3
dd <- read.csv('https://raw.githubusercontent.com/wzmli/COVID19-Canada/master/COVID19_Canada.csv') %>%
  mutate(Date = as.Date(Date))

## Creating a full date frame, this will automatically fill in missing gaps with NA
## FIXME: Do we really need this extra step? This will help flag people that there are missing days
datevec = as.Date(min(dd[["Date"]]):max(dd[["Date"]]), origin="1970-01-01")
provinces <- unique(dd[["Province"]])
datedf <- data.frame(Date = rep(datevec,length(provinces))
                     , Province = rep(provinces,each=length(datevec))
)

ddclean <- (left_join(datedf,dd)
            %>% left_join(.,BCdat)
            %>% rowwise()
            %>% mutate(calcTotal = sum(c(negative,presumptive_negative,presumptive_positive,confirmed_positive), na.rm=TRUE)
                       , bestTotal = max(c(calcTotal,total_testing,SourceTotalTests),na.rm=TRUE)
                       , cumConfirmations = sum(c(presumptive_positive,confirmed_positive),na.rm=TRUE)  ## Federal definition of a "Case" in include presumptive positive; however, if sum doesn't change but numbers changed, that is not good. Removing the sum."
                       , cumConfirmations = max(c(cumConfirmations,SourceCumConfirmations),na.rm=TRUE)
                       , cumConfirmations = ifelse((Province=="BC") & is.na(SourceCumConfirmations),NA,cumConfirmations) 
            )
            %>% ungroup()
            %>% group_by(Province)
            %>% mutate(
              newConfirmations = diff(c(NA,cumConfirmations))
              , newConfirmations = ifelse(newConfirmations <0, NA, newConfirmations) ## Help fix missing reporting days
              , newTests = diff(c(NA, bestTotal))
              , prop = newConfirmations/newTests
            )
            %>% ungroup()
)


####################3#############################################

dat <- (ddclean
        %>% filter(Province == "ON")
        %>% select(Date
                   , Backlog = under_investigation
                   , cumConfirmations, newConfirmations
                   , cumTests = bestTotal, newTests
                   , Hospitalization, ICU, Ventilator
                   , Deaths = deceased, Resolved = resolved
        )
        %>% mutate(Backlog_ratio = Backlog/newTests
                   , positivity = newConfirmations/newTests
                   , diffBacklog = diff(c(0,Backlog))
                   , diffBacklog_ratio = diffBacklog/newTests
                   , collect = newTests + diffBacklog
        )
)

############################################################################3
screen <- read.csv('https://raw.githubusercontent.com/wzmli/COVID19-Canada/master/Ontario_VOC.csv') %>%
  mutate(Date=as.Date(Date))

surv <- (dat
         %>% select(Date, newTests, newConfirmations)
)

print(surv)

mergedat <- (full_join(screen, surv)
             %>% mutate(
               N501Y_est = newConfirmations*N501Y/N501Y_screen
               , other_est = newConfirmations-N501Y_est
             )
)

print(mergedat)

longdat <- (mergedat
            %>% select(date=Date, other_est, N501Y_est, newConfirmations)
            %>% pivot_longer(cols=!date, names_to="type", values_to="count")
)
write.csv(ddclean, 'data/mli_canadian.csv')
write.csv(longdat, 'data/mli_on_variants.csv')


