#! /usr/bin/Rscript
library('deSolve')

library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('data.table')
library('ggthemes')


library('ggplot2')
source('ts_utils/seir.R')


# Real-world incubation period
m = dislnorm$new()
m$setPars(c(1.63, 0.5))
m$setXmin(0)

indices = c(0:50)
incubation_pdf = dist_pdf(m, q=indices)

# SEIR incubation period
gamma = 1/4.02 #1/10.02
MU = 1/5.72 #1/10.72

mean_gamma = 1/gamma
sd_gamma = sqrt((1/gamma)**2)
seir_incubation = discr_si(indices, mean_gamma, sd_gamma)

incubation_df = data.frame(d=indices, real_world=incubation_pdf, seir=seir_incubation)

write.csv(incubation_df, paste(paste('incubation_period', '.csv', sep='')))

file_path = 'figures_simulation'
dir.create(file.path(file_path), showWarnings = FALSE)

t = c(-1:400)


b = function(t, MU){
  if (t< 100){
    return(1.5*MU)
  }
  else if (t < 150){
    return(1.2*MU)
  }
  else if (t < 200){
    return(0.99*MU)
  }
  else if (t < 300){
    return(0.8*MU)
  }
  else{
    return (1.1*MU)
  }
}

###########################################################################################
N = 10000000
S = 10000000
E = 0 
I = 0
O = 0
R = 0

detection_prob = 0.8

EI_transitions= c(1:1000)*0
EO_transitions = c(1:1000)*0


all_S = c()
all_E = c()
all_I = c()
all_O = c()
all_R = c()
all_Rt = c()


true_incidence = c()

obs_symptomatic_incidence = c()

for(time_step in t){
  if (((time_step %% 7) == 0) | ((time_step %% 7) == 1)){
    detection_const = 1/3
  }
  else{
    detection_const = 1/6
  }

  # Append states
  all_S = append(all_S, S)
  all_E = append(all_E, E)
  all_I = append(all_I, I)
  all_R = append(all_R, R)
  all_O = append(all_O, O)
  
  # Compute beta
  beta_t = b(time_step, MU)
  all_Rt = append(all_Rt, beta_t/MU * S/N)
  
  if (time_step == -1){
    new_infections = 10
  }
  else{
  # Determine number of S-->E transitions
  new_infection_probability = I*beta_t/N
  new_infections = rbinom(1, size=S, prob=new_infection_probability)}

  true_incidence = append(true_incidence, S*new_infection_probability)
  
  # compute the E-->I and E-->O transition times for each new E
  
  if(new_infections > 0){
  
    for (unused in (c(0:(new_infections-1)))){
      
      infectious_time = rdgamma(1,shape=1, scale=1/gamma)#rexp(1, gamma)
      detection_time = rdgamma(1,shape=1, scale=1/detection_const)#rexp(1, detection_const)

      EI_transitions[infectious_time+1] = EI_transitions[infectious_time+1]+1
    
      EO_transitions[detection_time+1] = EO_transitions[detection_time+1] + 1
    }

  }

  # Compute the number of I-->R transitions
  IR_transitions = rbinom(1, size=I, prob = MU)

  # Execute the S-->E transitions
  S = S - new_infections
  E = E + new_infections

  # Execute the E-->I transitions decided previously 
  E = E - EI_transitions[1]
  I = I + EI_transitions[1]
  EI_transitions = EI_transitions[2:length(EI_transitions)]
  
  new_Os = EO_transitions[1]
  new_Os = rbinom(1, size=new_Os, prob=detection_prob)
  O = O + new_Os
  obs_symptomatic_incidence = append(obs_symptomatic_incidence, new_Os)
  EO_transitions = EO_transitions[2:length(EO_transitions)]
  

  # Execute the I-->R transitions
  I = I - IR_transitions
  R = R + IR_transitions
  

}

df = data.frame(t = t, S = all_S, E = all_E, I = all_I, R = all_R, O=all_O, true_incidence=true_incidence*detection_prob, obs_symptomatic_incidence = obs_symptomatic_incidence, Rt=all_Rt)
df = df[df$t>= 0, ]
ggplot(df) +  geom_line(aes(x=t, y=S, color='S'))+  geom_line(aes(x=t, y=E, color='E'))+ geom_line(aes(x=t, y=I, color='I'))+ geom_line(aes(x=t, y=R, color='R'))+ geom_line(aes(x=t, y=O, color='O'))+ scale_color_colorblind()

ggplot(df) + geom_line(aes(x=t, y=true_incidence, color='true_incidence', alpha=0.5)) + geom_line(aes(x=t, y=obs_symptomatic_incidence, color='obs_symptomatic_incidence', alpha=0.5)) + scale_color_colorblind()
ggsave('incidence_curves.png')
#ggplot(df) + geom_line(aes(x=t, y=Rt, color='Rt')) 

write.csv(df, 'data/seir.csv')