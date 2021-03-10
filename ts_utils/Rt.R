library('EpiEstim')
source('ts_utils/process_utils.R')

cori_estimation = function(i, generation_int, shift_amt=0){
  # Cori methods
  method='non_parametric_si'
  incidence = c(i)
  incidence = floor(incidence)
  config = make_config(incid=incidence, method = method, si_distr=generation_int)
  cori_true = estimate_R(incidence, method=method, config=config)
  cori_true = as.data.frame(cori_true$R)
  cori_true$mean_t = (cori_true$t_start + cori_true$t_end)/2
  cori_true$`Mean(R)`= shift(cori_true$`Mean(R)`, shift_amt)
  return(cori_true)
}

wt_estimation = function(i, generation_int, shift_amt=0){
  method='non_parametric_si'
  incidence = c(floor(i))
  incidence = floor(incidence)
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, si_distr=generation_int)
  config$n_sim = 10
  wt = wallinga_teunis(incidence, method=method, config=config)
  wt = as.data.frame(wt$R)
  wt$mean_t = (wt$t_start + wt$t_end)/2
  wt$`Mean(R)`=shift(wt$`Mean(R)`, shift_amt)
  
  return(wt)
}

rt_estimation = function(incidence,shift_amt = 0){
  rt_smoothed = diff(log(incidence))
  rt_smoothed = rollapply(rt_smoothed, 7, mean, fill=NA, align='center')
  rt_smoothed = data.table::shift(rt_smoothed, shift_amt)
  rt_smoothed = pad(rt_smoothed, incidence)
  return(rt_smoothed)
}