#! /usr/bin/Rscript
library('deSolve')

library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('data.table')
library('ggthemes')

library('ggplot2')
source('ts_utils/seir.R')


# Real-world incubation period
m = dislnorm$new()
m$setPars(c(1.63, 0.5))
m$setXmin(0)

indices = c(0:50)
incubation_pdf = dist_pdf(m, q=indices)

# SEIR incubation period
gamma = 1/4.02 #1/10.02
MU = 1/5.72 #1/10.72

mean_gamma = 1/gamma
sd_gamma = sqrt((1/gamma)**2)
seir_incubation = discr_si(indices, mean_gamma, sd_gamma)

incubation_df = data.frame(d=indices, real_world=incubation_pdf, seir=seir_incubation)

write.csv(incubation_df, paste(paste('incubation_period', '.csv', sep='')))



file_path = 'figures_simulation'
dir.create(file.path(file_path), showWarnings = FALSE)

t = c(0:501)
init_conditions= c(S=10000000, E=1, I=0, R=0)

b = function(t){
  if (t< 150){
    return(1.5*MU)
  }
  else if (t < 200){
    return(1.2*MU)
  }
  else if (t < 300){
    return(0.99*MU)
  }
  else if (t < 400){
    return(0.8*MU)
  }
  else{
    return (1.1*MU)
  }
}


seir_outputs = simulate_seir(t, init_conditions, b, gamma, MU, randomize_params=c(alpha=40, beta=4))
write.csv(seir_outputs, 'data/seir.csv')
#hist(rbbinom(100000, 1000000, alpha=40, beta=5))

ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=S, color='S'), )+ geom_line(aes(x=t, y=E, color='E')) + geom_line(aes(x=t, y=I, color='I')) + geom_line(aes(x=t, y=R, color='R') ) +theme_bw()  + labs(title='SEIR model outputs', x='time (days)', y = 'population')
ggsave(paste(file_path, '/simulation.png', sep=''))
ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=scaled_true_incidence, color='scaled true incidence'))+ geom_line(aes(x=t, y=scaled_symptomatic_incidence, color='scaled symptomatic incidence')) + geom_line(aes(x=t, y=noisy_symptomatic_incidence, color='noisy symptomatic incidence')) + theme_bw()  + labs(title='SEIR model outputs', x='time (days)', y = 'population')
ggsave(paste(file_path, '/incidence.png', sep=''))
ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=Rt, color='Instantaneous Rt'))+ geom_line(aes(x=t, y=Rt_case, color='Cohort Rt')) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt')
ggsave(paste(file_path, '/true_rt.png', sep=''))


