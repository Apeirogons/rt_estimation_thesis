
# For N=7, this has been confirmed to be equivalent to scipy (well with some precision problems at low incidence, but w/e)
linear_filter = function(incidence, N=7, level=0.99){
  linear_filter_base = function(i){
    temp_df = data.frame(x=c(1:length(i)), y = i)
    temp_df = temp_df[!is.infinite(temp_df$y),]
    temp_df = temp_df[!is.na(temp_df$y),]
    
    model = lm(y ~ x, data=temp_df)
    prediction = predict(model, newdata=temp_df, interval='prediction', level=level)
    
    return(prediction[4,])}
  stopifnot((N %% 2) == 1)
  N_half = N/2 - 0.5
  filtered = rollapply(incidence, N, linear_filter_base, fill=NA, align='center')
  temp_df = data.frame(x=c(1:N), y=incidence[1:N])
  model = lm(y ~ x, data=temp_df)
  
  
  left_df = data.frame(x=c(1:N_half))
  filtered[1:N_half,] = predict(model, newdata=left_df, interval='prediction', level=level)
  temp_df = data.frame(x=c((length(incidence)-N+1):length(incidence)), y=incidence[(length(incidence)-N+1):length(incidence)])
  model = lm(y ~ x, data=temp_df)
  right_df = data.frame(x=(length(incidence)-N_half+1):(length(incidence)))
  filtered[(length(incidence)-N_half+1):(length(incidence)),] = predict(model, newdata=right_df, interval='prediction', level=level)
  return(filtered)
}

linear_regression = function(incidence){

  temp_df = data.frame(x=c(1:length(incidence)), y = incidence)
  temp_df = temp_df[!is.infinite(temp_df$y),]
  temp_df = temp_df[!is.na(temp_df$y),]
  
  if(nrow(temp_df) == 0){
    return (c(mean=NA, lower=NA, upper=NA))
  }
  model = lm(y ~ x, data=temp_df)
  mean_slope = model$coefficients[['x']]
  ci_slope = confint(model, 'x', level=0.99)
  
  lower = ci_slope[[1]]
  upper = ci_slope[[2]]
  
  
  return (c(mean=mean_slope, lower=lower, upper=upper))}
