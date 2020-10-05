#install.packages('installr')
#library(installr)
#updateR()

#install.packages('remotes')
#remotes::install_github("bbolker/bbmle")
#remotes::install_github('bbolker/McMasterPandemic')
library(McMasterPandemic)
library(ggplot2)

params1 = read_params(system.file("params","ICU1.csv",
                                  package="McMasterPandemic"))

knitr::kable(describe_params(params1))
knitr::kable(round(t(summary(params1)),2))
knitr::kable(round(t(get_R0(params1, components=TRUE)),2))
state1 <- make_state(params=params1)

sdate <- "2020-Feb-10"
edate <- "2020-Sep-28"
res1 <- run_sim(params=params1, state=state1, start_date=sdate, end_date=edate)
summary(res1)
head(res1)


ggplot(data=res1, mapping=aes(x=date, y=incidence)) + geom_line(aes(x=date, y=incidence))
ggplot(data=res1, mapping=aes(x=date, y=foi)) + geom_line(aes(x=date, y=foi))