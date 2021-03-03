library(ggplot2)
library(ggthemes)
library(tidyverse)
source('ggplot_params.R')

data <- read.csv('data/Canada.csv') %>% mutate(date=as.Date(date))
data_US <- read.csv('data/United States.csv') %>% mutate(date=as.Date(date))

data_all <- inner_join(data, data_US, by='date')

# While this block isn't actually necessary, I thought it was good practice for figuring out how to reorder ggplot legends.
data_all <- data_all %>% 
  select(c('date','new_cases_per_million.x', 'new_cases_per_million.y')) %>%
  rename(Canada =new_cases_per_million.x, US = new_cases_per_million.y) %>% 
  pivot_longer(cols= !date) %>%
  mutate(name=name %>% factor() %>% fct_relevel('US', 'Canada'))

ggplot(data_all, aes(x=date, y=value,color=name)) + 
  geom_line() +
  labs(title='New cases per million', col='Country') +
  scale_color_colorblind()

ggsave('figures/real_dataviz.png', width=10.4, height=6.15)