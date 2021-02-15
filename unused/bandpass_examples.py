# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize, dual_annealing, basinhopping
import os 

from ts_utils.deconvolution import *
import seaborn as sns


# %%

from scipy.fftpack import fftfreq, rfft, irfft, fft, ifft


# %%
import pywt


# %%
#cutoffs = [10,]
sns.set_palette('colorblind')
for i, country in enumerate(os.listdir('data')):
    if not (country=='owid-covid-data.xlsx'):
        simulation = pd.read_csv('data/' + country)
        obs_symptomatic_incidence = simulation['new_cases_per_million'].to_numpy()
        
        freqs = fftfreq(len(obs_symptomatic_incidence))
       # print(freqs)
        plt.figure(figsize=(10, 5))
        periods = np.abs(1/freqs)
        shape = obs_symptomatic_incidence.shape
        f = fft(obs_symptomatic_incidence)
        f[periods < 7] = 0
        filtered = ifft(f)
        

        plt.title(country)
        plt.plot(obs_symptomatic_incidence, label='obs',alpha=0.5)
        plt.plot(filtered, label='filter')
        plt.legend()
        plt.savefig('figures/'+country+'_fft_filter.png')
        plt.show()

        freqs = fftfreq(len(obs_symptomatic_incidence))
       # print(freqs)
        plt.figure(figsize=(10, 5))
        periods = np.abs(1/freqs)

        f = fft(obs_symptomatic_incidence)
        f[(periods < 8) & (periods > 6)] = 0
        filtered = ifft(f)
        

        plt.title(country)
        plt.plot(obs_symptomatic_incidence, label='obs',alpha=0.5)
        plt.plot(filtered, label='filter')
        plt.legend()
        plt.savefig('figures/'+country+'_fft_garbage.png')
        plt.show()

  #  plt.legend()
   # plt.ylim(0,)
 #   plt.savefig('figures/seir'+ deconv_names[i]+'.png')


# %%



