library('EpiEstim')
library('ggplot2')
source('renewal.R')

dir.create(file.path('figures_renewal'), showWarnings = FALSE)

R0 = function(t){
  if (t < 150){
    return (2)}
  else if (t < 200) {
    return(0.5)}
  else {
    return(1.2)
  }
}

GAMMA = 1/4.02
MU = 1/5.72
t = c(0:301)
mean_to_infectious = 1/GAMMA
variance_to_infectious = 1/(GAMMA**2)
mean_to_recovered = 1/MU
variance_to_recovered = 1/(MU**2)
mean_generation = mean_to_infectious + mean_to_recovered 
variance_generation= variance_to_infectious + variance_to_recovered 
sd_generation = sqrt(variance_generation)


renewal_df = renewal(t, c(I=1), mean_generation, sd_generation, mean_to_infectious, variance_to_infectious, R0, stochastic=TRUE)
ggplot(data=renewal_df, aes(x=t, y=S)) + geom_line(aes(x=t, y=true_incidence, color='true incidence'))+ theme_bw()  + labs(title='Renewal model outputs', x='time (days)', y = 'population')
ggsave('figures_renewal/simulation.png')


method = 'parametric_si'


# Cori methods
incidence = renewal_df$true_incidence
incidence = floor(incidence)
config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
cori_true = estimate_R(incidence, method=method, config=config)
cori_true = as.data.frame(cori_true$R)
cori_true$mean_t = (cori_true$t_start + cori_true$t_end)/2
ggplot(data=cori_true, aes(x=t_end, y=`Mean(R)`)) + geom_line(data=cori_true, aes(x=mean_t, y=`Mean(R)`, color='Estimated Rt with true values'))+ geom_line(data=renewal_df, aes(x=t, y=Rt, color='Instantaneous Rt')) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt') + ylim(c(0,3))
ggsave('figures_renewal/rt_cori.png')

# Wallinga methods

incidence = renewal_df$true_incidence
incidence = floor(incidence)
config = make_config(incid=incidence, method = method, mean_si=mean_generation, std_si=sd_generation)
wt = wallinga_teunis(incidence, method=method, config=config)
wt = as.data.frame(wt$R)

ggplot(data=wt, aes(x=t_end, y=`Mean(R)`)) + geom_line(data=wt, aes(x=t_end, y=`Mean(R)`, color='WT case RT - true incidence'))+geom_line(data=renewal_df, aes(x=t, y=Rt_case, color='True case Rt')) + theme_bw()  + labs(title='Rt estimates', x='time (days)', y = 'Rt')
ggsave('figures_renewal/rt_wt.png')
