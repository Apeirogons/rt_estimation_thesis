#! /usr/bin/Rscript

library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('data.table')


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

shift = data.table::shift