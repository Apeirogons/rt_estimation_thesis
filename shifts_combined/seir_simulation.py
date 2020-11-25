# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize, dual_annealing, basinhopping
import os 
from scipy.stats import betabinom, poisson, norm
import seaborn as sns


ALPHA = 40
BETA=5
gamma = 1/10.02
mu = 1/10.72
s = np.asarray([20000000, 10, 0, 0])
times = np.arange(0, 350)
transitions = np.asarray([ [-1, 1, 0, 0], [0, -1, 1, 0], [0, 0, -1, 1]])

def b(t):
  if (t < 60):
    res =  3
  elif (t < 200):
    res = 1.5
  elif (t < 300):
    res = 0.7
  else:
    res = 2
  return (norm.rvs(0, 0.1) + res)*mu
  
def simulate(state, times):
    resets = 0
    results = pd.DataFrame()
    all_states = []
    all_transitions = []
    Rts = []
    for t in times:
        beta = b(t)
        S = state[0]
        E = state[1]
        I = state[2]
        R = state[3]

        N = S+E+I+R

        SE = beta * S/N * I
        EI = gamma*E
        IR =  mu * I
        
        number_of_transitions = [poisson.rvs(trans) for trans in [SE, EI, IR]]
        each_transition = [transitions[i]*number for i, number in enumerate(number_of_transitions)]
        sum_transitions = np.sum(each_transition, axis=0)
        while np.sum((state + sum_transitions) < 0) > 0:
            number_of_transitions = [poisson.rvs(trans) for trans in [SE, EI, IR]]
            each_transition = [transitions[i]*number for i, number in enumerate(number_of_transitions)]
            sum_transitions = np.sum(each_transition, axis=0)
            resets += 1

        all_transitions.append(number_of_transitions)
        Rt =  beta/mu*S/N
        Rts.append(Rt)
        all_states.append(state)
        state = state + sum_transitions
    
    results['true_incidence'] = np.asarray(all_transitions)[:, 0]
    results['symptomatic_incidence'] = np.asarray(all_transitions)[:, 1]
    results['Rt'] = Rts
    results['date'] = np.arange(len(Rts))
    return results

simulation = simulate(s, times)

scaling_factor =  ALPHA/(ALPHA+BETA)
simulation['scaled_true_incidence'] = simulation['true_incidence'] * scaling_factor
simulation['obs_symptomatic_incidence'] = betabinom.rvs(simulation['symptomatic_incidence'], ALPHA, BETA)
simulation['scaled_true_symptomatic_incidence'] = simulation['symptomatic_incidence'] * scaling_factor
simulation['new_cases_per_million'] = simulation['obs_symptomatic_incidence']/1000000
simulation.to_csv('data/process_noise_SEIR.csv')

#%%

if not os.path.exists('figures/'):
    os.mkdir('figures')

sns.set_palette('colorblind')
plt.figure(figsize=(10, 5))
xs = np.arange(len(simulation['true_incidence']))
plt.plot(simulation['true_incidence'], label='true incidence')
plt.plot(simulation['symptomatic_incidence'], label='symptomatic incidence')
#sns.lineplot(xs, simulation['true_incidence'], label='true incidence')#
#sns.lineplot(xs, simulation['symptomatic_incidence'], label='symptomatic incidence')#
plt.legend()
plt.xlabel('t')
plt.ylabel('incidence')
plt.savefig('figures/true_seir.png')
plt.show()

plt.figure(figsize=(10, 5))
plt.plot(simulation['scaled_true_incidence'], label='scaled true incidence')
plt.plot(simulation['obs_symptomatic_incidence'], label='beta-binomial noise symptomatic incidence')
plt.legend()
plt.xlabel('t')
plt.ylabel('incidence')
plt.savefig('figures/noisy_seir.png')
#plt.show()

xs = np.arange(0, 100000, 100)
plt.figure(figsize=(10, 5))
plt.plot(xs, betabinom.pmf(xs, n=100000, a=ALPHA, b=BETA))
plt.title('PMF of beta-binomial distribution with a=%s, b=%s' % (str(ALPHA), str(BETA)))
plt.ylabel('p')
plt.xlabel('N')
plt.savefig('figures/beta_binomial_pmf.png')

# %%
