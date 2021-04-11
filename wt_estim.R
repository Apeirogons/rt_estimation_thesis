#! /usr/bin/Rscript
library('ggplot2')
library('EpiEstim')
library('tidyverse')

source('ts_utils/rl_cobey.R')
source('ts_utils/filter.R')

source('ts_utils/cori_wallinga.R')

source('base_params.R')
source('ggplot_params.R')

i = 'simple_observation_blocks'

for(fairness in c('', '_fair')){
  seir = read.csv(paste('seir/', i, '.csv', sep=''))
  
  filtered = linear_filter(seir$obs_symptomatic_incidence, level=0.95)
  seir$smoothed_symptomatic_incidence = filtered[, 'fit']
  seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]#c(, NA* c(1:(length(total_delay_pdf)-1)))
  
  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0

  
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data #mean_detection
  if (fairness == ''){
  wt_symptomatic = wt_estimation(data_of_interest, generation_int, 0) %>%
    select(c('mean_t', 'Mean(R)', 'Quantile.0.025(R)', 'Quantile.0.975(R)'))
  }
  
  else if (fairness == '_fair'){
    wt_symptomatic = wt_estimation(data_of_interest, generation_int, mean_infectious) %>%
      select(c('mean_t', 'Mean(R)', 'Quantile.0.025(R)', 'Quantile.0.975(R)'))
  }

  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori = cori_estimation(data_of_interest, generation_int, -1*mean_detection)  %>%
    select(c('mean_t', 'Mean(R)', 'Quantile.0.025(R)', 'Quantile.0.975(R)'))
  
  joined = inner_join(wt_symptomatic, cori, by='mean_t')

  seir_join = seir %>%
    select(c('X', 'Rt', 'Rt_case')) %>%
    rename(mean_t = X) 


  ggplot_df = inner_join(joined, seir_join) %>%
    rename(wt=`Mean(R).x`, cori=`Mean(R).y`, X=mean_t, lwr_cori = `Quantile.0.025(R).y`, 
           upr_cori=`Quantile.0.975(R).y`, lwr_wt =`Quantile.0.025(R).x`, upr_wt=`Quantile.0.975(R).x`)



  labels = labs(x='date', y='R(t) inst.', title='Comparison of WT shifts and Cori', col='Estimation method')
  plot = create_plot(ggplot_df, c('wt', 'cori', 'Rt'), c('WT shifts', 'Cori', 'True Rt inst.'), c(0.75, 0.75, 0.75), labels, 'top_right')
 # plot = plot + geom_ribbon(data=ggplot_df, aes(x=X, ymin=lwr_cori, ymax=upr_cori), alpha=0.2, inherit.aes = FALSE, fill='orange')
  plot = plot + geom_ribbon(data=ggplot_df, aes(x=X, ymin=lwr_wt, ymax=upr_wt), alpha=0.2, inherit.aes = FALSE, fill='black')
  plot = plot + xlim(0, 400)
  plot = plot + ylim(c(0,3))
  print(plot)
  
  ggsave(paste('figures/wt_comparison_', toString(i), fairness, '.png', sep=''), width=width, height=height)

}








