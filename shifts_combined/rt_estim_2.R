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



i = 'deterministic'
seir = read.csv(paste('seir/deterministic.csv'))

seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)

seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
plot = ggplot(seir) 
plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='3-smoothed symptomatic'), alpha=1) 
plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
plot = plot + geom_line(aes(x=X, y=scaled_expected_incidence, color='4-expected true incidence'), alpha=0.1)
plot = plot + geom_line(aes(x=X, y=convolved_expected, color='1-true incidence forward-convolved by weekly mean detection kernel'), alpha=1)
plot = plot + scale_color_colorblind()
print(plot)

stopifnot(generation_int[1] < 1e-5)
generation_int[1] = 0
obj = extrapolate(seir, 'expected_incidence')
data_of_interest = obj$data
cori = cori_estimation(data_of_interest, generation_int) 
plot = ggplot(data=cori) + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='3. Cori - expected'))+ labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,3)) + scale_color_colorblind()
plot = plot + geom_line(data=seir, aes(x=X, y=Rt, color='True Rt'))


obj = extrapolate(seir, 'smoothed_symptomatic_incidence')
data_of_interest = obj$data
cori = cori_estimation(data_of_interest, generation_int) 
cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='1. Cori - smoothed symptomatic'), alpha=0.5)

obj = extrapolate(seir, 'obs_symptomatic_incidence')
data_of_interest = obj$data
cori = cori_estimation(data_of_interest, generation_int) 
cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='2. Cori - symptomatic'), alpha=0.5)
print(plot)

ggsave(paste('figures/estim_', toString(i), '.png', sep=''))

rt_smoothed = diff(seir$smoothed_symptomatic_incidence)/seir$smoothed_symptomatic_incidence[1:(length(seir$smoothed_symptomatic_incidence) -1)]
rt_smoothed = rollmean(rt_smoothed, 7, fill=NA, align='center')
rt_smoothed = data.table::shift(rt_smoothed, mean_detection)

ggplot_df = data.frame(x = c(0:(length(seir$smoothed_symptomatic_incidence)-2)), rt_smoothed = rt_smoothed, rt_actual = diff(seir$scaled_expected_incidence)/seir$scaled_expected_incidence[1:(length(seir$scaled_expected_incidence) -1)])

np_clip <- function(x, a, b) {
  ifelse(x <= a,  a, ifelse(x >= b, b, x))
}
ggplot_df$rt_actual = np_clip(ggplot_df$rt_actual, -0.1, 0.1)


plot = ggplot(ggplot_df)
plot = plot + geom_line(aes(x=x, y=rt_smoothed, color='1. Estimated r(t)'), alpha=1)
plot = plot + geom_line(aes(x=x, y=rt_actual, color='2. Actual r(t)'), alpha=0.7)
plot = plot + labs(x='day', y='r(t)', title='Fitted r(t) vs actual r(t) - for visualization actual values are clipped')
plot = plot + scale_color_colorblind()
print(plot)
ggsave(paste('figures/rt_', toString(i), '.png', sep=''))



for(i in c(1:5)){
  
  seir = read.csv(paste('seir/simple_observation_', toString(i), '.csv', sep=''))
  seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence, 14)
  
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  plot = ggplot(seir) 
  plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='3-smoothed symptomatic'), alpha=1) 
  plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
  plot = plot + geom_line(aes(x=X, y=scaled_expected_incidence, color='4-expected true incidence'), alpha=0.1)
  plot = plot + geom_line(aes(x=X, y=convolved_expected, color='1-true incidence forward-convolved by weekly mean detection kernel'), alpha=1)
  plot = plot + scale_color_colorblind()
  print(plot)
  
  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0
  obj = extrapolate(seir, 'expected_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  plot = ggplot(data=cori) + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='3. Cori - expected'))+ labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,3)) + scale_color_colorblind()
  plot = plot + geom_line(data=seir, aes(x=X, y=Rt, color='True Rt'))
  
  
  obj = extrapolate(seir, 'smoothed_symptomatic_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
  plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='1. Cori - smoothed symptomatic'), alpha=0.5)
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
  plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='2. Cori - symptomatic'), alpha=0.5)
  print(plot)
  
  ggsave(paste('figures/estim_', toString(i), '.png'))
  


  
  rt_smoothed = diff(seir$smoothed_symptomatic_incidence)/seir$smoothed_symptomatic_incidence[1:(length(seir$smoothed_symptomatic_incidence) -1)]
  rt_smoothed = rollmean(rt_smoothed, 14, fill=NA, align='center')
  rt_smoothed = data.table::shift(rt_smoothed, mean_detection)
  
  ggplot_df = data.frame(x = c(0:(length(seir$smoothed_symptomatic_incidence)-2)), rt_smoothed = rt_smoothed, rt_actual = diff(seir$scaled_expected_incidence)/seir$scaled_expected_incidence[1:(length(seir$scaled_expected_incidence) -1)])
  
  np_clip <- function(x, a, b) {
    ifelse(x <= a,  a, ifelse(x >= b, b, x))
  }
  ggplot_df$rt_actual = np_clip(ggplot_df$rt_actual, -0.1, 0.1)
  ggplot_df$rt_smoothed = np_clip(ggplot_df$rt_smoothed, -0.1, 0.1)
  
  plot = ggplot(ggplot_df)
  plot = plot + geom_line(aes(x=x, y=rt_smoothed, color='1. Estimated r(t)'), alpha=1)
  plot = plot + geom_line(aes(x=x, y=rt_actual, color='2. Actual r(t)'), alpha=0.7)
  plot = plot + labs(x='day', y='r(t)', title='Fitted r(t) vs actual r(t) - for visualization actual values are clipped')
  plot = plot + scale_color_colorblind()
  print(plot)
  ggsave(paste('figures/rt_', toString(i), '.png'))
  

}


