#! /usr/bin/Rscript
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library('extraDistr')
library('poweRlaw')
library('zoo')
library('tidyverse')


source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')

source('base_params.R')
source('ggplot_params.R')


for (i in c('process_1', 'deterministic')){
  seir = read.csv(paste('seir/', toString(i), '.csv', sep=''))
  seir$deconvolved = deconvolve(seir$t, seir$obs_symptomatic_incidence, detection_pdf)
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]
  seir$shifted_symptomatic = shift(n_day_smoother(seir$obs_symptomatic_incidence), -1*mean_detection)
  
  select_cols = c('deconvolved', 'shifted_symptomatic', 'scaled_expected_incidence') 
  label_cols =  c('deconvolved symptomatic', 'shifted symptomatic', 'expected incidence') 
  labels =  labs(x='time', y='incidence', title='Deconvolution vs shift', col='Incidence type')

  plot = create_plot(seir, select_cols, label_cols, c(0.75, 0.75, 0.75), labels)
  print(plot)
  ggsave(paste('figures/deconv_', toString(i), '.png', sep=''), width=width, height=height)



  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0
  obj = extrapolate(seir, 'expected_incidence')
  data_of_interest = obj$data
  cori_expected = cori_estimation(data_of_interest, generation_int) 

  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori_obs = cori_estimation(data_of_interest, generation_int, -1*mean_detection) 

  
  obj = extrapolate(seir, 'deconvolved')
  data_of_interest = obj$data
  cori_rl = cori_estimation(data_of_interest, generation_int)
  
  ggplot_df = data.frame(X = cori_rl$mean_t, expected=cori_expected$`Mean(R)`, 
                         obs=cori_obs$`Mean(R)`, rl=cori_rl$`Mean(R)`) 
  true_rt = seir$Rt[is.element(seir$t, ggplot_df$X)]
  ggplot_df$true = pad(true_rt, ggplot_df$X)


  #  pivot_longer(cols=!mean_t)
  labels = labs(x='time', y='R(t)', title='', col='Incidence type')
  
  plot = create_plot(ggplot_df, c('true', 'expected', 'obs', 'rl'),  c('true', 'expected', 'obs', 'rl'), c(1, 0.75, 0.75, 0.75), labels) +
    ylim(0, 3)
  print(plot)
  
  ggsave(paste('figures/estim_deconv_', toString(i), '.png', sep=''), width=width, height=height)

}













