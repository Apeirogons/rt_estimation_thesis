library(ggplot2)
library(ggthemes)
library(tidyverse)
source('ggplot_params.R')


data = read.csv('data/Canada.csv')
data$date = as.Date(data$date)

data_US = read.csv('data/United States.csv')
data_US$date = as.Date(data_US$date)

data_all = inner_join(data, data_US, by='date')

data_all = data_all %>% 
  select(c('date','new_cases_per_million.x', 'new_cases_per_million.y')) %>%
  rename(cdn_incidence =new_cases_per_million.x, us_incidence = new_cases_per_million.y) %>% 
  pivot_longer(cols=!date) %>%
  mutate(name=name %>% factor() %>% fct_relevel('us_incidence', 'cdn_incidence'))

plot = ggplot(data_all, aes(x=date, y=value,color=name)) + geom_line()

plot = plot + labs(title='New cases per million in various countries')
plot = plot + scale_color_colorblind()
print(plot)
ggsave('figures/real_dataviz.png', width=10.4, height=6.15)