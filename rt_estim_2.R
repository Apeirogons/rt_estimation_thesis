#! /usr/bin/Rscript
library('reticulate')
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library(data.table)
library('extraDistr')
library('poweRlaw')
library('zoo')


source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')

use_condaenv('MachineLearning')
source_python('ts_utils/deconvolution.py')
source('base_params.R')
source('ggplot_params.R')

desired = c('deterministic')
simple_obs = c()
for(i in c(1:3)){
  simple_obs = append(simple_obs, paste('simple_observation_', toString(i),sep=''))
}
desired = append(desired, simple_obs)

for(i in desired){
  print(i)
  seir = read.csv(paste('seir/', i,'.csv', sep=''))
  
  seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
#  plot = ggplot(seir) 
#  plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='3-smoothed symptomatic'), alpha=1) 
#  plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
#  plot = plot + geom_line(aes(x=X, y=scaled_expected_incidence, color='4-expected true incidence'), alpha=0.1)
#  plot = plot + geom_line(aes(x=X, y=convolved_expected, color='1-conv. true incidence'), alpha=1)
#  plot = plot + scale_color_colorblind()
#  print(plot)
  
  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0
  obj = extrapolate(seir, 'expected_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  plot = ggplot(data=cori) + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='3. Cori - expected'))+ labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,3)) + scale_color_colorblind()
  plot = plot + geom_line(data=seir, aes(x=X, y=Rt, color='True Rt'))
  
  
  obj = extrapolate(seir, 'smoothed_symptomatic_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
  plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='1. Cori - smoothed symptomatic'), alpha=0.5)
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
  plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='2. Cori - symptomatic'), alpha=0.5)
  print(plot)
  
  ggsave(paste('figures/estim_', toString(i), '.png', sep=''), width=10.4, height=6.15)
  
  rt_smoothed = diff(log(seir$smoothed_symptomatic_incidence))
  rt_smoothed = rollmean(rt_smoothed, 7, fill=NA, align='center')
  rt_smoothed = data.table::shift(rt_smoothed, -1*mean_detection)
  
  ggplot_df = data.frame(x = c(0:(length(seir$smoothed_symptomatic_incidence)-2)), rt_smoothed = rt_smoothed, rt_actual = diff(seir$scaled_expected_incidence)/seir$scaled_expected_incidence[1:(length(seir$scaled_expected_incidence) -1)])
  
  np_clip <- function(x, a, b) {
    ifelse(x <= a,  a, ifelse(x >= b, b, x))
  }
  ggplot_df$rt_actual = np_clip(ggplot_df$rt_actual, -0.1, 0.1)
  
  
  plot = ggplot(ggplot_df)
  plot = plot + geom_line(aes(x=x, y=rt_smoothed, color='1. Estimated r(t)'), alpha=1)
  plot = plot + geom_line(aes(x=x, y=rt_actual, color='2. Actual r(t)'), alpha=0.7)
  plot = plot + labs(x='day', y='r(t)', title='Fitted r(t) vs actual r(t) (actual values clipped)')
  plot = plot + scale_color_colorblind()
  print(plot)
  ggsave(paste('figures/rt_', toString(i), '.png', sep=''), width=10.4, height=6.15)
  }





