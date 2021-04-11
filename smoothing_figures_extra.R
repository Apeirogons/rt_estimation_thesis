#! /usr/bin/Rscript
library('reticulate')
library('ggplot2')
library('EpiEstim')
library('zoo')
library('signal')

source('base_params.R')
source('ggplot_params.R')

#use_condaenv('MachineLearning')
source_python('ts_utils/deconvolution_and_smoothing.py')

########################################################################################3

plotter = function(seir,i){
  z = seir$obs_symptomatic_incidence
  waveletted = wavelet_filter(z, 3, 'db4', cutoff=3000)#wavelet_lp_filter(z, 4, 'db4') 
  
  smoothed_symptomatic_incidence = append(rep(NA, 3), waveletted)
  smoothed_symptomatic_incidence = append(smoothed_symptomatic_incidence, rep(NA, 3))
  smoothed_symptomatic_incidence=waveletted
  seir$smoothed_symptomatic_incidence = smoothed_symptomatic_incidence
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  labels =labs(x='date', y='incidence', title=paste('Wavelet smoothing'), col='Incidence type')
  p = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('Smoothed observed', 'Observed', 'Expected'), c(0.75, 0.25, 0.75), labels, 'bottom_right')
  print(p)
  ggsave(paste('figures/wavelet_smooth', toString(i), '.png', sep=''), width=width, height=height)
  
  
  seir$smoothed_symptomatic_incidence = rollmean(seir$obs_symptomatic_incidence, 7, align='center', fill=NA)
  labels =labs(x='t', y='incidence', title=paste('7-day smoothing'), col='Incidence type')
  p = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('Smoothed observed', 'Observed', 'Expected'), c(0.75, 0.25, 0.75), labels, 'bottom_right')
  print(p)
  ggsave(paste('figures/7day_smooth_', toString(i), '.png', sep=''), width=width, height=height)
 
  #rep(1, 5)/5,1
  bf <- butter(5,0.2)
  seir$smoothed_symptomatic_incidence =filtfilt(bf, seir$obs_symptomatic_incidence)

  labels =labs(x='t', y='incidence', title=paste('FFT smoothing'), col='Incidence type')
  p = create_plot(seir, c('smoothed_symptomatic_incidence', 'obs_symptomatic_incidence', 'convolved_expected'), c('Smoothed observed', 'Observed', 'Expected'), c(0.75, 0.25, 0.75), labels, 'bottom_right')
  print(p)
  ggsave(paste('figures/fft_smooth_', toString(i), '.png', sep=''), width=width, height=height)


}
#####################################################################################
dir.create('figures', showWarnings = FALSE)



i = 'simple_observation_1'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i)
