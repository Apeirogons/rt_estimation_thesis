#! /usr/bin/Rscript
library('reticulate')
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library('extraDistr')
library('poweRlaw')
library('zoo')


source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')

source('base_params.R')
source('ggplot_params.R')

desired = c('deterministic')
simple_obs = c()
for(i in c(1:2)){
  simple_obs = append(simple_obs, paste('simple_observation_', toString(i),sep=''))
}
desired = append(desired, simple_obs)

use_condaenv('MachineLearning')
source_python('ts_utils/deconvolution.py')


#rt_estimation = function(incidence, shift_amt = 0){
#  rt_smoothed = sg_filter(incidence, window_length=19, polyorder=0)

#  rt_smoothed = data.table::shift(rt_smoothed, shift_amt)
#  rt_smoothed = pad(rt_smoothed, incidence)
#  return(rt_smoothed)
#}


for(i in desired){
  print(i)
  seir = read.csv(paste('seir/', i,'.csv', sep=''))
  
  seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  
  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0
  obj = extrapolate(seir, 'expected_incidence')
  data_of_interest = obj$data
  cori_expected = cori_estimation(data_of_interest, generation_int) 
  
  obj = extrapolate(seir, 'smoothed_symptomatic_incidence')
  data_of_interest = obj$data
  cori_smoothed = cori_estimation(data_of_interest, generation_int, -1*mean_detection) 
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori_obs = cori_estimation(data_of_interest, generation_int, -1*mean_detection) 


  ggplot_df = data.frame(X=cori_smoothed$mean_t, smoothed=cori_smoothed$`Mean(R)`, obs = cori_obs$`Mean(R)`, expected = cori_expected$`Mean(R)`)
  
  true_rt = seir$Rt[is.element(seir$t, ggplot_df$X)]
  ggplot_df$true = pad(true_rt, ggplot_df$X)
  labels =  labs(x='date', y='R(t)', title=paste('Cori R(t) estimation'), col='')
  plot = create_plot(ggplot_df, c('true', 'smoothed', 'obs', 'expected'),  c('True R(t)', 'Expected incidence of infection', 'Shifted symptomatic', 'Deconvolved symptomatic'), c(0.75, 0.5, 0.5, 0.5), labels, 'top_right')
  plot = plot + ylim(0, 3)
  plot = plot + xlim(0, seir$X[length(seir$X)])
  print(plot)
  ggsave(paste('figures/estim_', toString(i), '.png', sep=''), width=width, height=height)

  

  np_clip <- function(x, a, b) {
    ifelse(x <= a,  a, ifelse(x >= b, b, x))
  }
  
  rt_smoothed = rt_estimation(seir$smoothed_symptomatic_incidence, -1*mean_detection)
  rt_actual = diff(seir$scaled_expected_incidence)/seir$scaled_expected_incidence#[1:(length(seir$scaled_expected_incidence) -1)]
  rt_actual = np_clip(rt_actual, -0.1, 0.1)
  
  ggplot_df = data.frame(X = seir$X, rt_smoothed = rt_smoothed, rt_actual=rt_actual)

  labels = labs(x='day', y='r(t) (1/day)', title='Fitted r(t)', col='')
  plot = create_plot(ggplot_df, c('rt_smoothed', 'rt_actual'), c('Estimated', 'Actual'), c(0.75, 0.75), labels, 'bottom_right')
  plot = plot + ylim(c(-0.1, 0.1))
  print(plot)
  ggsave(paste('figures/rt_', toString(i), '.png', sep=''), width=width, height=height)
  
}



