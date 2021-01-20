#! /usr/bin/Rscript
library('deSolve')

library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('data.table')
library('ggthemes')


library('ggplot2')

source('ts_utils/process_utils.R')
source('ts_utils/process_noise_simulation.R')



##################################################################################
# Simulation parameters
t = c(-1:401)

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
# Create file path
file_path = 'seir'
dir.create(file.path(file_path), showWarnings = FALSE)


for(i in c(1:100)){

  df = simulate(10000000, 10, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob)

  write.csv(df, paste('seir/', toString(i), '.csv'))
  print(paste('Iteration: ', toString(i)))
}


#######################################################################################










#ggplot(df) +  geom_line(aes(x=t, y=E, color='E'))+ geom_line(aes(x=t, y=I, color='I'))+  scale_color_colorblind()
#+ geom_line(aes(x=t, y=randomized_incidence, color='randomized_incidence', alpha=0.5)) 
# ggplot(df) + geom_line(aes(x=t, y=expected_incidence, color='expected_incidence', alpha=0.5)) + geom_line(aes(x=t, y=obs_symptomatic_incidence, color='obs_symptomatic_incidence', alpha=0.5)) + scale_color_colorblind()
# ggplot(df) + geom_line(aes(x=t, y=Rt, color='Rt inst.')) + geom_line(aes(x=t, y=Rt_case, color='Rt case')) 

#rm(list=ls())