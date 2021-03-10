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

use_condaenv('MachineLearning')
source_python('ts_utils/deconvolution.py')

########################################################################################3

plotter = function(seir,i){
  z = seir$obs_symptomatic_incidence
  waveletted = wavelet_filter(z, 3, 'db4', cutoff=3000)#wavelet_lp_filter(z, 4, 'db4') 
  
  smoothed_symptomatic_incidence = append(rep(NA, 3), waveletted)
  smoothed_symptomatic_incidence = append(smoothed_symptomatic_incidence, rep(NA, 3))
  smoothed_symptomatic_incidence=waveletted
  seir$smoothed_symptomatic_incidence = smoothed_symptomatic_incidence
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  labels =labs(x='t', y='incidence', title='Wavelet smoothing', col='')
  plot = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c(1, 0.25, 0.75), labels)
  print(plot)
  ggsave(paste('figures/wavelet_smooth', toString(i), '.png'), width=10.4, height=6.15)
  
  seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  labels =labs(x='t', y='incidence', title='7-day smoothing', col='')
  plot = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c(1, 0.25, 0.75), labels)
  print(plot)
  ggsave(paste('figures/7day_smooth_', toString(i), '.png'), width=10.4, height=6.15)

  
  seir$smoothed_symptomatic_incidence = fft_filter(seir$obs_symptomatic_incidence, 7)
  labels =labs(x='t', y='incidence', title='FFT smoothing', col='')
  plot = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c(1, 0.25, 0.75), labels)
  print(plot)
  ggsave(paste('figures/fft_smooth_', toString(i), '.png'), width=10.4, height=6.15)
}
#####################################################################################
dir.create('figures', showWarnings = FALSE)
i = 'deterministic'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i)

i = 'process_1'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i)

i = 'simple_observation_1'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i)
