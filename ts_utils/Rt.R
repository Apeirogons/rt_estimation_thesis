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

rt_estimation = function(i,shift_amt = 0, n=7, use_sg = FALSE){
  incidence = i
  incidence[incidence < 0] = 0
  if (use_sg){
    rt_smoothed = sg_filter(log(incidence), window_length=n, polyorder=1, deriv=1)}
  #  rt_smoothed = sg_filter(rt_smoothed, window_length=15, polyorder=1, deriv=0)}
  else{
    rt_smoothed = diff(log(incidence))
    rt_smoothed = rollapply(rt_smoothed, n, mean, fill=NA, align='center')
    rt_smoothed = c(rt_smoothed, NA) # NA at end of sequence as it is not defined
  }
  
  rt_smoothed = data.table::shift(rt_smoothed, shift_amt)
  return(rt_smoothed)
}



rt_estimation_ci = function(incidence, ci_lower, ci_higher, n_resample = 20, level=0.95, shift_amt = 0, n=7){
  stopifnot(length(incidence) == length(ci_lower))
  stopifnot(length(incidence) == length(ci_higher))
  stopifnot((n %% 2) == 1)
  
  n_half = n/2 - 0.5
  means = NULL
  width = (ci_higher - ci_lower)/2 
  sd = width / qnorm(1 - (1-level)/2)
  
  for(x in c(1:n_resample)){
    resampled = c()
    for (i in c(1:length(incidence))){
      today_incidence = incidence[i]
      today_sd = sd[i]
      
      resampled = append(resampled, rnorm(1, mean=today_incidence, sd=today_sd))
    }
    resampled[resampled < 0] = 0
    
    estimated = rollapply(log(resampled), n, linear_regression, fill=NA, align='center')
    
    
    for (i in c(1:n_half)){
      estimated[i,] = estimated[(n_half + 1),]}
    
    for (i in c((length(estimated[,'mean'])-n_half+1):length(estimated[,'mean']))){
      estimated[i,] = estimated[(length(estimated[,'mean']) - n_half)]
    }
    
    
    this_mean = data.table::shift(estimated[,'mean'], shift_amt)
    
    if (is.null(means)){
      means = this_mean
    }
    else {
      means = cbind(means, this_mean)
    }
  }
  
  
  i = incidence
  i[i<0] = 0
  center = rollapply(log(i), n, linear_regression, fill=NA, align='center')
  for (i in c(1:n_half)){
    center[i,] = center[(n_half + 1),]}
  
  for (i in c((length(center[,'mean'])-n_half+1):length(center[,'mean']))){
    center[i,] = center[(length(center[,'mean']) - n_half)]
  }
  
  
  
  center = data.table::shift(center[,'mean'], shift_amt)
  sampled_mean = apply(means, 1, mean)
  sds = apply(means,1, sd)
  lowers = center - qnorm(1 - (1-level)/2)*sds
  uppers = center + qnorm(1 - (1-level)/2)*sds
  
  df = data.frame(mean=center, lower=lowers, upper = uppers)
  
  return(df)  #center
}
