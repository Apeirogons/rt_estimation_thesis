library('EpiEstim')

generation_seir = function(GAMMA, MU){

  #c(seir$smoothed_rl_deconv)
  mean_to_infectious = 1/GAMMA
  variance_to_infectious = 1/(GAMMA**2)
  mean_to_recovered = 1/MU
  variance_to_recovered = 1/(MU**2)
  mean_generation = mean_to_infectious + mean_to_recovered 
  variance_generation= variance_to_infectious + variance_to_recovered 
  sd_generation = sqrt(variance_generation)
  return(c(mean=mean_generation, sd = sd_generation))
  }


cori_estimation = function(i, mean_generation, sd_generation){
  # Cori methods
  method='parametric_si'
  incidence = c(i)
  incidence = floor(incidence)
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  cori_true = estimate_R(incidence, method=method, config=config)
  cori_true = as.data.frame(cori_true$R)
  cori_true$mean_t = (cori_true$t_start + cori_true$t_end)/2
  return(cori_true)
}

wt_estimation = function(i, mean_generation, sd_generation){
  method='parametric_si'
  incidence = c(floor(i))
  incidence = floor(incidence)
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  config$n_sim = 10
  wt = wallinga_teunis(incidence, method=method, config=config)
  wt_deconvolved = as.data.frame(wt$R)
  wt_deconvolved$mean_t = (wt_deconvolved$t_start + wt_deconvolved$t_end)/2
  # wt_deconvolved$`Mean(R)` = shift(wt_deconvolved$`Mean(R)`, -mean_generation)
  return(wt_deconvolved)
}