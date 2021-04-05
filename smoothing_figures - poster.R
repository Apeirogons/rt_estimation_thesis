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
source('ts_utils/filter.R')

source('base_params.R')
source('ggplot_params.R')

library('reticulate')

########################################################################################3

plotter = function(seir,i, title=''){
  z = seir$obs_symptomatic_incidence
  filtered = linear_filter(seir$obs_symptomatic_incidence, level=0.5)
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))


  seir$smoothed_symptomatic_incidence = filtered[,'fit']#sg_filter(seir$obs_symptomatic_incidence, window_length=7, polyorder=1)
 # ggplot_df = data.frame(X=seir$X, rt_lower = filtered[,'lwr'], rt_upper=filtered[,'upr'])
  
  
  labels =labs(x='day', y='incidence', title=paste('Savitzky-Golay filtering'), col='')
  plot = create_plot(seir, c('smoothed_symptomatic_incidence', 'convolved_expected', 'obs_symptomatic_incidence'), c('Filtered observed incidence', 'Expected observed incidence', 'Observed incidence'), c(0.75, 0.75, 0.25), labels, 'bottom_right')
 # plot = plot + geom_ribbon(data=ggplot_df, aes(x=X, ymin=rt_lower, ymax=rt_upper), alpha=0.3, inherit.aes = FALSE)
  print(plot)
  ggsave(paste('figures/savgol_', toString(i), '.png'), width=10.4, height=6.15)
}
#####################################################################################
dir.create('figures', showWarnings = FALSE)

i = 'simple_observation_1'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i, 'Observation noise')
