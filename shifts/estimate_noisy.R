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

ALPHA = 40
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

# Plot beta-binomial distribution
ggplot_df = data.frame(x=c(0:100000), y= dbbinom(c(0:100000), 100000, alpha=ALPHA, beta=BETA))
ggplot(data=ggplot_df, aes(x=x, y=y)) + geom_line() + labs(title='PDF of beta-binomial distribution for N=100000')
ggsave(paste(file_path, '/distribution.png', sep=''))

# Simulate SEIR with noise
seir_outputs = simulate_seir(t, init_conditions, b, GAMMA, MU, randomize=TRUE, randomize_params=c(alpha=ALPHA,beta=BETA), save_serial = TRUE)
seir_outputs$scaled_incidence = seir_outputs$true_incidence * ALPHA/(ALPHA+BETA)
write.csv(seir_outputs, 'noisy_seir_results.csv')

# Plot S, E, I, R compartments
ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=S, color='S'), )+ geom_line(aes(x=t, y=E, color='E')) + geom_line(aes(x=t, y=I, color='I')) + geom_line(aes(x=t, y=R, color='R') ) + labs(title='SEIR model outputs', x='time (days)', y = 'population')+ scale_color_colorblind()
ggsave(paste(file_path, '/simulation.png', sep=''))

# Plot incidence
#geom_line(aes(x=t, y=true_incidence, color='true incidence'))+
ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=scaled_incidence, color='scaled true incidence'))+ geom_line(aes(x=t, y=symptomatic_incidence, color='symptomatic incidence')) +geom_line(aes(x=t, y=deconvolved_incidence, color='deconvolved incidence'))  + labs(title='SEIR model outputs', x='time (days)', y = 'population')+ scale_color_colorblind()
ggsave(paste(file_path, '/incidence.png', sep=''))

# Plot true R(t)
ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=Rt, color='Instantaneous Rt'))+ geom_line(aes(x=t, y=Rt_case, color='Cohort Rt'))+ labs(title='Rt estimates', x='time (days)', y = 'Rt')+ scale_color_colorblind()
ggsave(paste(file_path, '/true_rt.png', sep=''))

# Compute generation interval/incubation period mean/sd
mean_to_infectious = 1/GAMMA
variance_to_infectious = 1/(GAMMA**2)
mean_to_recovered = 1/MU
variance_to_recovered = 1/(MU**2)
mean_generation = mean_to_infectious + mean_to_recovered 
variance_generation= variance_to_infectious + variance_to_recovered 
sd_generation = sqrt(variance_generation)

# Cori methods
method = 'parametric_si'
incidence = seir_outputs$deconvolved_incidence[1:length(seir_outputs$deconvolved_incidence)-1]
incidence = floor(incidence)
config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
cori = estimate_R(incidence, method=method, config=config)

incidence = seir_outputs$true_incidence
incidence = floor(incidence)
config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
cori_true = estimate_R(incidence, method=method, config=config)

cori_deconvolved = as.data.frame(cori$R)
cori_deconvolved$mean_t = (cori_deconvolved$t_start + cori_deconvolved$t_end)/2
cori_true = as.data.frame(cori_true$R)
cori_true$mean_t = (cori_true$t_start + cori_true$t_end)/2
plot = ggplot(data=cori_deconvolved, aes(x=mean_t, y=`Mean(R)`)) + geom_line(data=cori_deconvolved, aes(x=mean_t, y=`Mean(R)`, color='Estimated Rt with deconvolved values'))+  geom_line(data=cori_true, aes(x=mean_t, y=`Mean(R)`, color='Estimated Rt with true values'))+ geom_line(data=seir_outputs, aes(x=t, y=Rt, color='Instantaneous Rt')) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,3)) + scale_color_colorblind()


# Shifts method
incidence = seir_outputs$symptomatic_incidence
incidence = floor(incidence)

config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
config$n_sim=10


wt = wallinga_teunis(incidence, method=method, config=config)
wt_symptoms = as.data.frame(wt$R)
wt_symptoms$mean_t = (wt_symptoms$t_start + wt_symptoms$t_end)/2

#indices = c(0:30)
#gen_int =  discr_si(indices, mean_generation, sd_generation)
#rls = get_RL(wt_symptoms$`Mean(R)`, c(0:(length(wt_symptoms$mean_t)-1)), gen_int, max_iter=50)
#rls=rls[rls['time'] >=0,]
#wt_symptoms$deconv_wt = rls$RL_result[1:(length(rls$RL_result))]
#wt_symptoms$deconv_wt = shift(wt_symptoms$deconv_wt, mean_generation)

plot = plot + geom_line(data=wt_symptoms, aes(x=mean_t, y=`Mean(R)`, color='WT case Rt - Shifts')) #deconv_wt



# Cori on shifted symptomatic


incidence = seir_outputs$symptomatic_incidence
incidence = floor(incidence)
incidence[incidence < 0] = 0
config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
cori = estimate_R(incidence, method=method, config=config)
cori = as.data.frame(cori$R)
cori$mean_t = (cori$t_start + cori$t_end)/2
mean_shift = mean_to_infectious
cori$`Mean(R)` = shift(cori$`Mean(R)`, -mean_shift+1) #I don't know why +1 here, but it is exactly the same  as with deconvolved
plot = plot + geom_line(data=cori, aes(x=mean_t, y=`Mean(R)`, color='Cori- shifted raw symptomatic data'))#+ theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,5))
print(plot)



ggsave(paste(file_path, '/instantaneous_rt.png', sep=''))













#wt_symptoms = as.data.frame(wt$R)
#wt_symptoms$mean_t = (wt_symptoms$t_start + wt_symptoms$t_end)/2

# Wallinga methods

#incidence = seir_outputs$symptomatic_incidence
#incidence = floor(incidence)
#config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
#config$n_sim=10
#wt = wallinga_teunis(incidence, method=method, config=config)
#plot(wt)

#wt_symptoms = as.data.frame(wt$R)
#wt_symptoms$mean_t = (wt_symptoms$t_start + wt_symptoms$t_end)/2


#incidence = seir_outputs$deconvolved_incidence[1:length(seir_outputs$deconvolved_incidence)-1] 
#incidence = floor(incidence)
#config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
#config$n_sim=10
#wt = wallinga_teunis(incidence, method=method, config=config)
#plot(wt)

#wt_deconvolved = as.data.frame(wt$R)
#wt_deconvolved$mean_t = (wt_deconvolved$t_start + wt_deconvolved$t_end)/2


#ggplot(data=wt_deconvolved, aes(x=mean_t, y=`Mean(R)`)) + geom_line(data=wt_deconvolved, aes(x=mean_t, y=`Mean(R)`, color='WT case Rt - Deconvolved incidence'))+ geom_line(data=wt_symptoms, aes(x=mean_t, y=`Mean(R)`, color='WT case RT - Symptomatic'))+geom_line(data=seir_outputs, aes(x=t, y=Rt_case, color='True case Rt')) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt')
#ggsave(paste(file_path, '/rt_wt.png', sep=''))
