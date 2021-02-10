#! /usr/bin/Rscript
library('deSolve')

library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('data.table')
library('ggthemes')


library('ggplot2')
theme_set(theme_bw())

source('ts_utils/process_utils.R')
source('ts_utils/process_noise_simulation.R')
source('ts_utils/deterministic_simulation.R')


##################################################################################
# Simulation parameters
t = c(0:401)

b = function(t, MU){
  if (t< 150){
    z=2.1
  }
  else if (t < 200){
    z=0.99
  }
  else if (t < 300){
    z=0.9
  }
  else{
    z=1.2
  }
  return(z*MU)
}

# Periodic detection parameters
detection_prob = 0.8
detection_consts = c(1, 1.2, 1.2, 1, 1, 1, 1)

temp = get_detection_pdfs(detection_prob, detection_consts, infectious_pdf, incubation_pdf, detection_pdf)

# Incubation/Infection/Detection distribution parameters
# https://jamanetwork.com/journals/jamanetworkopen/fullarticle/2774707
indices = c(0:50)

# Real-world incubation period (E->I distribution)
inc = dislnorm$new()
inc$setPars(c(1.63, 0.5))

# Infectious period = recovery time
inf = disexp$new()
inf$setPars(c(1/10))


# Detection distribution
det = dislnorm$new()
det$setPars(c(1.7, 0.5))


#####################################################################################################
# Parse parameters

inc$setXmin(0)
incubation_pdf = dist_pdf(inc, q=indices)
incubation_pdf = incubation_pdf/sum(incubation_pdf)

inf$setXmin(0)
infectious_pdf = dist_pdf(inf, q=indices)
infectious_pdf = infectious_pdf/sum(infectious_pdf)

det$setXmin(0)
detection_pdf = dist_pdf(det, q=indices)
detection_pdf = detection_pdf/sum(detection_pdf)

temp = get_detection_pdfs(detection_prob, detection_consts, infectious_pdf, incubation_pdf, detection_pdf)
periodized_detections = temp$periodized_detections
p_greaters = temp$p_greaters
cumulative_time_to_recovery = temp$cumulative_time_to_recovery

#df = data.frame(t=indices, incubation=incubation_pdf, infectious = infectious_pdf)
#write.csv(df, 'incubation_and_infectious.csv')


########################################################################################3

plotter = function(df, sim_title, width=10.4, height=6.15){
  plot = ggplot(df) 
  plot = plot + geom_line(aes(x=t, y=expected_incidence, color='expected_incidence', alpha=0.5)) 
  plot = plot + geom_line(aes(x=t, y=obs_symptomatic_incidence, color='obs_symptomatic_incidence', alpha=0.5)) 
  plot = plot + scale_color_colorblind() 
  plot = plot + labs(x='t', y='incidence', title=paste(sim_title, ' incidence', sep=''))
  print(plot)
  ggsave(paste('figures/', sim_title, '_incidence.png', sep=''), width=width, height=height)
  
  plot = ggplot(df) +  geom_line(aes(x=t, y=E, color='E', alpha=0.5))+ geom_line(aes(x=t, y=I, color='I', alpha=0.5))+  scale_color_colorblind()
  plot = plot + labs(x='t', y='Prevalent cases', title=paste(sim_title, ' prevalence', sep=''))
  print(plot)
  ggsave(paste('figures/', sim_title, '_prevalence.png', sep=''), width=width, height=height)
  
  plot = ggplot(df) + geom_line(aes(x=t, y=Rt, color='Rt inst.', alpha=0.5)) + geom_line(aes(x=t, y=Rt_case, color='Rt case', alpha=0.5)) 
  plot = plot + labs(x='t', y='R(t)',  title=paste(sim_title, ' Rt', sep=''))
  plot = plot + scale_color_colorblind() 
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



for(i in c(1:5)){
  df = simulate_deterministic(10000000, 10, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob, noise='observation')

  write.csv(df, paste('seir/simple_observation_', toString(i), '.csv', sep=''))
  print(paste('Iteration: ', toString(i)))
  plotter(df, paste('simple_observation_', toString(i), sep=''))
}

for(i in c(1:5)){
  df = simulate_process(10000000, 10, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob)
  
  write.csv(df, paste('seir/process_', toString(i), '.csv', sep=''))
  print(paste('Iteration: ', toString(i)))
  plotter(df, paste('process_', toString(i), sep=''))
}

for(i in c(1)){
  df = simulate_process(10000000, 1, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob)
  
  write.csv(df, paste('seir/process_die', toString(i), '.csv', sep=''))
  print(paste('Iteration: ', toString(i)))
  plotter(df, paste('process_die', toString(i), sep=''))
}


