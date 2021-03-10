#! /usr/bin/Rscript
library('deSolve')
library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('data.table')
library('ggthemes')
library('zoo')

source('ts_utils/rl_cobey.R')

n_day_smoother = function(data, N=7){
  return(rollmean(data, N, fill=NA, align='center'))
}

r_alt_nbinom = function(N, mean, k){
  if(k == 0){
    return (rpois(N, lambda=mean))
  }
  else{
    return(rnbinom(N, mu=mean, size=1/k))
  }
}

periodize = function(pdf, offset, detection_consts){
  new_pdf = c()
  period = length(detection_consts)
  for (i in c(0:(length(pdf)-1))){
    new_pdf = append(new_pdf, pdf[i+1] * detection_consts[((i+ offset) %% period)+1 ])
  }
  new_pdf = new_pdf/sum(new_pdf)
  return(new_pdf)
}

p_greater = function(x, y){
  # Find probability that x > y
  total = 0
  # Iterate over all elements of y
  for (iy in 1:length(y)){
    # For each element in y, find all elements in x with a higher index than it
    if ((iy + 1) <= length(x)){
      greater_than = x[(iy+1):length(x)]
      cumulative_prob = y[iy] * sum(greater_than)
      total = total + cumulative_prob
    }
  }
  return(total)
}


get_detection_pdfs = function(detection_prob, detection_consts, infectious_pdf, incubation_pdf, detection_pdf){
  cumulative_time_to_recovery = convolve(infectious_pdf,rev(incubation_pdf), type='open')
  periodized_detections = list()
  p_greaters = list()
  for (i in 0:(length(detection_consts)-1)){
    periodized = c(periodize(detection_pdf, i, detection_consts))
    periodized_detections[[i+1]] = periodized
    p_greaters[[i+1]] = p_greater(periodized, cumulative_time_to_recovery)
  }
  
  return(list(periodized_detections=periodized_detections, p_greaters = p_greaters, cumulative_time_to_recovery=cumulative_time_to_recovery))
}

pad = function(target, comparator){
  stopifnot(length(target) <= length(comparator))
  return (c(target, rep(NA, length(comparator) - length(target))))
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

deconvolve = function(X, target, detection_pdf, N=7){
  smoothed_target= n_day_smoother(target, N)
  
  rl = get_RL(smoothed_target[!is.na(smoothed_target)], X[!is.na(smoothed_target)], detection_pdf, stopping_n = 0.5, regularize=0.01, max_iter=100)
  rl = pad(rl$RL_result[rl$time>0], X)
  return(rl)
}

shift = data.table::shift