#! /usr/bin/Rscript
#library('reticulate')
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library('extraDistr')
library('poweRlaw')
library('zoo')
library('tidyverse')

source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')

#source_python('ts_utils/deconvolution.py')
source('base_params.R')
source('ggplot_params.R')

for (i in c('process_1', 'deterministic')){
  seir = read.csv(paste('seir/', i, '.csv', sep=''))
  
  seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  
  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0
  
  
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  wt_symptomatic = wt_estimation(data_of_interest, generation_int, mean_detection) %>%
    select(c('mean_t', 'Mean(R)'))

  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int, -1*mean_detection)  %>%
    select(c('mean_t', 'Mean(R)'))
  
  joined = inner_join(wt_symptomatic, cori, by='mean_t')
  seir_join = seir %>%
    select(c('X', 'Rt', 'Rt_case')) %>%
    rename(mean_t = X) 

  ggplot_df = inner_join(joined, seir_join) %>%
    rename(wt=`Mean(R).x`, cori=`Mean(R).y`, X=mean_t)  %>%
    mutate(wt_actual = shift(wt, -1*mean_detection)) 

  
  labels = labs(x='date', y='R(t) inst.', title='Comparison of WT shifts and Cori', col='Estimation method')
  plot = create_plot(ggplot_df, c('wt', 'cori', 'Rt'), c('WT shifts', 'Cori', 'True Rt inst.'), c(0.75, 0.75, 0.75), labels, 'top_right')
  plot = plot + xlim(0, 400)
  plot = plot + ylim(c(0,3))
  print(plot)
  
  ggsave(paste('figures/wt_comparison_', toString(i), '.png', sep=''), width=10.4, height=6.15)
  
  labels = labs(x='date', y='R(t)', col='Estimation method')
  plot = create_plot(ggplot_df, c('wt_actual', 'Rt', 'Rt_case'), c('WT', 'Rt inst.', 'Rt case'), c(0.75, 0.75, 0.75), labels, 'top_right')
  plot = plot + ylim(c(0,3)) 
  plot = plot + xlim(0, 300)
  print(plot)
  
  ggsave(paste('figures/wt_vs_true_', toString(i), '.png', sep=''), width=10.4, height=6.15)
}








