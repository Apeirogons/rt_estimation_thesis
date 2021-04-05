#! /usr/bin/Rscript
library('reticulate')
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library('extraDistr')
library('poweRlaw')
library('zoo')
library('signal')



source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')
source('base_params.R')
source('ggplot_params.R')

use_condaenv('MachineLearning')
source_python('ts_utils/deconvolution.py')

########################################################################################3

plotter = function(seir,i, title=''){
  z = seir$obs_symptomatic_incidence
  waveletted = wavelet_filter(z, 3, 'db4', cutoff=3000)#wavelet_lp_filter(z, 4, 'db4') 
  
  smoothed_symptomatic_incidence = append(rep(NA, 3), waveletted)
  smoothed_symptomatic_incidence = append(smoothed_symptomatic_incidence, rep(NA, 3))
  smoothed_symptomatic_incidence=waveletted
  seir$smoothed_symptomatic_incidence = smoothed_symptomatic_incidence
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  labels =labs(x='date', y='incidence', title=paste('Wavelet smoothing -', title), col='Incidence type')
  plot = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('Smoothed observed', 'Observed', 'Convolved expected'), c(0.75, 0.25, 0.75), labels, 'bottom_right')
  print(plot)
  ggsave(paste('figures/wavelet_smooth', toString(i), '.png'), width=10.4, height=6.15)
  
  seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  labels =labs(x='t', y='incidence', title=paste('7-day smoothing - ', title), col='Incidence type')
  plot = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('Smoothed observed', 'Observed', 'Convolved expected'), c(0.75, 0.25, 0.75), labels, 'bottom_right')
  print(plot)
  ggsave(paste('figures/7day_smooth_', toString(i), '.png'), width=10.4, height=6.15)
 
  #rep(1, 5)/5,1
  bf <- butter(5,0.2)
  seir$smoothed_symptomatic_incidence =filtfilt(bf, seir$obs_symptomatic_incidence)

  labels =labs(x='t', y='incidence', title=paste('FFT smoothing - ', title), col='Incidence type')
  plot = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('Smoothed observed', 'Observed', 'Convolved expected'), c(0.75, 0.25, 0.75), labels, 'bottom_right')
  print(plot)
  ggsave(paste('figures/fft_smooth_', toString(i), '.png'), width=10.4, height=6.15)


  seir$smoothed_symptomatic_incidence = sg_filter(seir$obs_symptomatic_incidence, window_length=7, polyorder=1)
  
  labels =labs(x='t', y='incidence', title=paste('Savitzky-Golay - ', title), col='Incidence type')
  plot = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('Smoothed observed', 'Observed', 'Convolved expected'), c(1, 0.25, 0.75), labels, 'bottom_right')
  print(plot)
  ggsave(paste('figures/savgol_', toString(i), '.png'), width=10.4, height=6.15)
}
#####################################################################################
dir.create('figures', showWarnings = FALSE)
i = 'deterministic'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i, 'Deterministic')

i = 'process_1'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i, 'Dynamical noise')

i = 'simple_observation_1'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i, 'Observation noise')
