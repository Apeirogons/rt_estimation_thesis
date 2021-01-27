#! /usr/bin/Rscript
library('reticulate')
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library(data.table)
library('extraDistr')
library('poweRlaw')


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

dir.create('smoothing_imgs', showWarnings = FALSE)
dir.create('estim_imgs', showWarnings=FALSE)


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
ggsave(paste('smoothing_imgs/7day_', toString(i), '.png'))


#
z = seir$obs_symptomatic_incidence #seir$smoothed_symptomatic_incidence[4:(length(seir$smoothed_symptomatic_incidence) -4)]
waveletted = wavelet_lp_filter(z, 3, 'db4') 

#smoothed_symptomatic_incidence = append(rep(NA, 3), waveletted)
#smoothed_symptomatic_incidence = append(smoothed_symptomatic_incidence, rep(NA, 3))
smoothed_symptomatic_incidence=waveletted
seir$smoothed_symptomatic_incidence = smoothed_symptomatic_incidence
seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
plot = ggplot(seir) 
plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='3-smoothed symptomatic'), alpha=1) 
plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
plot = plot + geom_line(aes(x=X, y=scaled_expected_incidence, color='4-expected true incidence'), alpha=0.1)
plot = plot + geom_line(aes(x=X, y=convolved_expected, color='1-true incidence forward-convolved by weekly mean detection kernel'), alpha=1)
plot = plot + scale_color_colorblind()
print(plot)
ggsave(paste('smoothing_imgs/', toString(i), '.png'))


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

ggsave(paste('estim_imgs/', toString(i), '.png'))


rt_smoothed = data.table::shift(diff(seir$smoothed_symptomatic_incidence)/seir$smoothed_symptomatic_incidence[1:(length(seir$smoothed_symptomatic_incidence) -1)], mean_detection)
ggplot_df = data.frame(x = c(0:(length(seir$smoothed_symptomatic_incidence)-2)), rt_smoothed = rt_smoothed, rt_actual = diff(seir$scaled_expected_incidence)/seir$scaled_expected_incidence[1:(length(seir$scaled_expected_incidence) -1)])
plot = ggplot(ggplot_df)

plot = plot + geom_line(aes(x=x, y=rt_smoothed, color='rt_smoothed'))
plot = plot + geom_line(aes(x=x, y=rt_actual, color='rt_actual'))
plot = plot + ylim(-0.1, 0.1)
print(plot)
ggsave('rt.png')




for( i in c(2:20)){
  seir = read.csv(paste('seir/', toString(i),  '.csv'))
  
  seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  plot = ggplot(seir) 
  plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='3-smoothed symptomatic'), alpha=1) 
  plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
  plot = plot + geom_line(aes(x=X, y=scaled_expected_incidence, color='4-expected true incidence'), alpha=0.1)
  plot = plot + geom_line(aes(x=X, y=convolved_expected, color='1-true incidence forward-convolved by weekly mean detection kernel'), alpha=1)
  plot = plot + scale_color_colorblind()
  print(plot)
  ggsave(paste('smoothing_imgs/7day_', toString(i), '.png'))
  
  
  
  z = seir$smoothed_symptomatic_incidence[4:(length(seir$smoothed_symptomatic_incidence) -4)]
  waveletted = wavelet_lp_filter(z, 3, 'db4') 
  smoothed_symptomatic_incidence = append(rep(NA, 3), waveletted)
  smoothed_symptomatic_incidence = append(smoothed_symptomatic_incidence, rep(NA, 3))
  
  seir$smoothed_symptomatic_incidence = smoothed_symptomatic_incidence
  
  #smoothed_symptomatic_incidence = wavelet_lp_filter(seir$obs_symptomatic_incidence, 3, 'db4') 
  #seir$smoothed_symptomatic_incidence = smoothed_symptomatic_incidence
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  plot = ggplot(seir) 
  plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='3-smoothed symptomatic'), alpha=1) 
  plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
  plot = plot + geom_line(aes(x=X, y=scaled_expected_incidence, color='4-expected true incidence'), alpha=0.1)
  plot = plot + geom_line(aes(x=X, y=convolved_expected, color='1-true incidence forward-convolved by weekly mean detection kernel'), alpha=1)
  plot = plot + scale_color_colorblind()
  print(plot)
  ggsave(paste('smoothing_imgs/', toString(i), '.png'))
  
  
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
  
  ggsave(paste('estim_imgs/', toString(i), '.png'))
}

#obj = extrapolate(seir, 'obs_symptomatic_incidence')
#data_of_interest = obj$data
#wt = wt_estimation(data_of_interest, generation_int)

#wt$r_shifted = data.table::shift(wt$`Mean(R)`, mean_generation)
#plot = plot +  geom_line(data=wt, aes(x=mean_t, y=r_shifted, color='WT Shifts - symptomatic'), alpha=0.5) 
#print(plot)
#rls = get_RL(wt$`Mean(R)`, wt$mean_t, generation_int, max_iter=200, regularize=0.01, stopping_n=0.5)
#rls=rls[rls['time'] >=0,]
#wt$deconv_R = rls$RL_result[1:length(wt$`Mean(R)`)]
#wt$deconv_R = data.table::shift(wt$deconv_R, 0) #I don't know what the actual shifting level should be, but this is the number of NAs at the end of the sequence
#print(wt$deconv_R)
#plot = plot + geom_line(data=wt, aes(x=mean_t, y=deconv_R, color='WT, deconv on R'))
#print(plot)


# Deconvolution
obj = extrapolate(seir, 'smoothed_symptomatic_incidence')
Xs = obj$Xs
data_of_interest = obj$data
rls = get_RL(data_of_interest, Xs, detection_pdf, max_iter=10, regularize=0.01, stopping_n=0.55)
rls=rls[rls['time'] >=0,]
seir$rl_deconv = rls$RL_result[1:length(seir$X)]
seir$rl_deconv[is.na(seir$rl_deconv)] = 0
seir$shifted_smoothed_symptomatic_incidence = data.table::shift(seir$smoothed_symptomatic_incidence, -1*mean_detection)
plot = ggplot(seir)  + geom_line(aes(x=X, y=scaled_expected_incidence, color='scaled expected incidence')) + scale_color_colorblind()
plot = plot + geom_line(data=seir, aes(x=X, y=rl_deconv, color='deconvolved smoothed symptomatic incidence'))
plot = plot + geom_line(data=seir, aes(x=X, y=shifted_smoothed_symptomatic_incidence, color='shifted smoothed symptomatic incidence'))
print(plot)
ggsave('deconvolution.png')





#rm(list=ls())