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
source('base_params.R')
source('ggplot_params.R')


for (i in c('Germany', 'South Korea', 'Italy')){ #
  seir = read.csv(paste('data/', i, '.csv', sep=''))
  seir$date = as.Date(seir$date)
  seir$obs_symptomatic_incidence = seir$new_cases_per_million
  
  seir$nday_smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  seir$smoothed_symptomatic_incidence = seir$nday_smoothed_symptomatic_incidence
 # seir$smoothed_symptomatic_incidence =c(NA, NA, NA, wavelet_filter(seir$nday_smoothed_symptomatic_incidence[!is.na(seir$nday_smoothed_symptomatic_incidence)], 'db4', cutoff=3000), NA, NA, NA)
  
  seir$X = c(0:(length(seir$date)-1))

  plot = ggplot(seir) 
 # plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='nday+wavelet smoothed symptomatic'), alpha=1) 
  plot = plot + geom_line(aes(x=date, y=nday_smoothed_symptomatic_incidence, color='7day smoothed symptomatic'), alpha=1) 
  plot = plot + geom_line(aes(x=date, y=obs_symptomatic_incidence, color='observed symptomatic'), alpha=0.25) 
  plot = plot + scale_color_colorblind()
#  plot = plot + scale_y_log10()
#  plot = plot + xlim(c(20, 70))
  plot = plot + labs(x='date', y='incidence', title=i)
  print(plot)
  
  ggsave(paste('figures/smoothing_', toString(i), '.png', sep=''), width=10.4, height=6.15)
  
  
  
  seir$obs_symptomatic_incidence = seir$new_cases_per_million
  
  seir$nday_smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  seir$smoothed_symptomatic_incidence = seir$nday_smoothed_symptomatic_incidence
  rl = get_RL(seir$smoothed_symptomatic_incidence[!is.na(seir$smoothed_symptomatic_incidence)], seir$X[!is.na(seir$smoothed_symptomatic_incidence)], detection_pdf,stopping_n = 0.5, regularize=0.01, max_iter=50)
  rl = c(rl$RL_result[rl$time>0], rep(NA, length(seir$X) - length(rl$RL_result[rl$time>0])))
  seir$rl = rl
  
  seir$X = c(0:(length(seir$date)-1))
  plot = ggplot(seir) 

  plot = plot + geom_line(aes(x=date, y=nday_smoothed_symptomatic_incidence, color='7day smoothed symptomatic'), alpha=0.25) 
  plot = plot + geom_line(aes(x=date, y=obs_symptomatic_incidence, color='observed symptomatic'), alpha=0.25) 
  plot = plot + geom_line(aes(x=date, y=rl, color='RL deconvolution'), alpha=1)
  plot = plot + scale_color_colorblind()
  plot = plot + labs(x='date', y='incidence', title=i)
  print(plot)
  
  ggsave(paste('figures/deconv_', toString(i), '.png', sep=''), width=10.4, height=6.15)
  
  
  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0
  obj = extrapolate(seir, 'smoothed_symptomatic_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
  
  plot = ggplot(cori) + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='1. Cori - smoothed symptomatic'), alpha=0.5)
  
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
  plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='2. Cori - symptomatic'), alpha=1)

  obj = extrapolate(seir, 'rl')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='3. Cori - RL deconv.'), alpha=1)
  
  plot = plot + ylim(0, 3.5)
  plot = plot + labs(title=paste('Cori -', i))
  print(plot)
  
  ggsave(paste('figures/estim_', toString(i), '.png', sep=''), width=10.4, height=6.15)
  
  
  np_clip <- function(x, a, b) {
    ifelse(x <= a,  a, ifelse(x >= b, b, x))
  }
  rt_smoothed = diff(log(seir$smoothed_symptomatic_incidence))

  rt_smoothed = rollapply(rt_smoothed, 7, mean, fill=NA, align='center')
  rt_smoothed = data.table::shift(rt_smoothed, -1*mean_detection)

  rt_deconv_smoothed = diff(log(seir$rl))

  rt_deconv_smoothed = rollapply(rt_deconv_smoothed, 7, mean, fill=NA, align='center')
#  rt_deconv_smoothed = data.table::shift(rt_deconv_smoothed, mean_detection)
  
  ggplot_df = data.frame(x = seir$date[1:(length(seir$smoothed_symptomatic_incidence)-1)], rt_smoothed = rt_smoothed, rt_deconv_smoothed=rt_deconv_smoothed)
  
  plot = ggplot(ggplot_df)
  plot = plot + geom_line(aes(x=x, y=rt_smoothed, color='1. r(t)-shifted'), alpha=1)
  plot = plot + geom_line(aes(x=x, y=rt_deconv_smoothed, color='2. r(t)-deconv'), alpha=1)
  plot = plot + labs(x='day', y='r(t)', title='Fitted r(t)')
  plot = plot + scale_color_colorblind()
  plot = plot + ylim(c(-0.3, 0.3))
  print(plot)
  ggsave(paste('figures/rt_', toString(i), '.png', sep=''), width=10.4, height=6.15)
}
#rollapply doesn't properly handle NA!!!!
#seir$new_cases_per_million
#seir$smoothed_symptomatic_incidence
#diff(log(seir$smoothed_symptomatic_incidence))
#rollapply(diff(log(seir$smoothed_symptomatic_incidence)), 7, mean, fill=NA, align='center')
