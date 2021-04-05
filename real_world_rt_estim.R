#! /usr/bin/Rscript
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


for (i in c('Germany', 'South Korea', 'Italy')){ #
  seir = read.csv(paste('data/', i, '.csv', sep=''))
  seir$date = as.Date(seir$date)
  seir$obs_symptomatic_incidence = seir$new_cases_per_million
  
  seir$nday_smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  seir$smoothed_symptomatic_incidence = seir$nday_smoothed_symptomatic_incidence
  x = c(0:(length(seir$date)-1))
  
  rl = get_RL(seir$smoothed_symptomatic_incidence[!is.na(seir$smoothed_symptomatic_incidence)], x[!is.na(seir$smoothed_symptomatic_incidence)], detection_pdf,stopping_n = 0.5, regularize=0.01, max_iter=50)
  rl = c(rl$RL_result[rl$time>0], rep(NA, length(x) - length(rl$RL_result[rl$time>0])))
  seir$rl = rl
  seir$X = seir$date


  labels = labs(x='date', y='incidence', title=paste('Incidence in', i), col='Transform performed')
  plot = create_plot(seir, c('nday_smoothed_symptomatic_incidence', 'obs_symptomatic_incidence'), c('7-day smoothed', 'Raw data'), c(0.75, 0.25), labels, 'top_left')
  print(plot)
  
  ggsave(paste('figures/smoothing_', toString(i), '.png', sep=''), width=width, height=height)
  
  
  labels = labs(x='date', y='incidence', title=paste('Deconvolution -', i), col='Transform performed')
  plot = create_plot(seir, c('rl', 'nday_smoothed_symptomatic_incidence', 'obs_symptomatic_incidence'), c('Smoothed and deconvolved', '7-day smoothed', 'Raw data'), c(1, 0.25, 0.25), labels, 'top_left')
  print(plot)
  
  ggsave(paste('figures/deconv_', toString(i), '.png', sep=''), width=width, height=height)
  

  seir$X = x
  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0
  obj = extrapolate(seir, 'smoothed_symptomatic_incidence')
  data_of_interest = obj$data
  cori_smoothed = cori_estimation(data_of_interest, generation_int, -1*mean_detection ) 
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori_obs = cori_estimation(data_of_interest, generation_int, -1*mean_detection) 

  obj = extrapolate(seir, 'rl')
  data_of_interest = obj$data
  cori_rl = cori_estimation(data_of_interest, generation_int) 
  
  labels =  labs(x='date', y='R(t)', title=paste('Cori R(t) estimation -', i), col='Transform performed')
  ggplot_df = data.frame(X=cori_smoothed$mean_t, smoothed=cori_smoothed$`Mean(R)`, obs = cori_obs$`Mean(R)`, rl = cori_rl$`Mean(R)`)
  plot = create_plot(ggplot_df, c('smoothed', 'obs', 'rl'), c('Smoothed and shifted', 'Raw data', 'Smoothed and deconvolved'), c(0.5, 0.5, 0.5), labels, 'top_right')
  plot = plot + ylim(0, 3.5)
  plot = plot + xlim(0, x[length(x)])
  print(plot)
  ggsave(paste('figures/estim_', toString(i), '.png', sep=''), width=width, height=height)
  

  rt_smoothed = rt_estimation(seir$smoothed_symptomatic_incidence, -1*mean_detection)
  rt_deconv_smoothed =  rt_estimation(seir$rl)
  
  ggplot_df = data.frame(X = seir$date, rt_smoothed = rt_smoothed, rt_deconv_smoothed=rt_deconv_smoothed)
  
  labels = labs(x='day', y='r(t) (1/day)', title=paste('Fitted r(t) - ', i), col='Transform performed')
  plot = create_plot(ggplot_df, c('rt_smoothed', 'rt_deconv_smoothed'), c('Smoothed and shifted', 'Smoothed and deconvolved'), c(0.75, 0.75), labels, 'top_right')
  plot = plot + ylim(c(-0.3, 0.3))
  print(plot)
  ggsave(paste('figures/rt_', toString(i), '.png', sep=''), width=width, height=height)
}

