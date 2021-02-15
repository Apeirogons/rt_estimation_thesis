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



i = 'process_1'
seir = read.csv(paste('seir/process_1.csv'))

seir$smoothed_symptomatic_incidence = n_day_smoother(seir$obs_symptomatic_incidence)
rl = get_RL(seir$smoothed_symptomatic_incidence[!is.na(seir$smoothed_symptomatic_incidence)], seir$X[!is.na(seir$smoothed_symptomatic_incidence)], detection_pdf,stopping_n = 0.5, regularize=0.01, max_iter=100)
rl = c(rl$RL_result[rl$time>0], rep(NA, length(seir$X) - length(rl$RL_result[rl$time>0])))
seir$rl = rl

seir$convolved_expected = convolve(seir$scaled_true_incidence, rev(detection_pdf), type='open')[1:402]

seir$shifted_symptomatic = data.table::shift(seir$smoothed_symptomatic_incidence, -1*mean_detection)
plot = ggplot(seir) 
#plot = plot + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='3-smoothed symptomatic'), alpha=1) 
#plot = plot + geom_line(aes(x=X, y=obs_symptomatic_incidence, color='2-observed symptomatic'), alpha=0.25) 
#plot = plot + geom_line(aes(x=X, y=convolved_expected, color='1-true incidence forward-convolved by weekly mean detection kernel'), alpha=1)
plot = plot + geom_line(aes(x=X, y=rl, color='2-deconvolved'), alpha=1) 
plot = plot + geom_line(aes(x=X, y=shifted_symptomatic, color='3-shifted symptomatic'), alpha=0.75) 
plot = plot + geom_line(aes(x=X, y=scaled_expected_incidence, color='4-expected true incidence'), alpha=0.75)
plot = plot + labs(x='time', y='incidence', title='Deconvolution vs shift')
plot = plot + scale_color_colorblind()
print(plot)
ggsave(paste('figures/deconv_', toString(i), '.png', sep=''))



stopifnot(generation_int[1] < 1e-5)
generation_int[1] = 0
obj = extrapolate(seir, 'expected_incidence')
data_of_interest = obj$data
cori = cori_estimation(data_of_interest, generation_int) 
plot = ggplot(data=cori) + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='3. Cori - expected'))+ labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0, 2.5)) + scale_color_colorblind()
plot = plot + geom_line(data=seir, aes(x=X, y=Rt, color='True Rt'))


obj = extrapolate(seir, 'obs_symptomatic_incidence')
data_of_interest = obj$data
cori = cori_estimation(data_of_interest, generation_int) 
cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='2. Cori - symptomatic'), alpha=0.5)

obj = extrapolate(seir, 'rl')
data_of_interest = obj$data
cori = cori_estimation(data_of_interest, generation_int) 
#cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -1*mean_detection)
plot =  plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='1. Cori - deconv'), alpha=0.5)
print(plot)

ggsave(paste('figures/estim_deconv_', toString(i), '.png', sep=''))

















