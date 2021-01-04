#! /usr/bin/Rscript
library('reticulate')
library('ggplot2')
library('EpiEstim')
library('ggthemes')
source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
library(data.table)


gm = 1/4.02
mu = 1/5.72
use_condaenv('MachineLearning')
theme_set(theme_bw())

source_python('ts_utils/deconvolution.py')
dist_to_infectious = read.csv('incubation_period.csv')
seir = read.csv('data/seir.csv')



# Wavelet LP filter
smoothed_symptomatic_incidence = wavelet_lp_filter(seir$noisy_symptomatic_incidence, 5, 'db2')
seir$smoothed_symptomatic_incidence = smoothed_symptomatic_incidence
plot = ggplot(seir) + geom_line(aes(x=X, y=smoothed_symptomatic_incidence, color='smoothed'), alpha=0.75) + geom_line(aes(x=X, y=noisy_symptomatic_incidence, color='noisy'), alpha=0.75) + scale_color_colorblind()
plot = plot  + geom_line(aes(x=X, y=scaled_symptomatic_incidence, color='true'), alpha=0.75)
print(plot)
ggsave('figures_simulation/smoothing.png')

# Code to extrapolate the last (20) observations for the purposes of better deconvolution at the end of the timeseries
extrapolate = function(seir, target, n_targets=20, n_extend=50){
  data_of_interest = seir[[target]]
  data_end = tail(seir, n_targets)
  fm <- as.formula(paste(target, " ~ poly(X, 1)"))
  
  extrapolation_model = lm(fm, data=data_end)
  
  last_t = data_end$X[length(data_end$X)]
  extrapolated = data.frame(X=c(last_t:(last_t+(n_extend-1))))
  print( predict(extrapolation_model, extrapolated))
  extrapolated$interest = predict(extrapolation_model, extrapolated)

  data_of_interest = append(data_of_interest, extrapolated$interest)
  Xs = append(seir$X, extrapolated$X)
  
  data_of_interest[data_of_interest < 0] = 0
  data_of_interest[is.na(data_of_interest)] = 0
  return(list(Xs=Xs, data=c(data_of_interest)))}

# Deconvolution
obj = extrapolate(seir, 'noisy_symptomatic_incidence')
Xs = obj$Xs
data_of_interest = obj$data
rls = get_RL(data_of_interest, Xs, dist_to_infectious$seir, max_iter=200, regularize=0.01, stopping_n=0.25)
rls=rls[rls['time'] >=0,]
seir$rl_deconv = rls$RL_result[1:length(seir$X)]
seir$rl_deconv[is.na(seir$rl_deconv)] = 0
plot = ggplot(seir)  + geom_line(aes(x=X, y=scaled_true_incidence, color='true incidence')) + scale_color_colorblind()
#+ geom_line(aes(x=X, y=rl_deconv, color='deconvolved incidence'))
#seir$smoothed_rl = wavelet_lp_filter(seir$rl_deconv, 4, 'sym3')
#seir$shifted_symptomatic =data.table::shift(seir$noisy_symptomatic_incidence, -round(1/gm))
plot = plot + geom_line(data=seir, aes(x=X, y=rl_deconv, color='deconv'))
#plot = plot + geom_line(aes(x=X, y=shifted_symptomatic, color='shifted symptomatic'))
print(plot)
ggsave('figures_simulation/deconvolution.png')



obj = generation_seir(gm, mu)
mean_generation = obj['mean']
sd_generation = obj['sd']

obj = extrapolate(seir, 'noisy_symptomatic_incidence')
data_of_interest = obj$data
cori = cori_estimation(data_of_interest, mean_generation, sd_generation) 
cori$`Mean(R)` = data.table::shift(cori$`Mean(R)`, -round(1/gm))
plot = ggplot(data=cori) + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Cori-shifts'))+ labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,3)) + scale_color_colorblind()
plot = plot + geom_line(data=seir, aes(x=X, y=Rt, color='True Rt'))
print(plot)


obj = extrapolate(seir, 'rl_deconv')
data_of_interest = obj$data
cori = cori_estimation(data_of_interest, mean_generation, sd_generation) 
plot = plot+ geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Cori-deconv'))
print(plot)

obj = extrapolate(seir, 'noisy_symptomatic_incidence')#noisy_symptomatic_incidence rl_deconv smoothed_rl_deconv
data_of_interest = obj$data
wt = wt_estimation(data_of_interest, mean_generation, sd_generation)
wt$r_shifted = data.table::shift(wt$`Mean(R)`, mean_generation)

plot = plot +  geom_line(data=wt, aes(x=mean_t, y=r_shifted, color='WT-shifts')) 

print(plot)


# Interesting call to do deconv instead of shifts but it's not that good
si = discr_si(c(0:40), mean_generation, sd_generation)

rls = get_RL(wt$`Mean(R)`, wt$mean_t, si, max_iter=200, regularize=0.01, stopping_n=0.01)
rls=rls[rls['time'] >=0,]

wt$deconv_R = rls$RL_result[1:length(wt$`Mean(R)`)]
wt$deconv_R = data.table::shift(wt$deconv_R, -(25)) #I don't know what the actual shifting level should be, but this is the number of NAs at the end of the sequence
plot = plot + geom_line(data=wt, aes(x=mean_t, y=deconv_R, color='WT, deconv on R'))
ggsave('figures_simulation/rt.png')


#seir$rl_deconv[is.na(seir$rl_deconv)] = 0

#wt$deconv_R = 
#output = wt$deconv_rl[!is.na(wt$deconv_rl)]
#wt$deconv_rl = append(output, replicate(length(wt$deconv_rl) - length(output), NA)
#ggplot(data=wt)+ geom_line(data=wt, aes(x=mean_t, y=`Mean(R)`, color='WT-normal')) 
#plot = plot + geom_line(data=seir, aes(x=X, y=Rt_case, color='Rt case'))+ geom_line(data=seir, aes(x=X, y=Rt, color='Rt inst'))

#rm(list=ls())