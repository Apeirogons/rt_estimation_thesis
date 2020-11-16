library('EpiEstim')
library('ggplot2')
library('extraDistr')
source('seir.R')
source('cobey_ml_deconvolution.R')
library('ggthemes')
library(data.table)
file_path = 'figures_noisy'
dir.create(file.path(file_path), showWarnings = FALSE)

theme_set(theme_bw())
# Parameters (Yes b(t) is a function that is a parameter)
GAMMA = 1/4.02
MU = 1/5.72

ALPHA = 20
BETA=5
t = c(0:301)
init_conditions= c(S=10000000, E=1, I=0, R=0)

b = function(t){
  if (t < 100){
    return (2*MU)}
  else if (t < 200) {
    return(0.95*MU)}
  else {
    return(1.1*MU)
  }
}


slideFunct <- function(data, window, step){
  total <- length(data)
  spots <- seq(from=1, to=(total-window), by=step)
  result <- vector(length = length(spots))
  for(i in 1:length(spots)){
    result[i] <- mean(data[spots[i]:(spots[i]+window)])
  }
  return(result)
}

# Simulate SEIR with noise
seir_outputs = simulate_seir(t, init_conditions, b, GAMMA, MU, randomize=TRUE, randomize_params=c(alpha=ALPHA,beta=BETA), save_serial = TRUE)
seir_outputs$scaled_incidence = seir_outputs$true_incidence * ALPHA/(ALPHA+BETA)

seir_outputs$slided_incidence = c(slideFunct(seir_outputs$symptomatic_incidence, 7, 1), replicate(7, NaN))

L = length(seir_outputs$slided_incidence)-7
mean_gamma = 1/GAMMA
sd_gamma = sqrt((1/GAMMA)**2)
rls = get_RL(seir_outputs$slided_incidence[1:L], seir_outputs$time[1:L], discr_si(c(0:30), mean_gamma, sd_gamma))
rls = rls=rls[rls['time'] >=0,]

seir_outputs$deconvolved_slided = c(rls$RL_result, replicate(7, NaN))

# Plot incidence
#geom_line(aes(x=t, y=true_incidence, color='true incidence'))+
ggplot(data=seir_outputs) + geom_line(aes(x=t, y=scaled_incidence, color='scaled true incidence')) + geom_line(aes(x=t, y=deconvolved_slided, color='deconv slided')) +geom_line(aes(x=t, y=slided_incidence, color='slided')) # + geom_line(aes(x=t, y=symptomatic_incidence, color='symptomatic incidence')) +geom_line(aes(x=t, y=deconvolved_incidence, color='deconvolved incidence'))  + labs(title='SEIR model outputs', x='time (days)', y = 'population')+ scale_color_colorblind()
ggsave(paste(file_path, '/incidence.png', sep=''))
