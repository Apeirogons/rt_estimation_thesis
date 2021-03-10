#! /usr/bin/Rscript
library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('tidyverse')
library('ggthemes')
library('ggplot2')


source('ts_utils/process_utils.R')
source('ts_utils/process_noise_simulation.R')
source('ts_utils/deterministic_simulation.R')
source('base_params.R')
source('ggplot_params.R')
########################################################################################3

plotter = function(df, sim_title, width=10.4, height=6.15){
  df = df %>% rename(X=t)
  labels = labs(x='t', y='incidence', title=paste(sim_title, ' incidence', sep=''), col='')
  plot = create_plot(df, c('expected_incidence','obs_symptomatic_incidence'),  c('expected incidence','symptomatic incidence'), c(0.5, 0.5), labels)
  print(plot)
  ggsave(paste('figures/', sim_title, '_incidence.png', sep=''), width=width, height=height)
  
  
  labels = labs(x='t', y='Prevalent cases', title=paste(sim_title, ' prevalence', sep=''), col='')
  plot = create_plot(df, c('E','I'),  c('E','I'), c(0.5, 0.5), labels)
  print(plot)
  ggsave(paste('figures/', sim_title, '_prevalence.png', sep=''), width=width, height=height)
  
  labels = labs(x='t', y='R(t)',  title=paste(sim_title, ' Rt', sep=''), col='')
  plot = create_plot(df, c('Rt', 'Rt_case'), c('Rt inst.', 'Rt_case'), c(0.5, 0.5), labels)
  print(plot)
  
  ggsave(paste('figures/', sim_title, '_Rt.png', sep=''), width=width, height=height)}


########################################################################################
# Create file path
file_path = 'seir'
dir.create(file.path(file_path), showWarnings = FALSE)
file_path = 'figures'
dir.create(file.path(file_path), showWarnings = FALSE)


df = simulate_deterministic(10000000, 10, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob, noise='none')#'observation')
write.csv(df, 'seir/deterministic.csv')
print('Iteration 0: deterministic')
plotter(df, 'Fully deterministic')



for(i in c(1:3)){
  df = simulate_deterministic(10000000, 10, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob, noise='observation')

  write.csv(df, paste('seir/simple_observation_', toString(i), '.csv', sep=''))
  print(paste('Iteration: ', toString(i)))
  plotter(df, paste('simple_observation_', toString(i), sep=''))
}

for(i in c(1:3)){
  df = simulate_process(10000000, 10, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob)
  
  write.csv(df, paste('seir/process_', toString(i), '.csv', sep=''))
  print(paste('Iteration: ', toString(i)))
  plotter(df, paste('process_', toString(i), sep=''))
}

# Dying out happens with high certainty!

for(i in c(1)){

  df = simulate_process(10000000, 1, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob)
  while(df$obs_symptomatic_incidence[400] > 0){
    df = simulate_process(10000000, 1, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob)
  }
  write.csv(df, paste('seir/process_die', toString(i), '.csv', sep=''))
  print(paste('Iteration: ', toString(i)))
  plotter(df, paste('process_die', toString(i), sep=''))
}

