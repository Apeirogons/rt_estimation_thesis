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



#https://www.eurosurveillance.org/content/10.2807/1560-7917.ES.2020.25.17.2000257#html_fulltext
mean_generation = 3.95
sd_generation = 1.51

incubation_df = data.frame(d=interval, pdf=incubation_pdf)
write.csv(incubation_df, paste(paste('incubation_interval', '.csv', sep='')))

#gen_int =  discr_si(c(0:20), mean_generation, sd_generation)

for (country in c('Canada', 'United States', 'United Kingdom', 'Japan')){
  data = read.csv(paste(paste('data/', country, sep=''), '.csv', sep=''))
  
  # Deconvolution step
  rls = get_RL(data$new_cases_per_million*1000000, c(1:length(data$date)), incubation_pdf, max_iter=50)
  deconv_results = as.data.frame(rls)
  deconv_results = deconv_results[deconv_results['time'] >= 1,]
  
  deconv_results$date = as.Date(data$date)
  deconv_results$original = data$new_cases_per_million*1000000
  
  ggplot(deconv_results) + geom_line(aes(x=date, y=original, color='original'))+ geom_line(aes(x=date, y=RL_result, color='deconvolved'))
  ggsave(paste(paste('figures/', country, sep=''), '.png', sep=''))
  
  # RL deconvolution - no longer relevant, removed from plots

#  incidence = deconv_results$RL_result
#  incidence = floor(incidence)
#  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
#  cori = estimate_R(incidence, method=method, config=config)
#  cori = as.data.frame(cori$R)
#  cori$mean_t = (cori$t_start + cori$t_end)/2
#  plot = ggplot(data=cori, aes(x=t_end, y=`Mean(R)`)) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,5)) #geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Estimated Rt with RL deconvolution')) 
  

  # Cori on Weiner
  data = read.csv(paste(paste('deconv/', country, sep=''), '.csv', sep=''))
  method = 'parametric_si'
  incidence = data$deconv
  incidence = floor(incidence)
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  cori = estimate_R(incidence, method=method, config=config)
  cori = as.data.frame(cori$R)
  cori$mean_t = (cori$t_start + cori$t_end)/2
  plot = ggplot(data=cori) + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Cori- Weiner deconvolution'))+ theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,3)) + scale_color_colorblind()
  
  method = 'parametric_si'
  
  # Cori on shifted symptomatic
  data = read.csv(paste(paste('deconv_mine/', country, sep=''), '.csv', sep=''))
  incidence = data$symptomatic
  incidence = floor(incidence)
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  cori = estimate_R(incidence, method=method, config=config)
  cori = as.data.frame(cori$R)
  cori$mean_t = (cori$t_start + cori$t_end)/2
  mean_shift = sum(incubation_pdf*interval)
  cori$`Mean(R)` = shift(cori$`Mean(R)`, -round(mean_shift)) #why not +1 here then...?
  plot = plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Cori- shifted raw symptomatic data'))+ ylim(c(0,5))
  
  
  # Cori on "my" deconvolution
  data = read.csv(paste(paste('deconv_mine/', country, sep=''), '.csv', sep=''))
  
  method = 'parametric_si'
  incidence = data$deconv
  incidence = floor(incidence)
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  cori = estimate_R(incidence, method=method, config=config)
  cori = as.data.frame(cori$R)
  cori$mean_t = (cori$t_start + cori$t_end)/2
  plot = plot +  geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Cori - "mine"'))

  # WT on shifted symptomatic
  data = read.csv(paste(paste('deconv_mine/', country, sep=''), '.csv', sep=''))
  incidence = data$symptomatic
  incidence = floor(incidence)
  incidence[incidence < 0] = 0
  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
  config$n_sim = 10
  wt = wallinga_teunis(incidence, method=method, config=config)
  wt_deconvolved = as.data.frame(wt$R)
  wt_deconvolved$mean_t = (wt_deconvolved$t_start + wt_deconvolved$t_end)/2
  #mean_shift = 2*sum(incubation_pdf*interval)
  # wt_deconvolved$`Mean(R)` = shift(wt_deconvolved$`Mean(R)`, -mean_shift)
  plot = plot + geom_line(data=wt_deconvolved, aes(x=mean_t, y=`Mean(R)`, color='WT - Unshifted raw symptomatic'))
  print(plot)
  
  ggsave(paste(paste('figures_noisy/', country, sep=''), '_cori_estims.png', sep=''))
  

}




# Case RT starts here
# WT on Weiner
#  method = 'parametric_si'
#  data = read.csv(paste(paste('deconv/', country, sep=''), '.csv', sep=''))
#  incidence = data$deconv
#  incidence = floor(incidence)
#  incidence[incidence < 0] = 0
#  config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
#  config$n_sim = 10
#  wt = wallinga_teunis(incidence, method=method, config=config)
#  wt_deconvolved = as.data.frame(wt$R)
#  wt_deconvolved$mean_t = (wt_deconvolved$t_start + wt_deconvolved$t_end)/2
#  plot = ggplot(data=wt_deconvolved) + geom_line(data=wt_deconvolved, aes(x=mean_t, y=`Mean(R)`, color='WT case Rt - Deconvolved (Weiner) incidence')) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt')+ ylim(c(0,3)) + scale_color_colorblind()


# WT on shifted symptomatic
#data = read.csv(paste(paste('deconv_mine/', country, sep=''), '.csv', sep=''))
#incidence = data$symptomatic
#incidence = floor(incidence)
#incidence[incidence < 0] = 0
#config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
#config$n_sim = 10
#wt = wallinga_teunis(incidence, method=method, config=config)
#wt_deconvolved = as.data.frame(wt$R)
#wt_deconvolved$mean_t = (wt_deconvolved$t_start + wt_deconvolved$t_end)/2
#mean_shift = sum(incubation_pdf*interval)
#wt_deconvolved$`Mean(R)` = shift(wt_deconvolved$`Mean(R)`, -mean_shift)
#plot = plot + geom_line(data=wt_deconvolved, aes(x=mean_t, y=`Mean(R)`, color='WT case Rt - Shifted raw symptomatic'))

# WT on "mine"
#method = 'parametric_si'
#data = read.csv(paste(paste('deconv_mine/', country, sep=''), '.csv', sep=''))
#incidence = data$deconv
#incidence = floor(incidence)
#incidence[incidence < 0] = 0
#config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
#config$n_sim = 10
#wt = wallinga_teunis(incidence, method=method, config=config)
#wt_deconvolved = as.data.frame(wt$R)
#wt_deconvolved$mean_t = (wt_deconvolved$t_start + wt_deconvolved$t_end)/2


#plot = plot + geom_line(data=wt_deconvolved, aes(x=mean_t, y=`Mean(R)`, color='WT case Rt - Deconvolved ("Mine") incidence'))
#print(plot)
#ggsave(paste(paste('figures_noisy/', country, sep=''), '_wt_estims.png', sep=''))




