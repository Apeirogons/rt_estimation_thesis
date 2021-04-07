#! /usr/bin/Rscript
library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('tidyverse')
library('ggthemes')
library('ggplot2')


source('ts_utils/process_utils.R')
source('ts_utils/deterministic_simulation.R')

source('base_params.R')
source('ggplot_params.R')
########################################################################################3

plotter = function(df, save_loc, sim_title, width=10.4, height=6.15){
  df = df %>% rename(X=t)
  labels = labs(x='day', y='incidence', title=paste('Simulated disease data'), col='')
  plot = create_plot(df, c('expected_incidence','obs_symptomatic_incidence'),  c('Incidence of infection','Observed incidence'), c(0.75, 0.75), labels,'top_left')
  #plot = plot + geom_vline(xintercept=150, linetype='dashed', color='red', size=2, alpha=0.25)
  #plot = plot + geom_vline(xintercept=200, linetype='dashed', color='red', size=2, alpha=0.25)
  #plot = plot + geom_vline(xintercept=300, linetype='dashed', color='red', size=2, alpha=0.25)
  print(plot)
  ggsave(paste('figures/', save_loc,  '_incidence.png', sep=''), width=width, height=height)
  
  
  labels = labs(x='t', y='Prevalent cases', title=paste('Simulated prevalence'), col='')
  plot = create_plot(df, c('E','I'),  c('Exposed','Infectious'), c(0.9, 0.9), labels, 'top_left')
  print(plot)
  ggsave(paste('figures/', save_loc, '_prevalence.png', sep=''), width=width, height=height)
  
  labels = labs(x='t', y='R(t)',  title=paste('Simulated Rt'), col='')
  plot = create_plot(df, c('Rt', 'Rt_case'), c('Rt inst.', 'Rt_case'), c(0.75, 0.75), labels, 'top_right')
  print(plot)
  
  ggsave(paste('figures/', save_loc, '_Rt.png', sep=''), width=width, height=height)}

#########################################################################################
# Plot R0

R0_t = c()
for(t_step in t){
  R0_t = append(R0_t, R0(t_step))
}
ggplot_df = data.frame(t=t, R0 = R0_t)


ggplot(ggplot_df) +
  geom_line(data=ggplot_df, aes(x=t, y=R0), alpha=1) +
  xlim(0, 400) +
  scale_color_colorblind() +
  labs(title='R0(t)', x='date')


ggsave(paste('figures/R0.png', sep=''), width=width, height=height)


########################################################################################
# Create file path
file_path = 'seir'
dir.create(file.path(file_path), showWarnings = FALSE)
file_path = 'figures'
dir.create(file.path(file_path), showWarnings = FALSE)



for(i in c(1)){
  df = simulate_deterministic(10000000, 10, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob, noise='observation')

  write.csv(df, paste('seir/simple_observation_', toString(i), '.csv', sep=''))
  print(paste('Iteration: ', toString(i)))
  plotter(df, paste('simple_observation_', toString(i), sep=''), '') #re-add 'Observation noise'
}
