# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize, dual_annealing
import os 


# %%
if not os.path.exists('figures'):
    os.mkdir('figures')


# %%
SEIR_outputs = pd.read_csv('../shifts/SEIR_outputs.csv')
true_incidence = SEIR_outputs['true_incidence'].to_numpy()
symptomatic_incidence = SEIR_outputs['symptomatic_incidence'].to_numpy()

true_kernel = pd.read_csv('../shifts/serial_interval.csv')


# %%
def optimizer_function(kernel):
    # other priors I could put in:
    # regularization
    # smoothness
    # long right tail
    convolved = np.convolve(true_incidence, kernel,  mode='valid') #kernel/np.sum(kernel)

    return np.mean((convolved - symptomatic_incidence[(len(kernel)-1):])**2) 


# %%
x0 = np.ones(shape=(30,))
x0/=np.sum(x0)
xs = minimize(optimizer_function, x0, bounds = [[0, 1] for _ in x0])
#x0 = true_kernel['si'].to_numpy()


# %%
kernel = true_kernel['si'].to_numpy()
plt.figure(figsize=(10, 5))
plt.plot(np.convolve(true_incidence, kernel, mode='valid'),label='convolved symptomatic from true incidence', alpha=0.5)
plt.plot(true_incidence[(len(kernel)-1):], label='true incidence')
plt.plot(symptomatic_incidence[(len(kernel)-1):], label='symptomatic', alpha=0.5)
plt.xlabel('Days since epidemic start')
plt.ylabel('Incidence')
plt.legend()

print('Mean SI from "true" kernel: ' + str(np.sum(true_kernel['index']*true_kernel['si'])))
print('Mean SI from estimated kernel: '+ str(np.sum(range(len(xs.x))*xs.x/np.sum(xs.x))))
plt.savefig('figures/true_convolved_seir.png')


# %%
plt.figure(figsize=(10, 5))
plt.plot(range(len(xs.x)), xs.x/np.sum(xs.x), label='estimated kernel', alpha=1) # not bar plot, double bar plot has low visibility
plt.plot(range(len(true_kernel['si'])), true_kernel['si'], label='true kernel', alpha=1)

plt.xlabel('Days since infection')
plt.ylabel('Probability of becoming symptomatic')
plt.title('Estimated vs true kernels')
plt.legend()

plt.savefig('figures/estimated_vs_true_kernels_seir.png')


# %%
plt.figure(figsize=(10, 5))
plt.plot(np.convolve(xs.x/np.sum(xs.x), true_incidence, mode='valid'), alpha=0.5, label='convolved symptomatic from true incidence and estimated filter')
plt.plot(true_incidence[(len(xs.x)-1):], label='true incidence')
plt.plot(symptomatic_incidence[(len(xs.x)-1):], alpha=0.5, label='symptomatic incidence')
plt.legend()
plt.xlabel('Days since epidemic start')
plt.ylabel('Incidence')
plt.savefig('figures/estimated_convolved_seir.png')


