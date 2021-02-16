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

theme_set(theme_bw())
source_python('ts_utils/deconvolution.py')
source('base_params.R')


for (i in c('process_1', 'deterministic')){
  seir = read.csv(paste('seir/', i, '.csv', sep=''))
  
  seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  
  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0
  
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  wt_symptomatic = wt_estimation(data_of_interest, generation_int) 
  wt_symptomatic$`Mean(R)` = data.table::shift(wt_symptomatic$`Mean(R)`, mean_detection) #-1*mean_detection)
  
  plot = ggplot(wt_symptomatic)
  plot =  plot + geom_line(data=wt_symptomatic, aes(x=mean_t, y=`Mean(R)`, color='1. WT Shifts - symptomatic'), alpha=1)
  
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int) 
  cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
  plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='2. Cori - symptomatic'), alpha=0.5)
  
  plot = plot + xlim(0, 400)
  plot = plot + geom_line(data=seir, aes(x=X, y=Rt, color='3. True Inst. Rt'), alpha=0.5)
  plot = plot + ylim(c(0,3)) + scale_color_colorblind()
  print(plot)
  ggsave(paste('figures/wt_comparison_', toString(i), '.png', sep=''), width=10.4, height=6.15)
  
  
  
  wt_symptomatic$`Mean(R)` = data.table::shift(wt_symptomatic$`Mean(R)`, -1*mean_detection)
  
  plot = ggplot(wt_symptomatic)
  plot = plot + geom_line(data=wt_symptomatic, aes(x=mean_t, y=`Mean(R)`, color='WT - symptomatic'))
  plot = plot + geom_line(data=seir, aes(x=X, y=Rt_case, color='True Case Rt'))
  plot = plot + geom_line(data=seir, aes(x=X, y=Rt, color='True Inst. Rt'), alpha=0.5)
  plot = plot + ylim(c(0,3)) + scale_color_colorblind()
  plot = plot + xlim(0, 300)
  print(plot)
  ggsave(paste('figures/wt_vs_true_', toString(i), '.png', sep=''), width=10.4, height=6.15)
}








