#! /usr/bin/Rscript
library('reticulate')
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library(data.table)
library('extraDistr')
library('poweRlaw')
library('zoo')


source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')

use_condaenv('MachineLearning')
theme_set(theme_bw())
source_python('ts_utils/deconvolution.py')



##################################################################################
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
generation_int = convolve(incubation_pdf, rev(infectious_pdf), type='open')

#df = data.frame(t=indices, incubation=incubation_pdf, infectious = infectious_pdf)
#write.csv(df, 'incubation_and_infectious.csv')
mean_generation = sum(c(0:(length(generation_int)-1))*generation_int)

mean_detection = sum(c(0:(length(detection_pdf)-1))*detection_pdf)

########################################################################################3

plotter = function(seir,i){
  z = seir$obs_symptomatic_incidence
  waveletted = wavelet_filter(z, 3, 'db4', cutoff=3000)#wavelet_lp_filter(z, 4, 'db4') 
  
  smoothed_symptomatic_incidence = append(rep(NA, 3), waveletted)
  smoothed_symptomatic_incidence = append(smoothed_symptomatic_incidence, rep(NA, 3))
  smoothed_symptomatic_incidence=waveletted
  seir$smoothed_symptomatic_incidence = smoothed_symptomatic_incidence
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  plot = ggplot(seir) 
  plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='1-smoothed symptomatic'), alpha=1) 
  plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
  plot = plot + geom_line(aes(x=X, y=convolved_expected, color='3-true incidence forward-convolved by weekly mean detection kernel'), alpha=0.75)
  plot = plot + scale_color_colorblind()
  plot = plot + labs(x='t', y='incidence', title='Wavelet smoothing')
  print(plot)
  ggsave(paste('figures/wavelet_smooth', toString(i), '.png'), width=10.4, height=6.15)
  
  seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  plot = ggplot(seir) 
  plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='1-smoothed symptomatic'), alpha=1) 
  plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
  plot = plot + geom_line(aes(x=X, y=convolved_expected, color='3-true incidence forward-convolved by weekly mean detection kernel'), alpha=0.75)
  plot = plot + scale_color_colorblind()
  plot = plot + labs(x='t', y='incidence', title='7-day smoothing')
  print(plot)
  ggsave(paste('figures/7day_smooth_', toString(i), '.png'), width=10.4, height=6.15)

  
  seir$smoothed_symptomatic_incidence = fft_filter(seir$obs_symptomatic_incidence, 7)
  
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  plot = ggplot(seir) 
  plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='1-smoothed symptomatic'), alpha=1) 
  plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
  plot = plot + geom_line(aes(x=X, y=convolved_expected, color='3-true incidence forward-convolved by weekly mean detection kernel'), alpha=0.75)
  plot = plot + scale_color_colorblind()
  plot = plot + labs(x='t', y='incidence', title='FFT smoothing')
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
