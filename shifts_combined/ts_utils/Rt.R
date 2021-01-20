library('EpiEstim')




cori_estimation = function(i, generation_int){
  # Cori methods
  method='non_parametric_si'
  incidence = c(i)
  incidence = floor(incidence)
  config = make_config(incid=incidence, method = method, si_distr=generation_int)
  cori_true = estimate_R(incidence, method=method, config=config)
  cori_true = as.data.frame(cori_true$R)
  cori_true$mean_t = (cori_true$t_start + cori_true$t_end)/2
  return(cori_true)
}

wt_estimation = function(i, generation_int){
  method='non_parametric_si'
  incidence = c(floor(i))
  incidence = floor(incidence)
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, si_distr=generation_int)
  config$n_sim = 10
  wt = wallinga_teunis(incidence, method=method, config=config)
  wt_deconvolved = as.data.frame(wt$R)
  wt_deconvolved$mean_t = (wt_deconvolved$t_start + wt_deconvolved$t_end)/2
  # wt_deconvolved$`Mean(R)` = shift(wt_deconvolved$`Mean(R)`, -mean_generation)
  return(wt_deconvolved)
}