library('EpiEstim')
library('ggplot2')
source('seir.R')
source('cobey_ml_deconvolution.R')

dir.create(file.path('figures'), showWarnings = FALSE)

GAMMA = 1/4.02
MU = 1/5.72
t = c(0:201)
init_conditions= c(S=10000000, E=1, I=0, R=0)

b = function(t){
  return (2*MU)
}


seir_outputs = simulate_seir(t, init_conditions, b, GAMMA, MU)
ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=S, color='S'), )+ geom_line(aes(x=t, y=E, color='E')) + geom_line(aes(x=t, y=I, color='I')) + geom_line(aes(x=t, y=R, color='R') ) +theme_bw()  + labs(title='SEIR model outputs', x='time (days)', y = 'population')
ggsave('figures/simulation.png')
ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=true_incidence, color='true incidence'))+ geom_line(aes(x=t, y=symptomatic_incidence, color='symptomatic incidence')) +geom_line(aes(x=t, y=deconvolved_incidence, color='deconvolved incidence')) + theme_bw()  + labs(title='SEIR model outputs', x='time (days)', y = 'population')
ggsave('figures/incidence.png')
ggplot(data=seir_outputs, aes(x=t, y=S)) + geom_line(aes(x=t, y=Rt, color='Instantaneous Rt'))+ geom_line(aes(x=t, y=Rt_case, color='Cohort Rt')) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt')
ggsave('figures/true_rt.png')

# I think this works out the same mathematically https://github.com/cobeylab/Rt_estimation/blob/master/code/util.R
mean_to_infectious = 1/GAMMA
variance_to_infectious = 1/(GAMMA**2)
mean_to_recovered = 1/MU
variance_to_recovered = 1/(MU**2)
mean_generation = mean_to_infectious + mean_to_recovered 
variance_generation= variance_to_infectious + variance_to_recovered 
sd_generation = sqrt(variance_generation)

method = 'parametric_si'

incidence = seir_outputs$deconvolved_incidence[1:length(seir_outputs$deconvolved_incidence)-1]
incidence = floor(incidence)
config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
cori = estimate_R(incidence, method=method, config=config)
plot(cori)

# Cori methods
incidence = seir_outputs$true_incidence
incidence = floor(incidence)
config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
cori_true = estimate_R(incidence, method=method, config=config)
plot(cori_true)

cori_deconvolved = as.data.frame(cori$R)
cori_deconvolved$mean_t = (cori_deconvolved$t_start + cori_deconvolved$t_end)/2
cori_true = as.data.frame(cori_true$R)
cori_true$mean_t = (cori_true$t_start + cori_true$t_end)/2
ggplot(data=cori_deconvolved, aes(x=t_end, y=`Mean(R)`)) + geom_line(data=cori_deconvolved, aes(x=mean_t, y=`Mean(R)`, color='Estimated Rt with deconvolved values'))+  geom_line(data=cori_true, aes(x=mean_t, y=`Mean(R)`, color='Estimated Rt with true values'))+ geom_line(data=seir_outputs, aes(x=t, y=Rt, color='Instantaneous Rt')) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt')
ggsave('figures/rt_cori_deconvolved.png')

# Wallinga methods

incidence = seir_outputs$symptomatic_incidence
incidence = floor(incidence)
config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
wt = wallinga_teunis(incidence, method=method, config=config)
plot(wt)

wt_symptoms = as.data.frame(wt$R)
wt_symptoms$mean_t = (wt_symptoms$t_start + wt_symptoms$t_end)/2




incidence = seir_outputs$deconvolved_incidence[1:length(seir_outputs$deconvolved_incidence)-1] 
incidence = floor(incidence)
config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
wt = wallinga_teunis(incidence, method=method, config=config)
plot(wt)

wt_deconvolved = as.data.frame(wt$R)
wt_deconvolved$mean_t = (wt_deconvolved$t_start + wt_deconvolved$t_end)/2


ggplot(data=wt_deconvolved, aes(x=t_end, y=`Mean(R)`)) + geom_line(data=wt_deconvolved, aes(x=t_end, y=`Mean(R)`, color='WT case Rt - Deconvolved incidence'))+ geom_line(data=wt_symptoms, aes(x=t_end, y=`Mean(R)`, color='WT case RT - Symptomatic'))+geom_line(data=seir_outputs, aes(x=t, y=Rt_case, color='True case Rt')) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt')
ggsave('figures/rt_wt.png')
