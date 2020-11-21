library('EpiEstim')

library('extraDistr')
library('ggplot2')
source('cobey_ml_deconvolution.R') #
library('poweRlaw')
library('data.table')
library('ggthemes')

file_path = 'figures_noisy'
dir.create(file.path(file_path), showWarnings = FALSE)


m = dislnorm$new()
m$setPars(c(1.63, 0.5))
m$setXmin(0)

interval = c(0:40)
incubation_pdf = dist_pdf(m, q=interval)
plot(interval, incubation_pdf, type='l')

slideFunct <- function(data, window, step){
  total <- length(data)
  spots <- seq(from=1, to=(total-window), by=step)
  result <- vector(length = length(spots))
  for(i in 1:length(spots)){
    result[i] <- mean(data[spots[i]:(spots[i]+window)])
  }
  return(result)
}


#https://www.eurosurveillance.org/content/10.2807/1560-7917.ES.2020.25.17.2000257#html_fulltext
mean_generation = 3.95
sd_generation = 1.51

incubation_df = data.frame(d=interval, pdf=incubation_pdf)
write.csv(incubation_df, paste(paste('incubation_interval', '.csv', sep='')))



for (country in c('Canada', 'United States', 'United Kingdom', 'Japan')){ #
  data = read.csv(paste(paste('data/', country, sep=''), '.csv', sep=''))
  
  # Deconvolution step
  attempt_data = slideFunct(data$new_cases_per_million*1000000, 7, 1)
  
  rls = get_RL(attempt_data, c(1:length(attempt_data)), incubation_pdf, max_iter=50)
  deconv_results = as.data.frame(rls)
  deconv_results = deconv_results[deconv_results['time'] >= 1,]

  
  deconv_results$date = as.Date(data$date)[7:(length(data$date)-1)]
  deconv_results$original = attempt_data
  
  ggplot(deconv_results) + geom_line(aes(x=date, y=original, color='original'))+ geom_line(aes(x=date, y=RL_result, color='deconvolved'))
  ggsave(paste(paste('figures/rl_', country, sep=''), '.png', sep=''))
  
  # RL deconvolution - no longer relevant, removed from plots
  method = 'parametric_si'
  incidence = deconv_results$RL_result
  incidence = floor(incidence)
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  cori = estimate_R(incidence, method=method, config=config)
  cori = as.data.frame(cori$R)
  cori$mean_t = (cori$t_start + cori$t_end)/2
  plot = ggplot(data=cori, aes(x=t_end, y=`Mean(R)`)) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,5)) +geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Estimated Rt with RL deconvolution'))
  print(plot)
  ggsave(paste(paste('figures/rl_Rt_', country, sep=''), '.png', sep=''))
  
}


  