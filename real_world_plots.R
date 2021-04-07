# load packages

library(ggplot2)
library(directlabels)
library(cowplot)
library(colorspace)
library(tidyverse)


source('ts_utils/rt.R')
source('ts_utils/filter.R')
source('base_params.R')
source('ggplot_params.R')
library('reticulate')


i=15
n_shift = 6


np_clip <- function(x, a, b) {
  ifelse(x <= a,  a, ifelse(x >= b, b, x))
}


data <- read.csv('data/Canada.csv') %>%
  select(c('date', 'new_cases_per_million')) %>%
  mutate(date=as.Date(date), count = new_cases_per_million*37590000/1000000)




data <- data %>%
 # mutate(smoothed = sg_filter(count, window_length=7, polyorder=1)) %>%
  mutate(smoothed=filtered[,'fit'], lwr=filtered[,'lwr'], upr=filtered[,'upr']) %>%
  select(c('date', 'count', 'smoothed', 'lwr', 'upr')) %>%
  rename(original_data=count) 


rt_estim_2smoothed = rt_estimation_ci(data$smoothed, data$lwr, data$upr,n=i,level=0.95)



data <- data %>%
  mutate(mean_estim = np_clip(rt_estim_2smoothed$mean, -0.1, 0.1), lower_estim = np_clip(rt_estim_2smoothed$lower, -0.1, 0.1), upper_estim = np_clip(rt_estim_2smoothed$upper,  -0.1, 0.1))

for(z in c(1:10)){
  first_row = data[1, ]
  next_date = first_row$date - 1
  first_row = first_row + NA
  first_row$date = next_date
  
  data = rbind(first_row, data)
}

data <- data %>% 
  mutate(mean_estim = data.table::shift(mean_estim, -n_shift),
         lower_estim = data.table::shift(lower_estim, -n_shift),
         upper_estim = data.table::shift(upper_estim, -n_shift))


rt_group <- data %>%
  select(c('date', 'mean_estim', 'lower_estim', 'upper_estim')) 
  
rt_group <- rt_group %>%
  mutate(group=rep('rt', nrow(rt_group))) 

orig_group <- data %>%
  select(c('date', 'original_data', 'smoothed', 'lwr', 'upr')) 
orig_group <- orig_group %>%
  mutate(group=rep('orig', nrow(orig_group)))


ggplot(rt_group) +
  geom_line(data=rt_group, aes(x=date, y=mean_estim, color='Estimated'), lwd=1)+
  geom_ribbon(data=rt_group, aes(x=date, ymin=lower_estim, ymax=upper_estim), alpha=0.3)+
  
  geom_line(data=orig_group, aes(x=date,y=original_data, color='Observed incidence'), lwd=1) +
#  geom_line(data=orig_group, aes(x=date, y=smoothed, color='Smoothed observed incidence'), lwd=1) +
#  geom_ribbon(data=orig_group, aes(x=date, ymin=lwr, ymax=upr, alpha=0.3))+
  
  scale_color_colorblind()+
  
 # xlim(c(as.Date('2021-02-06'), as.Date('2021-03-08')))+
  
  facet_wrap(~group,scales = "free_y", ncol=1,
             strip.position = "left", labeller=as_labeller(c(rt = "Estimated r(t) (1/day)", orig = "Observed incidence"))) +
  labs(x='date', y=NULL, title='Canada data/estimations', col='') +
  theme( legend.position='none')+
  theme(strip.background = element_blank(),
        strip.placement = "outside") + 
  theme(axis.text.x=element_text(angle=60, hjust=1)) 


  
ggsave('figures/Canada_rt.png', width=width, height=height)

########################################################################

