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
  cori_true$`Quantile.0.05(R)` = shift(cori_true$`Quantile.0.05(R)`, shift_amt)
  cori_true$`Quantile.0.95(R)` = shift(cori_true$`Quantile.0.95(R)`, shift_amt)
  cori_true$`Quantile.0.025(R)` = shift(cori_true$`Quantile.0.025(R)`, shift_amt)
  cori_true$`Quantile.0.975(R)` = shift(cori_true$`Quantile.0.975(R)`, shift_amt)
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
  wt$`Quantile.0.05(R)` = shift(wt$`Quantile.0.05(R)`, shift_amt)
  wt$`Quantile.0.95(R)` = shift(wt$`Quantile.0.95(R)`, shift_amt)
  wt$`Quantile.0.025(R)` = shift(wt$`Quantile.0.025(R)`, shift_amt)
  wt$`Quantile.0.975(R)` = shift(wt$`Quantile.0.975(R)`, shift_amt)
  return(wt)
}

extrapolate = function(seir, target, n_targets=50, n_extend=20){
  data_of_interest = seir[[target]]
  data_end = tail(seir, n_targets)
  fm <- as.formula(paste(target, " ~ poly(X, 1)"))
  
  extrapolation_model = lm(fm, data=data_end)
  
  last_t = data_end$X[length(data_end$X)]
  extrapolated = data.frame(X=c(last_t:(last_t+(n_extend-1))))
  extrapolated$interest = predict(extrapolation_model, extrapolated)
  
  data_of_interest = append(data_of_interest, extrapolated$interest)
  Xs = append(seir$X, extrapolated$X)
  
  data_of_interest[data_of_interest < 0] = 0
  data_of_interest[is.na(data_of_interest)] = 0
  return(list(Xs=Xs, data=c(data_of_interest)))}
