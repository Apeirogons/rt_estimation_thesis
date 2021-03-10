# load packages

library(ggplot2)
library(directlabels)
library(cowplot)
library(colorspace)
library(tidyverse)

source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')

source('base_params.R')
source('ggplot_params.R')

data <- read.csv('data/mli_on_variants.csv') %>%
  select(c('date', 'type', 'count')) %>%
  mutate(date=as.Date(date)) %>%
  filter(type=='N501Y_est') %>%
  filter(!is.na(count)) %>%
  mutate(smoothed = rollapply(count, 7, mean, fill=NA, align='center')) %>%
  select(c('date', 'count', 'smoothed')) %>%
  rename(original_data=count) 

ggplot_df <- data %>%
  pivot_longer(cols=!date)

ggplot(ggplot_df)+
  aes(x=date, y=value, color=name) +
  geom_line(lwd=1)+
  scale_color_colorblind()+
  labs(x='date', y='new cases', title='N501Y estimated', col='')
ggsave('figures/N501Y.png', width=width, height=height)
########################################################################


df <- data %>%
  mutate(rt_estim_2smoothed = rt_estimation(smoothed),
         rt_estim_after = rt_estimation(original_data), 
         rt_estim_none = c(diff(log(original_data)), NA)) %>%
  select(c('date', 'rt_estim_2smoothed', 'rt_estim_after', 'rt_estim_none')) %>%
  pivot_longer(cols=!date)


ggplot(df)+
  aes(x=date, y=value, color=name)+
  geom_line(lwd=1) +
  scale_color_colorblind(labels=c('Smoothed twice', 'Smoothed after', 'Not smoothed'))+
  labs(x='date', y='r(t)', title='N501Y r(t) estimated') 

ggsave('figures/N501Y_r(t).png', width=width, height=height)

