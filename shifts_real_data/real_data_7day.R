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

#gen_int =  discr_si(c(0:20), mean_generation, sd_generation)

method = 'parametric_si'
for (country in c('Canada', 'United States', 'United Kingdom', 'Japan')){
  data = read.csv(paste(paste('data/', country, sep=''), '.csv', sep=''))
  
  # Cori on shifted symptomatic
  data = read.csv(paste(paste('deconv_mine/', country, sep=''), '.csv', sep=''))
  incidence = data$symptomatic
  incidence = slideFunct(incidence, 7 ,1)
  incidence = floor(incidence)
  print(length(incidence))
  
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  cori = estimate_R(incidence, method=method, config=config)
  cori = as.data.frame(cori$R)
  cori$mean_t = (cori$t_start + cori$t_end)/2
  mean_shift = sum(incubation_pdf*interval)
  cori$`Mean(R)` = shift(cori$`Mean(R)`, -mean_shift+7)
  plot = ggplot(data=cori) + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Cori- shifted raw symptomatic data'))+ ylim(c(0,3))
  
  
  # Cori on "my" deconvolution
  data = read.csv(paste(paste('deconv_mine/', country, sep=''), '.csv', sep=''))

  incidence = data$deconv
  incidence = floor(incidence)
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  cori = estimate_R(incidence, method=method, config=config)
  cori = as.data.frame(cori$R)
  cori$mean_t = (cori$t_start + cori$t_end)/2
  plot = plot +  geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Cori - "mine"'))
  print(length(incidence))
  
  # WT Shifts
  data = read.csv(paste(paste('deconv_mine/', country, sep=''), '.csv', sep=''))
  incidence = data$symptomatic
#  incidence = c(replicate(7, 0), slideFunct(incidence, 7 ,1))
  incidence = slideFunct(incidence, 7 ,1)
  incidence = floor(incidence)
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  config$n_sim = 10
  wt = wallinga_teunis(incidence, method=method, config=config)
  wt_deconvolved = as.data.frame(wt$R)
  wt_deconvolved$mean_t = (wt_deconvolved$t_start + wt_deconvolved$t_end)/2
  wt_deconvolved$`Mean(R)` = shift(wt_deconvolved$`Mean(R)`, 7)
  plot = plot + geom_line(data=wt_deconvolved, aes(x=mean_t, y=`Mean(R)`, color='WT - Unshifted raw symptomatic'))
  print(plot)
  print(length(incidence))
  ggsave(paste(paste('figures_noisy/', country, sep=''), '_cori_estims.png', sep=''))
  
  
}







