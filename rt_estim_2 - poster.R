#! /usr/bin/Rscript
library('reticulate')
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library('extraDistr')
library('poweRlaw')
library('zoo')

# r(t) defined on the left side: that is, the change of incidence from one day to next (not from day before to that day)

source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')
source('ts_utils/filter.R')

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



L = length(seir$scaled_expected_incidence)
rt_actual = diff(seir$scaled_expected_incidence)/seir$scaled_expected_incidence[1:(L - 1)]
rt_actual = c(rt_actual, NA) # append NA at end of sequence as it is not defined
rt_actual[rt_actual == Inf] = NA
rt_actual[rt_actual == -Inf] = NA
rt_actual = np_clip(rt_actual, -0.1, 0.1)

rt_smoothed_normal = rt_estimation(seir$smoothed_symptomatic_incidence, seir$low_smoothed, seir$high_smoothed, level=0.95, n_resample=20, n=7, shift_amt=-1*mean_detection) #, shift_amt=-1*mean_detection
ggplot_df = data.frame(X = seir$X, rt_actual=rt_actual, rt_smoothed_normal=np_clip(rt_smoothed_normal$mean, -0.1, 0.1), rt_lower = np_clip(rt_smoothed_normal$lower, -0.1, 0.1), rt_upper = np_clip(rt_smoothed_normal$upper, -0.1, 0.1))


labels = labs(x='day', y='r(t) (1/day)', title='r(t) estimation - 7-day filter', col='') #, 'rt_smoothed_normal', 'Estimated 7-day smoothing'
plot = create_plot(ggplot_df, c('rt_smoothed_normal', 'rt_actual'), c('Estimated', 'Actual'), c(0.75, 0.75, 0.75), labels, 'bottom_right')

plot = plot + ylim(c(-0.1, 0.1))

plot = plot + geom_ribbon(data=ggplot_df, aes(x=X, ymin=rt_lower, ymax=rt_upper), alpha=0.3, inherit.aes = FALSE)
print(plot)
ggsave(paste('figures/rt_7_', toString(i), '.png', sep=''), width=width, height=height)


#####################################################################################################################3

rt_smoothed_normal = rt_estimation(seir$smoothed_symptomatic_incidence, seir$low_smoothed, seir$high_smoothed, level=0.95, n_resample=20, n=15, shift_amt=-1*mean_detection) #, shift_amt=-1*mean_detection
ggplot_df = data.frame(X = seir$X, rt_actual=rt_actual, rt_smoothed_normal=np_clip(rt_smoothed_normal$mean, -0.1, 0.1), rt_lower = np_clip(rt_smoothed_normal$lower, -0.1, 0.1), rt_upper = np_clip(rt_smoothed_normal$upper, -0.1, 0.1))


labels = labs(x='day', y='r(t) (1/day)', title='r(t) estimation - 15-day filter', col='') #, 'rt_smoothed_normal', 'Estimated 7-day smoothing'
plot = create_plot(ggplot_df, c('rt_smoothed_normal', 'rt_actual'), c('Estimated', 'Actual'), c(0.75, 0.75, 0.75), labels, 'bottom_right')

plot = plot + ylim(c(-0.1, 0.1))

plot = plot + geom_ribbon(data=ggplot_df, aes(x=X, ymin=rt_lower, ymax=rt_upper), alpha=0.3, inherit.aes = FALSE)
print(plot)
ggsave(paste('figures/rt_15_', toString(i), '.png', sep=''), width=width, height=height)
