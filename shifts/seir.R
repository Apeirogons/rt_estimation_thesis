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

simulate_seir = function(t, conditions, b, gamma, mu,save_serial = TRUE){
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
  indices = c(0:25)
  dist_to_infectious = discr_si(indices, mean_gamma, sd_gamma)
  
  if (save_serial){
    df = data.frame('index' = indices, 'si' = dist_to_infectious)
    write.csv(df, 'serial_interval.csv', row.names=FALSE)
  }
  
  mean_generation = 1/gamma + 1/mu
  sd_generation = sqrt(1/gamma**2 + 1/mu**2)
  indices= c(0:50)
  gen_int =  discr_si(indices, mean_generation, sd_generation)
  
  Rt_case = convolve(seir_outputs$Rt, gen_int, type='filter')
  Rt_case = c(Rt_case, NA* c(1:(length(gen_int)-1)))
  seir_outputs$Rt_case = Rt_case

  rls = get_RL(seir_outputs$symptomatic_incidence, seir_outputs$time, dist_to_infectious, max_iter=50)
  rls=rls[rls['time'] >=0,]
  seir_outputs$deconvolved_incidence = rls$RL_result
  return(seir_outputs)
}
