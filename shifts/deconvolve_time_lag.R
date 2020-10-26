library('EpiEstim')

library('extraDistr')
library('ggplot2')
source('seir.R')
source('cobey_ml_deconvolution.R')

dir.create(file.path('figures_2'), showWarnings = FALSE)

GAMMA = 1/4.02
MU = 1/5.72
t = c(0:301)
init_conditions= c(S=10000000, E=1, I=0, R=0)

b = function(t){
  if (t < 150){
    return (2*MU)}
  else if (t < 200) {
    return(0.5*MU)}
  else {
    return(1.2*MU)
  }
}

seir_outputs = simulate_seir(t, init_conditions, b, GAMMA, MU)

