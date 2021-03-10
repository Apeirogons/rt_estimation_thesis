library(ggplot2)
library(ggthemes)
library(tidyverse)
source('ggplot_params.R')

data <- read.csv('data/Canada.csv') %>% mutate(date=as.Date(date))
data_US <- read.csv('data/United States.csv') %>% mutate(date=as.Date(date))

data_all <- inner_join(data, data_US, by='date') %>% 
  select(c('date','new_cases_per_million.x', 'new_cases_per_million.y')) %>%
  rename(X=date, Canada =new_cases_per_million.x, US = new_cases_per_million.y)

labels = labs(title='New cases per million', col='Country', x='date', y='new cases per million')
create_plot(data_all, c('Canada', 'US'), c('Canada', 'US'), c(0.75, 0.75), labels)

ggsave('figures/real_dataviz.png', width=width, height=height)