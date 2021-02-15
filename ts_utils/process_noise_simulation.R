#! /usr/bin/Rscript
library('deSolve')

library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('data.table')
library('ggthemes')


library('ggplot2')

source('ts_utils/process_utils.R')


simulate_process = function(init_N, init_infections, b, t, incubation_pdf, infectious_pdf, periodized_detections, p_greaters, cumulative_time_to_recovery, detection_prob){
  N = init_N
  S = N
  E = 0 
  I = 0
  O = 0
  R = 0
  
  
  EI_transitions= c(1:(length(t)+1))*0
  EO_transitions = c(1:(length(t)+1))*0
  IR_transitions = c(1:(length(t)+1))*0
  
  all_S = c()
  all_E = c()
  all_I = c()
  all_O = c()
  all_R = c()
  all_Rt = c()
  
  expected_incidence = c()
  randomized_incidence = c()
  obs_symptomatic_incidence = c()
  
  for(time_step in t){
    this_detection =periodized_detections[[(time_step %% 7)+1]]
    todays_missing_factor = p_greaters[[(time_step %% 7) + 1]]
    today_selection_prob = detection_prob/(1-todays_missing_factor)
    stopifnot(today_selection_prob < 1)
    
    # Append states
    all_S = append(all_S, S)
    all_E = append(all_E, E)
    all_I = append(all_I, I)
    all_R = append(all_R, R)
    all_O = append(all_O, O)
    
    # Compute beta
    mu = 1/sum(c(0:(length(infectious_pdf) -1))*infectious_pdf)
    beta_t = b(time_step, mu)
    all_Rt = append(all_Rt, beta_t/mu * S/N)
  
    
    if (time_step == 0){
      new_infections = init_infections
      expected_incidence = append(expected_incidence, 0)
      randomized_incidence = append(randomized_incidence, 0)
    }
    else{
      # Determine number of S-->E transitions
      new_infection_probability = I*beta_t/N
      new_infections = r_alt_nbinom(1, mean=S*new_infection_probability, k=0)
    
      expected_incidence = append(expected_incidence, S*new_infection_probability)
      randomized_incidence = append(randomized_incidence, new_infections)
      }
    
    # compute the E-->I and E-->O transition times for each new E
    
    if(new_infections > 0){
      for (unused in (c(0:(new_infections-1)))){
        
        infectious_time = sample(c(0:(length(incubation_pdf)-1)),size=1, prob=incubation_pdf) 
        recovery_time = sample(c(0:(length(infectious_pdf)-1)), size=1, prob = infectious_pdf) + infectious_time
  
  
        detection_time = sample(c(0:(length(this_detection)-1)),size=1, prob=this_detection) 
        
        is_selected = sample(c(TRUE, FALSE), size=1, prob = c(today_selection_prob, 1-today_selection_prob))
        
        if((detection_time <= recovery_time) && is_selected){
          EO_transitions[detection_time+1] = EO_transitions[detection_time+1] + 1
          }
        
        
        EI_transitions[infectious_time+1] = EI_transitions[infectious_time+1]+1
        IR_transitions[recovery_time+1] =  IR_transitions[recovery_time+1]+1
      }
  
    }
  
    # Execute the S-->E transitions
    S = S - new_infections
    E = E + new_infections
  
    # Execute the E-->I transitions decided previously 
    E = E - EI_transitions[1]
    I = I + EI_transitions[1]
    EI_transitions = EI_transitions[2:length(EI_transitions)]
    
    new_Os = EO_transitions[1]
    
    O = O + new_Os
    obs_symptomatic_incidence = append(obs_symptomatic_incidence, new_Os)
    EO_transitions = EO_transitions[2:length(EO_transitions)]
    
    # Execute the I-->R transitions decided previously
    I = I - IR_transitions[1]
    R = R + IR_transitions[1]
    IR_transitions = IR_transitions[2:length(IR_transitions)]
  }
  df = data.frame(t = t, S = all_S, E = all_E, I = all_I, R = all_R, O=all_O, scaled_expected_incidence=expected_incidence*detection_prob, expected_incidence = expected_incidence, obs_symptomatic_incidence = obs_symptomatic_incidence, Rt=all_Rt, true_incidence = randomized_incidence, scaled_true_incidence = randomized_incidence*detection_prob)#, rt=all_rt
  
  Rt_case = convolve(df$Rt, cumulative_time_to_recovery, type='filter')
  Rt_case = c(Rt_case, NA* c(1:(length(cumulative_time_to_recovery)-1)))
  df$Rt_case = Rt_case
  df = df[df$t>= 0, ]
  return(df)
}
