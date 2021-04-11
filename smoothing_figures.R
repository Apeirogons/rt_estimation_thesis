#! /usr/bin/Rscript
source('ts_utils/filter.R')

source('base_params.R')
source('ggplot_params.R')



########################################################################################3

plotter = function(seir,i, title='', show_ribbon = FALSE){
  z = seir$obs_symptomatic_incidence
  filtered = linear_filter(seir$obs_symptomatic_incidence)
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))


  seir$smoothed_symptomatic_incidence = filtered[,'fit']#sg_filter(seir$obs_symptomatic_incidence, window_length=7, polyorder=1)
  ggplot_df = data.frame(X=seir$X, rt_lower = filtered[,'lwr'], rt_upper=filtered[,'upr'])
  
  
  labels =labs(x='day', y='incidence', title=title, col='')
  plot = create_plot(seir, c('smoothed_symptomatic_incidence', 'convolved_expected', 'obs_symptomatic_incidence'), c('Filtered observed incidence', 'Expected observed incidence', 'Observed incidence'), c(0.75, 0.75, 0.25), labels, 'bottom_right')
  if (show_ribbon){
    plot = plot + geom_ribbon(data=ggplot_df, aes(x=X, ymin=rt_lower, ymax=rt_upper), alpha=0.3, inherit.aes = FALSE)}
  print(plot)
  ggsave(paste('figures/savgol_', toString(i), '.png', sep=''), width=10.4, height=6.15)
}
#####################################################################################
dir.create('figures', showWarnings = FALSE)

i = 'simple_observation_1'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i, 'Savitzky-Golay filtering')

i = 'simple_observation_1_CI'
plotter(seir, i, 'Savitzky-Golay filtering with confidence intervals', show_ribbon=TRUE)


i = 'simple_observation_blocks'
seir = read.csv(paste('seir/', i, '.csv', sep=''))
plotter(seir, i, 'Savitzky-Golay filtering')

i = 'simple_observation_blocks_CI'
plotter(seir, i, 'Savitzky-Golay filtering with confidence intervals', show_ribbon=TRUE)
