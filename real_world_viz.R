library(ggplot2)
library(ggthemes)
library(tidyverse)
source('ggplot_params.R')

data <- read.csv('data/mli_canadian.csv') %>%
  mutate(date=as.Date(Date)) %>%
  select(c('date', 'Province', 'newConfirmations')) %>%
  pivot_wider(id_cols=date, names_from=Province,values_from=newConfirmations) %>%
  rename(X=date) %>% 
  mutate(ON=as.numeric(ON), QC=as.numeric(QC), AB=as.numeric(AB))%>%
  as.data.frame 
# I am so sorry for the hardcoding.

labels = labs(title='Province-level incidence', col='Province', x='date', y='new confirmed cases')

create_plot(data, c('ON', 'QC', 'AB'), c('ON', 'QC', 'AB'), c(0.75, 0.75, 0.75), labels, 'top_left')
ggsave('figures/real_dataviz.png', width=width, height=height)


#data_US <- read.csv('data/United States.csv') %>% mutate(date=as.Date(date))

#data_all <- inner_join(data, data_US, by='date') %>% 
#  select(c('date','new_cases_per_million.x', 'new_cases_per_million.y')) %>%
#  rename(X=date, Canada =new_cases_per_million.x, US = new_cases_per_million.y)
#labels = labs(title='Country-level incidence', col='Country', x='date', y='new confirmed cases per million')
#create_plot(data_all, c('US', 'Canada'), c('US','Canada'), c(0.75, 0.75), labels, 'top_left')

#ggsave('figures/real_dataviz.png', width=width, height=height)