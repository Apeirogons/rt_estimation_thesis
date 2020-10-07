#! /usr/bin/Rscript
library('deSolve')
library('ggplot2')
library('EpiEstim')
source('cobey_ml_deconvolution.R')

seir = function(t, conditions, parms){
  beta = b(t)
  S = conditions['S']
  E = conditions['E']
  I = conditions['I']
  R = conditions['R']
  gamma = parms['gamma']
  mu = parms['mu']
  
  N = S+ E+I +R
  dSdt = -beta * S/N * I
  dEdt = beta * I *  S/N - gamma*E
  dIdt = gamma*E - mu * I
  dRdt = mu*I


  return (list(c(dSdt, dEdt, dIdt, dRdt)))}

simulate_seir = function(t, conditions, b, gamma, mu){
  beta_t = c()
  for (t0 in t){
    beta_t = append(beta_t, b(t0))
  }
  N_t = sum(conditions)
  seir_outputs = ode(y=conditions, times=t, func=seir, parms = c(gamma=gamma, mu=mu))
  seir_outputs = as.data.frame(seir_outputs)
  
  seir_outputs$true_incidence = beta_t * seir_outputs$I *  seir_outputs$S/N_t
  seir_outputs$symptomatic_incidence = gamma* seir_outputs$E
  
  seir_outputs$Rt = beta_t / mu * seir_outputs$S/N_t
  seir_outputs$beta = beta_t
  
  # EpiEstim::discr_si computes descrete GI/SI for gamma-distribution, but exponential distribution is a special case of gamma
  # with shape = 1, rate = L
  # mean of Gamma: shape*scale
  # sd of Gamma: sqrt(shape*scale**2)
  mean_gamma = 1/gamma
  sd_gamma = sqrt((1/gamma)**2)
  dist_to_infectious = discr_si(c(0:25), mean_gamma, sd_gamma)

  Rt_case = convolve(seir_outputs$Rt, dist_to_infectious, type='filter')
  Rt_case = c(Rt_case, NA* c(1:(length(dist_to_infectious)-1)))
  seir_outputs$Rt_case = Rt_case

  rls = get_RL(seir_outputs$symptomatic_incidence, seir_outputs$time, dist_to_infectious, max_iter=50)
  rls=rls[rls['time'] >=0,]
  seir_outputs$deconvolved_incidence = rls$RL_result
  return(seir_outputs)
}


#GAMMA = 1/4.02
#MU = 1/5.72
#t = c(0:151)
#init_conditions= c(S=1000000, E=1, I=0, R=0)

#b = function(t){
#  return (2*GAMMA)
#}

#seir_outputs = simulate_seir(t, init_conditions, b, GAMMA, MU)

#ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=S, color='S'), )+ geom_line(aes(x=t, y=E, color='E')) + geom_line(aes(x=t, y=I, color='I')) + geom_line(aes(x=t, y=R, color='R') ) +theme_bw()  + labs(title='SEIR model outputs', x='time (days)', y = 'population')
#ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=true_incidence, color='true incidence'))+ geom_line(aes(x=t, y=symptomatic_incidence, color='symptomatic incidence')) +geom_line(aes(x=t, y=deconvolved_incidence, color='deconvolved incidence')) + theme_bw()  + labs(title='SEIR model outputs', x='time (days)', y = 'population')
#ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=Rt, color='Instantaneous Rt'))+ geom_line(aes(x=t, y=Rt_case, color='Cohort Rt')) + theme_bw()  + labs(title='SEIR model outputs', x='time (days)', y = 'Rt')
