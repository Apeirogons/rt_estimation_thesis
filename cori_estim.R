#! /usr/bin/Rscript
library('ggplot2')
library('EpiEstim')
library('ggthemes')

source('ts_utils/filter.R')
source('ts_utils/rl_cobey.R')
source('ts_utils/cori_wallinga.R')

source('base_params.R')
source('ggplot_params.R')

desired = c('simple_observation_1', 'simple_observation_blocks')


for(i in desired){
  print(i)
  seir = read.csv(paste('seir/', i,'.csv', sep=''))
  
  filtered = linear_filter(seir$obs_symptomatic_incidence, level=0.95)
  seir$smoothed_symptomatic_incidence = filtered[, 'fit']
  
  stopifnot(generation_int[1] < 1e-5)
  generation_int[1] = 0
  obj = extrapolate(seir, 'expected_incidence')
  data_of_interest = obj$data
  cori_expected = cori_estimation(data_of_interest, generation_int) 
  
  obj = extrapolate(seir, 'smoothed_symptomatic_incidence')
  data_of_interest = obj$data
  cori_smoothed = cori_estimation(data_of_interest, generation_int, -1*mean_detection) 
  
  obj = extrapolate(seir, 'obs_symptomatic_incidence')
  data_of_interest = obj$data
  cori_obs = cori_estimation(data_of_interest, generation_int, -1*mean_detection) 

  ggplot_df = data.frame(X=cori_smoothed$mean_t, smoothed=cori_smoothed$`Mean(R)`, obs = cori_obs$`Mean(R)`, expected = cori_expected$`Mean(R)`)
  ggplot_df$lwr = cori_obs$`Quantile.0.025(R)`
  ggplot_df$upr = cori_obs$`Quantile.0.975(R)`
  
  true_rt = seir$Rt[is.element(seir$t, ggplot_df$X)]
  ggplot_df$true = pad(true_rt, ggplot_df$X)
  labels =  labs(x='date', y='R(t)', title=paste('Cori R(t) estimation'), col='')

  plot = create_plot(ggplot_df, c('true', 'smoothed', 'obs', 'expected'),  c('True R(t)', 'Cori applied to smoothed observations', 'Cori applied to unsmoothed observations', 'Cori applied to true incidence of infection'), c(0.75, 0.5, 0.5, 0.5), labels, 'top_right')
  plot = plot + geom_ribbon(data=ggplot_df, aes(x=X, ymin=lwr, ymax=upr), alpha=0.1, inherit.aes = FALSE)
  plot = plot + ylim(0, 3)
  plot = plot + xlim(0, seir$X[length(seir$X)])
  print(plot)
  ggsave(paste('figures/Rt_estim_', toString(i), '.png', sep=''), width=width, height=height)

  
}



