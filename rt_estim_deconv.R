#! /usr/bin/Rscript
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library('extraDistr')
library('poweRlaw')
library('zoo')

# r(t) defined on the left side: that is, the change of incidence from one day to next (not from day before to that day)

source('ts_utils/rt.R')
source('ts_utils/process_utils.R')
source('ts_utils/filter.R')
source('ts_utils/rl_cobey.R')

source('base_params.R')
source('ggplot_params.R')


rt_estimation = rt_estimation_ci

np_clip <- function(x, a, b) {
  ifelse(x <= a,  a, ifelse(x >= b, b, x))
}


desired = c('simple_observation_1')
i = desired[1]
seir = read.csv(paste('seir/', i,'.csv', sep=''))

filtered = linear_filter(seir$obs_symptomatic_incidence, level=0.95)
seir$smoothed_symptomatic_incidence = filtered[, 'fit']
seir$low_smoothed = filtered[,'lwr']
seir$high_smoothed = filtered[,'upr']
seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402] #c(, NA* c(1:(length(total_delay_pdf)-1)))

seir$shifted_smoothed = data.table::shift(seir$smoothed_symptomatic_incidence, -1*mean_detection)
rl = get_RL(seir$smoothed_symptomatic_incidence, c(1:length(seir$smoothed_symptomatic_incidence)), detection_pdf, stopping_n = 0.5, regularize=0.001, right_censor=TRUE)
rl = rl[rl$time >= 1, ]

seir$rl = rl$RL_result

labels = labs(title='Comparison of deconvolution and shifting', x='day', y='incidence', col='')
plot = create_plot(seir, c('rl', 'scaled_expected_incidence', 'shifted_smoothed'), c('Deconvolved', 'True incidence of infection', 'Shifted observed incidence'), c(0.75, 0.5, 0.5), labels, 'bottom_right')
print(plot)
ggsave(paste('figures/deconv_vs_shift', toString(i), '.png', sep=''), width=width, height=height)


###############################################################################################################################################

for (n in c(7, 15)){
  L = length(seir$scaled_expected_incidence)
  rt_actual = c(diff(log(seir$scaled_expected_incidence))) #diff(seir$scaled_expected_incidence)/seir$scaled_expected_incidence[1:(L - 1)]
  rt_actual = c(rt_actual, NA) # append NA at end of sequence as it is not defined
  rt_actual[rt_actual == Inf] = NA
  rt_actual[rt_actual == -Inf] = NA
  rt_actual = np_clip(rt_actual, -0.1, 0.1)
  
  rt_smoothed_normal = rt_estimation(seir$smoothed_symptomatic_incidence, seir$low_smoothed, seir$high_smoothed, level=0.95, n_resample=20, n=15, shift_amt=-1*mean_detection) #, shift_amt=-1*mean_detection
  rt_smoothed_rl = rt_estimation(seir$rl, seir$low_smoothed, seir$high_smoothed, level=0.95, n_resample=20, n=15, shift_amt=0)
  
  
  ggplot_df = data.frame(X = seir$X, rt_actual=rt_actual, rt_smoothed_normal=np_clip(rt_smoothed_normal$mean, -0.1, 0.1), rt_smoothed_rl = np_clip(rt_smoothed_rl$mean, -0.1, 0.1))
  
  
  labels = labs(x='day', y='r(t) (1/day)', title=paste('r(t) estimation -', toString(n), '-day filter', sep=''), col='') #, 'rt_smoothed_normal', 'Estimated 7-day smoothing'
  plot = create_plot(ggplot_df, c('rt_smoothed_normal', 'rt_smoothed_rl', 'rt_actual'), c('Estimated with shifting', 'Estimated with deconvolution', 'Actual'), c(0.75, 0.75, 0.75), labels, 'bottom_right')
  
  plot = plot + ylim(c(-0.1, 0.1))
  in_ci = Reduce('&', list((ggplot_df$rt_actual >= ggplot_df$rt_lower), (ggplot_df$rt_actual <= ggplot_df$rt_upper)))
  in_ci = in_ci[!is.na(in_ci)]
  print(sum(in_ci)/length(in_ci))
  
  print(plot)
  ggsave(paste('figures/rt_', toString(n), '_deconv', toString(i), '.png', sep=''), width=width, height=height)
}





