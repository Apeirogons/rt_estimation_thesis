library('EpiEstim')
library('ggplot2')


get_next_poisson = function(current_incidence, gen_int, R){
  total = 0
  for (i in c(2:length(gen_int))){
    # if i == 2 (delay 1), current_index = length(current_incidence) (last observation)
    # if i == 3, (delay 2), current_index = length(current_incidence) - 1 (2nd-last observation)
    current_index = length(current_incidence)-(i-2)
    if(current_index >= 1){
      total = total + gen_int[i] * current_incidence[current_index]}
  }
  return(total*R)
}


#


renewal = function(t, conditions, mean_generation, sd_generation, mean_to_infectious, variance_to_infectious, R0, stochastic=FALSE){
  incidence = c(conditions['I'])
  gen_int = discr_si(k=c(0:50), mu=mean_generation, sigma=sd_generation)
  symptomatic_int = discr_si(k=c(0:50), mu=mean_to_infectious, sigma=variance_to_infectious)
  #symptomatic = c(0)
  Rt = c(R0(0))
  for (z in t[-1]){
    R = R0(z)
    next_incidence = get_next_poisson(incidence, gen_int, R)
    if(stochastic){
    next_incidence = rpois(1, next_incidence)}
    incidence = append(incidence, next_incidence)
    Rt = append(Rt, R)
    
    #  next_symptomatic = get_next_poisson(incidence, symptomatic_int, 1)
    # next_symptomatic = rpois(1, next_symptomatic_number)
    #  symptomatic = append(symptomatic, next_symptomatic)
  }
  #symptomatic = convolve(symptomatic_int, incidence, type='filter')
  Rt_case = convolve(Rt, gen_int, type='filter')
  Rt_case = c(Rt_case, NA* c(1:(length(gen_int)-1)))
  renewal_df = data.frame('t'=t, 'true_incidence'=incidence,'Rt'=Rt,'Rt_case'=Rt_case)
  return(renewal_df)
}
