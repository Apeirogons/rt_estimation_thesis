#! /usr/bin/Rscript
library('deSolve')
library('ggplot2')
library('EpiEstim')
library('extraDistr')

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

multiply_noise = function(x, alpha, beta){
  noisy = c()
  
  for (item in x){
    noisy = append(noisy, rbbinom(1, item, alpha=alpha, beta=beta))
  }
  return (noisy)
}

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
  
  
  mean_gamma = 1/gamma
  sd_gamma = sqrt((1/gamma)**2)
  indices = c(0:100)
  dist_to_infectious = discr_si(indices, mean_gamma, sd_gamma)
  
  
  mean_generation = 1/gamma + 1/mu
  sd_generation = sqrt(1/gamma**2 + 1/mu**2)
  gen_int =  discr_si(indices, mean_generation, sd_generation)

  Rt_case = convolve(seir_outputs$Rt, gen_int, type='filter')
  Rt_case = c(Rt_case, NA* c(1:(length(gen_int)-1)))
  seir_outputs$Rt_case = Rt_case
  
  seir_outputs$noisy_symptomatic_incidence = multiply_noise(round(seir_outputs$symptomatic_incidence), alpha=randomize_params['alpha'], beta=randomize_params['beta'] )
  
  seir_outputs$scaled_true_incidence = seir_outputs$true_incidence
  seir_outputs$scaled_symptomatic_incidence = seir_outputs$symptomatic_incidence
  return(seir_outputs)
}